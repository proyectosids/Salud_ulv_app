import 'location_track_filter.dart';

class StepFusionResult {
  const StepFusionResult({
    required this.confirmedSteps,
    required this.confidence,
  });

  final int confirmedSteps;
  final double confidence;
}

/// Confirms accelerometer candidates as a coherent walking/running bout.
///
/// A reliable stationary GPS fix is a hard veto. When location is unavailable,
/// a longer and more regular cadence is required before releasing candidates.
class StepFusionTracker {
  StepFusionTracker({
    this.minimumInterval = const Duration(milliseconds: 280),
    this.maximumInterval = const Duration(milliseconds: 1300),
    this.movingWarmupSteps = 3,
    this.locationlessWarmupSteps = 6,
  });

  final Duration minimumInterval;
  final Duration maximumInterval;
  final int movingWarmupSteps;
  final int locationlessWarmupSteps;

  final List<DateTime> _pending = [];
  DateTime? _lastCandidateAt;
  bool _boutConfirmed = false;
  LocationMotionState? _lastMotionState;

  StepFusionResult addCandidate({
    required DateTime timestamp,
    required LocationMotionState motionState,
    required double detectorConfidence,
  }) {
    if (motionState == LocationMotionState.stationary) {
      reset();
      _lastMotionState = motionState;
      return const StepFusionResult(confirmedSteps: 0, confidence: 0);
    }

    if (_lastMotionState != motionState) {
      _pending.clear();
      _boutConfirmed = false;
    }
    _lastMotionState = motionState;

    final last = _lastCandidateAt;
    if (last != null) {
      final interval = timestamp.difference(last);
      if (interval < minimumInterval) {
        return const StepFusionResult(confirmedSteps: 0, confidence: 0);
      }
      if (interval > maximumInterval) {
        _pending.clear();
        _boutConfirmed = false;
      }
    }
    _lastCandidateAt = timestamp;

    if (_boutConfirmed) {
      return StepFusionResult(
        confirmedSteps: 1,
        confidence: motionState == LocationMotionState.moving
            ? detectorConfidence.clamp(0.75, 1.0)
            : detectorConfidence.clamp(0.55, 0.85),
      );
    }

    _pending.add(timestamp);
    final warmup = motionState == LocationMotionState.moving
        ? movingWarmupSteps
        : locationlessWarmupSteps;
    if (_pending.length < warmup || !_hasRegularCadence()) {
      return const StepFusionResult(confirmedSteps: 0, confidence: 0);
    }

    final released = _pending.length;
    _pending.clear();
    _boutConfirmed = true;
    return StepFusionResult(
      confirmedSteps: released,
      confidence: motionState == LocationMotionState.moving ? 0.9 : 0.65,
    );
  }

  bool _hasRegularCadence() {
    if (_pending.length < 3) return false;
    final intervals = <int>[];
    for (var index = 1; index < _pending.length; index++) {
      intervals.add(
        _pending[index].difference(_pending[index - 1]).inMilliseconds,
      );
    }
    final average = intervals.reduce((a, b) => a + b) / intervals.length;
    final maxDeviation = intervals
        .map((value) => (value - average).abs())
        .reduce((a, b) => a > b ? a : b);
    return maxDeviation <= average * 0.35;
  }

  void reset() {
    _pending.clear();
    _lastCandidateAt = null;
    _boutConfirmed = false;
    _lastMotionState = null;
  }
}
