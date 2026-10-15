import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/anthro_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/cycling_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/member_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/running_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/network/anthro_controller.dart';
import 'package:salud_ulv_app/src/core/data/source/network/exercise_controller.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/models/anthropometrics.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/get_recent_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/send_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/logout_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/get_recent_exercise.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/send_exercise.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/get_profile_info_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/get_user_name.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/anthropometrics/register_anthro_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/profile/profile_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/anthropometrics/anthro_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/snackbar.dart';
import 'package:salud_ulv_app/src/features/services/check_connection.dart';

class MemberHomePage extends StatelessWidget {
  const MemberHomePage({super.key, this.onActivitySelected});

  final VoidCallback? onActivitySelected;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SendAnhroBloc(
            sendAnthroUsecase: SendAnthroUsecase(
              AnthroLocalStorage(),
              AnthroController(),
              CurrentUserSession(),
              CheckConnection(),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => SendExerciseBloc(
            sendExerciseUseCase: SendExerciseUseCase(
              [WalkRepo(), RunningRepo(), CyclingRepo()],
              ExerciseController(),
              CurrentUserSession(),
              CheckConnection(),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => GetUserNameBloc(
            getUserName: GetUserNameUseCase(
              currentUserSession: CurrentUserSession(),
              userLocalRepo: UserLocalRepo(),
            ),
          ),
        ),
        BlocProvider(
          create: (_) =>
              LogoutBloc(logoutUseCase: LogoutUsecase(TokenStorage())),
        ),
        BlocProvider(
          create: (_) => GetProfileInfoBloc(
            getUserInfoUsecase: GetProfileInfoUsecase(
              UserLocalRepo(),
              CurrentUserSession(),
              MemberLocalRepo(),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => ExerciseGetRecentBloc(
            recentExerciseUseCase: GetRecentExerciseUseCase(
              WalkRepo(),
              CurrentUserSession(),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => GetAnthroRecentBloc(
            getRecentAnthroUsecase: GetRecentAnthroUsecase(
              AnthroLocalStorage(),
              CurrentUserSession(),
            ),
          ),
        ),
      ],
      child: _MemberHomeContent(onActivitySelected: onActivitySelected),
    );
  }
}

class _MemberHomeContent extends StatefulWidget {
  const _MemberHomeContent({this.onActivitySelected});
  final VoidCallback? onActivitySelected;

  @override
  State<_MemberHomeContent> createState() => _MemberHomeContentState();
}

class _MemberHomeContentState extends State<_MemberHomeContent> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    context.read<GetUserNameBloc>().add(GetUserNameEvent());
    context.read<ExerciseGetRecentBloc>().add(ExerciseGetRecentEvent());
    context.read<GetAnthroRecentBloc>().add(AnthroGetRecentEvent());
    _syncPendingLocalData();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (mounted && !results.contains(ConnectivityResult.none)) {
        _syncPendingLocalData();
      }
    });
  }

