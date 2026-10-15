import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salud_ulv_app/src/core/services/exercise_audio_cue_service.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_event.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/exercise%20tracking/exercise_tracking_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

class ExerciseCatalogPage extends StatefulWidget {
  const ExerciseCatalogPage({super.key});

  @override
  State<ExerciseCatalogPage> createState() => _ExerciseCatalogPageState();
}

class _ExerciseCatalogPageState extends State<ExerciseCatalogPage> {
  bool _audioEnabled = true;
  int _audioInterval = 1000;

  static const _activities = [
    _ActivityOption(
      type: ExerciseType.walk,
      title: 'Caminata al aire libre',
      description: 'Pasos, distancia, ruta y ritmo',
      icon: Icons.directions_walk_rounded,
      colors: [Color(0xFF0A6F73), Color(0xFF16404D)],
    ),
    _ActivityOption(
      type: ExerciseType.running,
      title: 'Correr al aire libre',
      description: 'Ruta, pasos, ritmo y velocidad',
      icon: Icons.directions_run_rounded,
      colors: [Color(0xFFB24D28), Color(0xFF5D2B32)],
    ),
    _ActivityOption(
      type: ExerciseType.indoorRunning,
      title: 'Correr en interiores',
      description: 'Avance por pasos, sin mapa',
      icon: Icons.fitness_center,
      colors: [Color(0xFF6D477E), Color(0xFF2D314A)],
    ),
    _ActivityOption(
      type: ExerciseType.cycling,
      title: 'Ciclismo al aire libre',
      description: 'Ruta, distancia y velocidad',
      icon: Icons.directions_bike_rounded,
      colors: [Color(0xFF315D78), Color(0xFF18394A)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAudioPreferences();
  }

  Future<void> _loadAudioPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _audioEnabled = preferences.getBool(exerciseAudioEnabledKey) ?? true;
      _audioInterval = preferences.getInt(exerciseAudioIntervalKey) ?? 1000;
    });
  }

  Future<void> _saveAudioPreferences({bool? enabled, int? interval}) async {
    final preferences = await SharedPreferences.getInstance();
    if (enabled != null) {
      await preferences.setBool(exerciseAudioEnabledKey, enabled);
    }
    if (interval != null) {
      await preferences.setInt(exerciseAudioIntervalKey, interval);
    }
  }

  Future<void> _openActivity(_ActivityOption activity) async {
    context.read<ExerciseTrackingBloc>().add(
      SelectExerciseTypeEvent(activity.type),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExerciseTrackerMainPage(onExit: () => Navigator.of(context).pop()),
      ),
    );
  }

  Future<void> _showAudioSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avisos durante la actividad',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'La voz indicará distancia, tiempo del tramo y ritmo. Funciona sin internet.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorios de audio'),
                  value: _audioEnabled,
                  onChanged: (value) {
                    setState(() => _audioEnabled = value);
                    setSheetState(() {});
                    _saveAudioPreferences(enabled: value);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Frecuencia',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 500, label: Text('Cada 500 m')),
                    ButtonSegment(value: 1000, label: Text('Cada 1 km')),
                  ],
                  selected: {_audioInterval},
                  onSelectionChanged: _audioEnabled
                      ? (selection) {
                          final value = selection.first;
                          setState(() => _audioInterval = value);
                          setSheetState(() {});
                          _saveAudioPreferences(interval: value);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actividades',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Elige cómo quieres moverte hoy',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Configurar avisos de audio',
                      onPressed: _showAudioSettings,
                      icon: Icon(
                        _audioEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              sliver: SliverList.separated(
                itemCount: _activities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  return _ActivityCard(
                    activity: activity,
                    onTap: () => _openActivity(activity),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});

  final _ActivityOption activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Iniciar ${activity.title}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          height: 190,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: activity.colors),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -25,
                  child: Icon(
                    activity.icon,
                    size: 170,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activity.icon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.description,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
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

class _ActivityOption {
  const _ActivityOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });

  final ExerciseType type;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
}
