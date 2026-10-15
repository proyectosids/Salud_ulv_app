import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sensors/geolocator_sensor.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/services/current_location_cache.dart';
import 'package:salud_ulv_app/src/core/services/exercise_audio_cue_service.dart';
import 'package:salud_ulv_app/src/core/usecase/location/get_current_position.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/location_bloc/location_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/location_bloc/location_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/location_bloc/location_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/exercise%20tracking/exercise_summary_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/map.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/snackbar.dart';

class ExerciseTrackerMainPage extends StatelessWidget {
  const ExerciseTrackerMainPage({super.key, this.onExit});

  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetCurrentLocationBloc(
        currentLocation: GetUserCurrentPosition(GeolocatorSensor()),
      ),
      child: _ExerciseTrackerMainPage(onExit: onExit),
    );
  }
}

class _ExerciseTrackerMainPage extends StatefulWidget {
  const _ExerciseTrackerMainPage({this.onExit});
  final VoidCallback? onExit;

  @override
  State<_ExerciseTrackerMainPage> createState() =>
      _ExerciseTrackerMainPageState();
}

class _ExerciseTrackerMainPageState extends State<_ExerciseTrackerMainPage> {
  final MapController _mapController = MapController();
  final StreamController<double?> _alignPositionController =
      StreamController<double?>.broadcast();
  final StreamController<void> _alignDirectionController =
      StreamController<void>.broadcast();
  final StreamController<LocationMarkerPosition?> _mapPositionController =
      StreamController<LocationMarkerPosition?>.broadcast();
  final List<LatLng> _routePoints = [];
  final ExerciseAudioCueService _audioCues = ExerciseAudioCueService();
  LatLng? _initialLocation;
  LatLng? _startPoint;
  LatLng? _endPoint;
  bool _satellite = false;
  bool _followLocation = true;
  String? _locationMessage;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_audioCues.initialize());
    if (context.read<ExerciseTrackingBloc>().state.selectedType !=
        ExerciseType.indoorRunning) {
      final cached = CurrentLocationCache.instance.current;
      if (cached != null) {
        _initialLocation = LatLng(cached.latitude, cached.longitude);
      }
      context.read<GetCurrentLocationBloc>().add(GetCurrentLocation());
    }
  }

  @override
  void dispose() {
    unawaited(_audioCues.stop());
    _alignPositionController.close();
    _alignDirectionController.close();
    _mapPositionController.close();
    _mapController.dispose();
    super.dispose();
  }

  void _centerMap() {
    final target = _routePoints.isNotEmpty
        ? _routePoints.last
        : _initialLocation;
    if (target == null) {
      CustomSnackBar.show(
        context,
        message: 'Esperando la primera posición GPS',
      );
      return;
    }
    setState(() => _followLocation = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _publishMapPosition(target);
      _alignPositionController.add(17);
      _alignDirectionController.add(null);
    });
  }

  void _publishMapPosition(LatLng location) {
    _mapPositionController.add(
      LocationMarkerPosition(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: 0,
      ),
    );
  }

  void _stopFollowingMap() {
    if (!_followLocation || !mounted) return;
    setState(() => _followLocation = false);
  }

  void _onTrackingState(ExerciseTrackingState state) {
    if (state is TrackingExercise) {
      unawaited(
        _audioCues.announceProgress(
          distanceMeters: state.distance ?? 0,
          elapsed: state.timeElapsed,
        ),
      );
      var changed = false;
      if (state.startLocation != null && _startPoint == null) {
        _startPoint = LatLng(
          state.startLocation!.latitude,
          state.startLocation!.longitude,
        );
        changed = true;
      }
      if (state.currentLocation != null) {
        final point = LatLng(
          state.currentLocation!.latitude,
          state.currentLocation!.longitude,
        );
        final isNew =
            _routePoints.isEmpty ||
            _routePoints.last.latitude != point.latitude ||
            _routePoints.last.longitude != point.longitude;
        if (isNew) {
          _routePoints.add(point);
          _publishMapPosition(point);
          changed = true;
        }
      }
      if (changed && mounted) setState(() {});
    }

    if (state is ExerciseSaved) {
      _finishing = false;
      if (state.endLocation != null) {
        _endPoint = LatLng(
          state.endLocation!.latitude,
          state.endLocation!.longitude,
        );
        if (_routePoints.isEmpty || _routePoints.last != _endPoint) {
          _routePoints.add(_endPoint!);
        }
      }
      final completedRoute = List<LatLng>.unmodifiable(_routePoints);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ExerciseSummaryPage(result: state, routePoints: completedRoute),
        ),
      );
      CustomSnackBar.show(
        context,
        message: 'Actividad guardada automáticamente',
      );
    }

    if (state is ExerciseDiscarded) {
      _finishing = false;
      CustomSnackBar.show(context, message: 'Actividad descartada');
    }
    if (state is ExerciseError) {
      _finishing = false;
      CustomSnackBar.showError(context, state.message);
    }
    if (state is ExercisePermissionsDenied) {
      CustomSnackBar.show(
        context,
        message: state.message,
        backgroundColor: context.colors.danger,
        action: state.canOpenSettings
            ? SnackBarAction(
                label: 'Abrir ajustes',
                onPressed: () => context.read<ExerciseTrackingBloc>().add(
                  OpenExercisePermissionSettingsEvent(),
                ),
              )
            : null,
      );
    }
    if (state is ExerciseInitial) {
      _audioCues.reset();
      if (_routePoints.isNotEmpty || _startPoint != null || _endPoint != null) {
        setState(() {
          _startPoint = null;
          _endPoint = null;
          _routePoints.clear();
        });
      }
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar actividad?'),
        content: const Text(
          'Se eliminarán la ruta y las mediciones de esta sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      context.read<ExerciseTrackingBloc>().add(DiscardExerciseEvent());
      setState(() {
        _startPoint = null;
        _endPoint = null;
        _routePoints.clear();
      });
    }
  }

  bool _hasEnoughActivity(ExercisePaused state) {
    if (state.timeElapsed.inSeconds < 10) return false;

    return switch (state.selectedType) {
      ExerciseType.walk => (state.steps ?? 0) > 0,
      ExerciseType.running ||
      ExerciseType.indoorRunning ||
      ExerciseType.cycling => (state.distance ?? 0) > 0,
    };
  }

  Future<void> _finishExercise(ExercisePaused state) async {
    if (_finishing) return;

    if (_hasEnoughActivity(state)) {
      setState(() => _finishing = true);
      context.read<ExerciseTrackingBloc>().add(SaveExerciseEvent());
      return;
    }

    final finish = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Actividad insuficiente'),
        content: const Text(
          'No hay suficiente información para crear un registro. '
          'Si finalizas, esta sesión se descartará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Finalizar',
              style: TextStyle(color: context.colors.danger),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (finish == true) {
      setState(() => _finishing = true);
      // The domain save operation intentionally rejects sessions without
      // enough activity. Confirming this dialog means discard, not save.
      context.read<ExerciseTrackingBloc>().add(DiscardExerciseEvent());
    } else if (finish == false) {
      context.read<ExerciseTrackingBloc>().add(ResumeExerciseEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExerciseTrackingBloc, ExerciseTrackingState>(
          listener: (_, state) => _onTrackingState(state),
        ),
        BlocListener<GetCurrentLocationBloc, LocationState>(
          listener: (context, state) {
            if (state is CurrentLocationLoaded) {
              final location = LatLng(
                state.currentLocation.latitude,
                state.currentLocation.longitude,
              );
              setState(() {
                _initialLocation = location;
                _locationMessage = null;
              });
              CurrentLocationCache.instance.update(
                Coordinates(
                  latitude: location.latitude,
                  longitude: location.longitude,
                ),
              );
              _publishMapPosition(location);
            } else if (state is LocationUnavailable) {
              setState(
                () => _locationMessage =
                    'Esperando una ubicación GPS reciente y precisa',
              );
            } else if (state is LocationError) {
              setState(() => _locationMessage = state.message);
            }
          },
        ),
      ],
      child: BlocBuilder<ExerciseTrackingBloc, ExerciseTrackingState>(
        builder: (context, state) {
          final active = state is ActiveExerciseState;
          final indoor = state.selectedType == ExerciseType.indoorRunning;
          return Scaffold(
            backgroundColor: context.colors.background,
            body: Stack(
              children: [
                Positioned.fill(
                  child: indoor
                      ? _IndoorTrackBackdrop(
                          elapsed: active ? state.timeElapsed : Duration.zero,
                          moving: state is TrackingExercise,
                        )
                      : _initialLocation == null && _routePoints.isEmpty
                      ? const _PreparingLocationBackdrop()
                      : MapWidget(
                          initialCenter: _initialLocation,
                          startPoint: _startPoint,
                          endPoint: _endPoint,
                          routePoints: _routePoints,
                          mapController: _mapController,
                          satellite: _satellite,
                          navigationMode: true,
                          followCurrentLocation: _followLocation,
                          onUserInteraction: _stopFollowingMap,
                          positionStream: _mapPositionController.stream,
                          alignPositionStream: _alignPositionController.stream,
                          alignDirectionStream:
                              _alignDirectionController.stream,
                          mapReady: () {
                            final location = _routePoints.isNotEmpty
                                ? _routePoints.last
                                : _initialLocation;
                            if (location != null) {
                              _publishMapPosition(location);
                            }
                          },
                        ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.44),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.12),
                          ],
                          stops: const [0, 0.32, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      children: [
                        _TopBar(
                          title: active
                              ? state.selectedType.label
                              : 'Actividad al aire libre',
                          onExit: widget.onExit,
                        ),
                        if (!indoor && _locationMessage != null) ...[
                          const SizedBox(height: 10),
                          _OfflineStatus(
                            message:
                                'Mapa local activo · esperando ubicación GPS',
                            onRetry: () => context
                                .read<GetCurrentLocationBloc>()
                                .add(GetCurrentLocation()),
                          ),
                        ],
                        if (active) ...[
                          const SizedBox(height: 18),
                          _LiveMetrics(state: state),
                        ],
                        const Spacer(),
                        if (!active)
                          _StartPanel(state: state)
                        else if (state is ExercisePaused)
                          _PausedPanel(
                            onResume: () => context
                                .read<ExerciseTrackingBloc>()
                                .add(ResumeExerciseEvent()),
                            onDiscard: _confirmDiscard,
                            onFinish: () => _finishExercise(state),
                          )
                        else
                          _TrackingControls(
                            onPause: () => context
                                .read<ExerciseTrackingBloc>()
                                .add(PauseExerciseEvent()),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!indoor)
                  Positioned(
                    right: 14,
                    top: MediaQuery.paddingOf(context).top + 76,
                    child: Column(
                      children: [
                        _MapButton(
                          icon: Icons.layers_outlined,
                          selected: _satellite,
                          tooltip: 'Cambiar tipo de mapa',
                          onPressed: () =>
                              setState(() => _satellite = !_satellite),
                        ),
                        const SizedBox(height: 10),
                        _MapButton(
                          icon: Icons.my_location_rounded,
                          selected: _followLocation,
                          tooltip: 'Centrar ubicación',
                          onPressed: _centerMap,
                        ),
                      ],
                    ),
                  ),
                if (_finishing)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.38),
                        child: const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Text('Guardando actividad…'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onExit});
  final String title;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Volver al inicio',
          onPressed: onExit,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(blurRadius: 12, color: Colors.black54)],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveMetrics extends StatelessWidget {
  const _LiveMetrics({required this.state});
  final ActiveExerciseState state;

  String get _pace {
    final speed = state.speed;
    if (speed == null || speed < 0.5) return '--:--';
    final total = 1000 / speed;
    return '${total ~/ 60}:${(total % 60).round().toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, String value})>[
      (label: 'DURACIÓN', value: formatDuration(state.timeElapsed)),
      (
        label: 'DISTANCIA',
        value: '${((state.distance ?? 0) / 1000).toStringAsFixed(2)} km',
      ),
      (
        label: state.selectedType == ExerciseType.cycling
            ? 'VELOCIDAD'
            : 'RITMO',
        value: state.selectedType == ExerciseType.cycling
            ? '${((state.speed ?? 0) * 3.6).toStringAsFixed(1)} km/h'
            : '$_pace /km',
      ),
      if (state.selectedType != ExerciseType.cycling)
        (label: 'PASOS', value: '${state.steps ?? 0}'),
    ];

    return Semantics(
      liveRegion: true,
      label:
          'Duración ${formatDuration(state.timeElapsed)}, distancia ${((state.distance ?? 0) / 1000).toStringAsFixed(2)} kilómetros${state.selectedType == ExerciseType.cycling ? '' : ', ${state.steps ?? 0} pasos'}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = metrics.length == 4 ? 2 : 3;
          final metricWidth =
              (constraints.maxWidth - ((columns - 1) * 10)) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: metricWidth,
                  child: _GlassMetric(label: metric.label, value: metric.value),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassMetric extends StatelessWidget {
  const _GlassMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({required this.state});
  final ExerciseTrackingState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(blurRadius: 24, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.colors.secondaryContainer,
                foregroundColor: context.colors.onSecondaryContainer,
                child: Icon(state.selectedType.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.selectedType.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      state.selectedType == ExerciseType.indoorRunning
                          ? 'Avance por movimiento, sin ruta GPS'
                          : 'GPS listo para registrar tu ruta',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                context.read<ExerciseTrackingBloc>().add(StartExerciseEvent()),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Comenzar'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El registro y la ruta se guardan en este dispositivo, incluso sin internet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TrackingControls extends StatelessWidget {
  const _TrackingControls({required this.onPause});
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pausar actividad',
      child: FloatingActionButton.large(
        heroTag: 'pause-exercise',
        onPressed: onPause,
        backgroundColor: context.colors.danger,
        foregroundColor: Colors.white,
        child: const Icon(Icons.pause_rounded, size: 42),
      ),
    );
  }
}

class _PausedPanel extends StatelessWidget {
  const _PausedPanel({
    required this.onResume,
    required this.onDiscard,
    required this.onFinish,
  });
  final VoidCallback onResume;
  final VoidCallback onDiscard;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 28, color: Colors.black38)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RoundExerciseAction(
                tooltip: 'Descartar actividad',
                icon: Icons.delete_outline_rounded,
                backgroundColor: context.colors.surfaceMuted,
                foregroundColor: context.colors.textPrimary,
                onPressed: onDiscard,
              ),
              _RoundExerciseAction(
                tooltip: 'Continuar actividad',
                icon: Icons.play_arrow_rounded,
                backgroundColor: context.colors.success,
                foregroundColor: Colors.white,
                size: 86,
                iconSize: 48,
                onPressed: onResume,
              ),
              _HoldToFinishButton(onFinished: onFinish),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mantén el botón rojo para finalizar',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundExerciseAction extends StatelessWidget {
  const _RoundExerciseAction({
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.size = 62,
    this.iconSize = 30,
  });

  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, color: foregroundColor, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldToFinishButton extends StatefulWidget {
  const _HoldToFinishButton({required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<_HoldToFinishButton> createState() => _HoldToFinishButtonState();
}

class _HoldToFinishButtonState extends State<_HoldToFinishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1300),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.mediumImpact();
          widget.onFinished();
        }
      });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start(LongPressStartDetails _) => _controller.forward(from: 0);
  void _cancel([Object? _]) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.animateBack(0, duration: const Duration(milliseconds: 180));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mantén presionado para finalizar y guardar la actividad',
      child: GestureDetector(
        onLongPressStart: _start,
        onLongPressEnd: _cancel,
        onLongPressCancel: _cancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => SizedBox.square(
            dimension: 94,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 94,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: _controller.value > 0 ? 78 : 82,
                  height: _controller.value > 0 ? 78 : 82,
                  decoration: BoxDecoration(
                    color: context.colors.danger,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(blurRadius: 12, color: Colors.black38),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndoorTrackBackdrop extends StatelessWidget {
  const _IndoorTrackBackdrop({required this.elapsed, required this.moving});

  final Duration elapsed;
  final bool moving;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final alternate = elapsed.inSeconds.isEven;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111923), Color(0xFF18232A), Color(0xFF090D13)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _TrackPainter())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 150,
            child: AnimatedAlign(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              alignment: moving
                  ? (alternate
                        ? const Alignment(-0.12, 0)
                        : const Alignment(0.12, 0))
                  : Alignment.center,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: context.colors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.secondary.withValues(alpha: 0.35),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparingLocationBackdrop extends StatelessWidget {
  const _PreparingLocationBackdrop();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Preparando tu ubicación GPS',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF102128), Color(0xFF17353B), Color(0xFF081014)],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 14),
                Flexible(
                  child: Text(
                    'Preparando tu ubicación GPS…',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final lane = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final accent = Paint()
      ..color = const Color(0xFFFF8A3D).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final horizon = size.height * 0.34;
    for (var index = 0; index < 4; index++) {
      final inset = size.width * (0.08 + index * 0.11);
      final path = ui.Path()
        ..moveTo(size.width / 2, horizon)
        ..lineTo(inset, size.height);
      canvas.drawPath(path, lane);
      final mirrored = ui.Path()
        ..moveTo(size.width / 2, horizon)
        ..lineTo(size.width - inset, size.height);
      canvas.drawPath(mirrored, lane);
    }

    for (var index = 0; index < 5; index++) {
      final y = horizon + (size.height - horizon) * (index + 1) / 6;
      final width = 18.0 + index * 12;
      final chevron = ui.Path()
        ..moveTo(size.width / 2 - width, y)
        ..lineTo(size.width / 2, y + 18)
        ..lineTo(size.width / 2 + width, y)
        ..lineTo(size.width / 2, y + 34)
        ..close();
      canvas.drawPath(chevron, accent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfflineStatus extends StatelessWidget {
  const _OfflineStatus({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.66),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.offline_bolt_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: tooltip,
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: selected
          ? context.colors.secondary
          : context.colors.surface,
      foregroundColor: selected
          ? context.colors.onSecondary
          : context.colors.textPrimary,
      child: Icon(icon),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}