  void _syncPendingLocalData() {
    context.read<SendAnhroBloc>().add(AnthroSyncPending());
    context.read<SendExerciseBloc>().add(ExerciseSyncPending());
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExerciseGetRecentBloc, ExerciseState>(
          listener: (context, state) {
            if (state is ExerciseError) {
              CustomSnackBar.showError(context, state.message);
            }
          },
        ),
        BlocListener<SendAnhroBloc, AnthroState>(
          listener: (context, state) {
            if (state is AnthroSent) {
              CustomSnackBar.showSuccess(
                context,
                'Datos antropométricos sincronizados',
              );
            }
          },
        ),
        BlocListener<GetAnthroRecentBloc, AnthroState>(
          listener: (context, state) {
            if (state is AnthroError) {
              CustomSnackBar.showError(context, state.message);
            }
          },
        ),
        BlocListener<SendExerciseBloc, ExerciseState>(
          listener: (context, state) {
            if (state is ExerciseSent) {
              CustomSnackBar.showSuccess(
                context,
                'Actividades sincronizadas con Salud ULV',
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                sliver: SliverToBoxAdapter(child: _HomeHeader()),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _HealthOverview(onStart: widget.onActivitySelected),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Comienza una actividad',
                    action: 'Ver todas',
                    onTap: widget.onActivitySelected,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 126,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _QuickActivity(
                        label: 'Caminar',
                        icon: Icons.directions_walk_rounded,
                        color: const Color(0xFF0A7778),
                        onTap: widget.onActivitySelected,
                      ),
                      _QuickActivity(
                        label: 'Correr',
                        icon: Icons.directions_run_rounded,
                        color: const Color(0xFFB9532D),
                        onTap: widget.onActivitySelected,
                      ),
                      _QuickActivity(
                        label: 'Interior',
                        icon: Icons.fitness_center,
                        color: const Color(0xFF795184),
                        onTap: widget.onActivitySelected,
                      ),
                      _QuickActivity(
                        label: 'Ciclismo',
                        icon: Icons.directions_bike_rounded,
                        color: const Color(0xFF356783),
                        onTap: widget.onActivitySelected,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Tu salud hoy',
                    action: 'Antropometría',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AnthroRecordsPage(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverToBoxAdapter(child: _HealthCards()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetUserNameBloc, ProfileState>(
      builder: (context, state) {
        final names = state is UserNameLoaded ? state.name : const <String>[];
        final firstName = names.isNotEmpty ? names.first : 'Hola';
        final initials = names
            .take(2)
            .where((name) => name.isNotEmpty)
            .map((name) => name[0].toUpperCase())
            .join();
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salud ULV',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '¡Hola, $firstName! ¿Cómo te sientes hoy?',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileMainPage(),
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: context.colors.secondaryContainer,
                foregroundColor: context.colors.onSecondaryContainer,
                child: Text(
                  initials.isEmpty ? 'U' : initials,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HealthOverview extends StatelessWidget {
  const _HealthOverview({this.onStart});
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseGetRecentBloc, ExerciseState>(
      builder: (context, state) {
        final activity = state is ExerciseRecentLoaded ? state.data : null;
        final walk = activity is Walk ? activity : null;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.secondary,
                context.colors.secondary.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Resumen de movimiento',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _OverviewMetric(
                      value: walk == null ? '0' : '${walk.steps ?? 0}',
                      label: 'pasos recientes',
                    ),
                  ),
                  Expanded(
                    child: _OverviewMetric(
                      value: walk == null
                          ? '0.00'
                          : ((walk.distance ?? 0) / 1000).toStringAsFixed(2),
                      label: 'kilómetros',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: context.colors.secondary,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  walk == null ? 'Registrar actividad' : 'Moverme de nuevo',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white70)),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

class _QuickActivity extends StatelessWidget {
  const _QuickActivity({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 105,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.16),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _HealthCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetAnthroRecentBloc, AnthroState>(
      builder: (context, state) {
        if (state is AnthroLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = state is AnthroRecentLoaded ? state.data : null;
        return data == null
            ? const _AnthroEmptyCard()
            : _AnthroGrid(data: data);
      },
    );
  }
}

class _AnthroGrid extends StatelessWidget {
  const _AnthroGrid({required this.data});
  final Anthropometrics data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Peso', data.weight.toStringAsFixed(1), 'kg', Icons.monitor_weight),
      ('IMC', data.bmi.toStringAsFixed(1), '', Icons.speed_rounded),
      (
        'Grasa corporal',
        data.bodyFatPercentage.toStringAsFixed(1),
        '%',
        Icons.water_drop_rounded,
      ),
      ('Músculo', data.smm.toStringAsFixed(1), 'kg', Icons.fitness_center),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _HealthMetricCard(
                  label: metric.$1,
                  value: metric.$2,
                  unit: metric.$3,
                  icon: metric.$4,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 145),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colors.secondary),
        // The card lives inside a Wrap, which does not impose a finite height.
        // A fixed gap keeps the layout responsive without using a flex child.
        const SizedBox(height: 24),
        Text(label, style: TextStyle(color: context.colors.textSecondary)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            children: [
              TextSpan(
                text: unit.isEmpty ? '' : ' $unit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AnthroEmptyCard extends StatelessWidget {
  const _AnthroEmptyCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.colors.border),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: context.colors.secondaryContainer,
          foregroundColor: context.colors.onSecondaryContainer,
          child: const Icon(Icons.monitor_weight_outlined),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completa tu resumen de salud',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text('Registra peso y composición corporal.'),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Agregar antropometría',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => RegisterAnthroPage()),
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
  );
}
