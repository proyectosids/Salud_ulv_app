import 'dart:math';

class StepDetector {
  // ============================================================
  // CONFIGURACIÓN
  // ============================================================

  /// Menos suavizado = responde más rápido a los pasos.
  static const double smoothAlpha = 0.45;

  /// El baseline cambia lentamente.
  static const double baselineAlpha = 0.985;

  /// Threshold mínimo.
  static const double minimumThreshold = 0.35;

  /// Qué tanto influye el ruido.
  static const double noiseMultiplier = 2.0;

  /// Nunca permitimos que el threshold adaptativo
  /// sea demasiado alto.
  static const double maximumThreshold = 1.40;

  /// Para rearmar el detector.
  static const double resetThreshold = 0.15;

  // ============================================================
  // TIEMPO
  // ============================================================

  static const int minimumStepIntervalMs = 280;

  static const int maximumStepIntervalMs = 1300;

  // ============================================================
  // CALIBRACIÓN
  // ============================================================

  static const int calibrationSamples = 20;

  // ============================================================
  // ESTADO
  // ============================================================

  StepDetectorState _state = StepDetectorState.calibrating;

  double _smoothMagnitude = 0.0;

  double _baseline = 0.0;

  double _noise = 0.10;

  double _previousSignal = 0.0;

  double _peakSignal = 0.0;

  DateTime? _lastStepTime;

  int _calibrationSamples = 0;

  double _calibrationSum = 0.0;

  int _steps = 0;

  // ============================================================
  // DEBUG
  // ============================================================

  double _lastMagnitude = 0.0;

  double _lastConfidence = 0.0;

  // ============================================================
  // GETTERS
  // ============================================================

  double get magnitude => _lastMagnitude;

  double get smoothMagnitude => _smoothMagnitude;

  double get baseline => _baseline;

  double get noise => _noise;

  double get signal => _smoothMagnitude - _baseline;

  double get threshold {
    final adaptive = _noise * noiseMultiplier;

    return adaptive.clamp(minimumThreshold, maximumThreshold);
  }

  double get confidence => _lastConfidence;

  int get steps => _steps;

  StepDetectorState get state => _state;

  // ============================================================
  // UPDATE
  // ============================================================

  bool update(List<double> accelerometerData, {DateTime? timestamp}) {
    if (accelerometerData.length < 3) {
      return false;
    }

    final x = accelerometerData[0];
    final y = accelerometerData[1];
    final z = accelerometerData[2];

    // Una lectura inválida no debe envenenar el baseline ni el umbral
    // adaptativo durante el resto de la sesión.
    if (!x.isFinite || !y.isFinite || !z.isFinite) {
      return false;
    }

    // ----------------------------------------------------------
    // MAGNITUD
    // ----------------------------------------------------------

    final magnitude = sqrt(x * x + y * y + z * z);

    _lastMagnitude = magnitude;

    // ----------------------------------------------------------
    // CALIBRACIÓN
    // ----------------------------------------------------------

    if (_state == StepDetectorState.calibrating) {
      return _calibrate(magnitude);
    }

    // ----------------------------------------------------------
    // SUAVIZADO
    // ----------------------------------------------------------

    _smoothMagnitude =
        smoothAlpha * _smoothMagnitude + (1.0 - smoothAlpha) * magnitude;

    // ----------------------------------------------------------
    // BASELINE
    // ----------------------------------------------------------

    _baseline =
        baselineAlpha * _baseline + (1.0 - baselineAlpha) * _smoothMagnitude;

    // ----------------------------------------------------------
    // SEÑAL
    // ----------------------------------------------------------

    final signal = _smoothMagnitude - _baseline;

    // ----------------------------------------------------------
    // RUIDO
    // ----------------------------------------------------------

    _updateNoise(signal);

    // ----------------------------------------------------------
    // MÁQUINA DE ESTADOS
    // ----------------------------------------------------------

    final now = timestamp ?? DateTime.now();

    bool stepDetected = false;

    switch (_state) {
      case StepDetectorState.calibrating:
        break;

      case StepDetectorState.idle:
        if (signal >= threshold) {
          _state = StepDetectorState.rising;

          _peakSignal = signal;
        }
        break;

      case StepDetectorState.rising:
        if (signal > _peakSignal) {
          _peakSignal = signal;
        }

        // Detectamos que llegamos al pico.
        if (signal < _previousSignal) {
          _state = StepDetectorState.peak;
        }

        break;

      case StepDetectorState.peak:
        if (signal > _peakSignal) {
          _peakSignal = signal;
        }

        // Esperamos una caída suficientemente clara.
        if (signal < _peakSignal * 0.80) {
          stepDetected = _validateStep(now);

          _state = StepDetectorState.waitingReset;
        }

        break;

      case StepDetectorState.waitingReset:
        if (signal <= resetThreshold) {
          _state = StepDetectorState.idle;

          _peakSignal = 0.0;
        }

        break;
    }

    _previousSignal = signal;

    if (stepDetected) {
      _steps++;
    }

    return stepDetected;
  }

  // ============================================================
  // CALIBRACIÓN
  // ============================================================

  bool _calibrate(double magnitude) {
    _calibrationSamples++;

    _calibrationSum += magnitude;

    _smoothMagnitude = _calibrationSum / _calibrationSamples;

    _baseline = _smoothMagnitude;

    if (_calibrationSamples >= calibrationSamples) {
      _state = StepDetectorState.idle;

      _previousSignal = 0.0;

      _noise = 0.10;

      return false;
    }

    return false;
  }

  // ============================================================
  // RUIDO
  // ============================================================

  void _updateNoise(double signal) {
    final value = signal.abs();

    _noise = 0.97 * _noise + 0.03 * value;

    _noise = _noise.clamp(0.05, 0.60);
  }

  // ============================================================
  // VALIDAR PASO
  // ============================================================

  bool _validateStep(DateTime now) {
    // ----------------------------------------------------------
    // AMPLITUD
    // ----------------------------------------------------------

    if (_peakSignal < threshold) {
      return false;
    }

    // ----------------------------------------------------------
    // INTERVALO
    // ----------------------------------------------------------

    if (_lastStepTime == null) {
      _lastStepTime = now;

      _lastConfidence = 0.80;

      return true;
    }

    final interval = now.difference(_lastStepTime!).inMilliseconds;

    // Demasiado rápido.
    if (interval < minimumStepIntervalMs) {
      return false;
    }

    // Demasiado lento para ser parte
    // de la misma caminata.
    if (interval > maximumStepIntervalMs) {
      _lastStepTime = now;

      _lastConfidence = 0.65;

      return true;
    }

    // ----------------------------------------------------------
    // SCORE SIMPLE
    // ----------------------------------------------------------

    double confidence = 0.0;

    // Amplitud.
    final amplitudeRatio = _peakSignal / threshold;

    if (amplitudeRatio >= 2.0) {
      confidence += 0.50;
    } else if (amplitudeRatio >= 1.3) {
      confidence += 0.40;
    } else {
      confidence += 0.30;
    }

    // Timing.
    if (interval >= 350 && interval <= 900) {
      confidence += 0.40;
    } else {
      confidence += 0.20;
    }

    _lastConfidence = confidence.clamp(0.0, 1.0);

    _lastStepTime = now;

    return confidence >= 0.50;
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _state = StepDetectorState.calibrating;

    _smoothMagnitude = 0.0;

    _baseline = 0.0;

    _noise = 0.10;

    _previousSignal = 0.0;

    _peakSignal = 0.0;

    _lastStepTime = null;

    _calibrationSamples = 0;

    _calibrationSum = 0.0;

    _steps = 0;

    _lastMagnitude = 0.0;

    _lastConfidence = 0.0;
  }

  // ============================================================
  // DEBUG
  // ============================================================

  String get debugInfo {
    return 'state=$_state '
        'mag=${magnitude.toStringAsFixed(3)} '
        'smooth=${smoothMagnitude.toStringAsFixed(3)} '
        'baseline=${baseline.toStringAsFixed(3)} '
        'signal=${signal.toStringAsFixed(3)} '
        'noise=${noise.toStringAsFixed(3)} '
        'threshold=${threshold.toStringAsFixed(3)} '
        'peak=${_peakSignal.toStringAsFixed(3)} '
        'confidence=${confidence.toStringAsFixed(2)} '
        'steps=$_steps';
  }
}

enum StepDetectorState { calibrating, idle, rising, peak, waitingReset }
