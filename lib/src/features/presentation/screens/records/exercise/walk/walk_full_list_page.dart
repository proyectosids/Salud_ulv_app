
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/models/exercise_summaries.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/get_all_exercise.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_repo.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/get_summart.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_state.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/containers.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/data_tiles.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/exercise_list_widgets.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/snackbar.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/tab_bar.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/tabs_menu.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class AllWalkRecordsPage extends StatelessWidget {
  const AllWalkRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ExerciseGetAllBLoc(
            allExerciseUseCase: GetAllExerciseUseCase(
              WalkRepo(),
              CurrentUserSession(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => ExerciseSummaryBloc(
            getExerciseSummary: GetExerciseSummaryUseCase(
              WalkRepo(),
              CurrentUserSession(),
            ),
          ),
        ),
      ],
      child: const _AllWalkRecordsPage(),
    );
  }
}

class _AllWalkRecordsPage extends StatefulWidget {
  const _AllWalkRecordsPage();

  @override
  State<_AllWalkRecordsPage> createState() => _AllWalkRecordsPageState();
}

class _AllWalkRecordsPageState extends State<_AllWalkRecordsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<ExerciseGetAllBLoc>().add(ExerciseGetAllEvent());
    context.read<ExerciseSummaryBloc>().add(
      ExerciseGetSummary(SummaryPeriod.week),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,

      appBar: AppBar(
        backgroundColor: context.colors.background,
        // toolbarHeight: 80,
        elevation: 0,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios_new, color: context.colors.primary),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Text("Historial", style: TextStyle(color: context.colors.textPrimary)),
        centerTitle: true,
      ),

      body: MultiBlocListener(
        listeners: [
          BlocListener<ExerciseGetAllBLoc, ExerciseState>(
            listener: (context, state) {
              if (state is ExerciseError) {
                CustomSnackBar.showError(context, state.message);
              }
            },
          ),

          BlocListener<ExerciseSummaryBloc, ExerciseState>(
            listener: (context, state) {
              if (state is ExerciseError) {
                CustomSnackBar.showError(context, state.message);
              }
            },
          ),
        ],

        child: SafeArea(
          top: true,
          bottom: true,

          child: SingleChildScrollView(
            key: _formKey,
            scrollDirection: .vertical,
            child: Padding(
              padding: EdgeInsets.all(context.spacing.xxs),
              child: Column(
                children: [
                  // SizedBox(height: context.spacing.radiusLg),
                  BackgroundContainer(
                    child: TabbedContainer(
                      pages: [
                        TabPage(
                          title: 'Sumatoria',
                          child: Column(
                            children: [
                              // Always visible
                              CustomTabBar(
                                tabs: [
                                  TabItem(
                                    label: 'Semana',
                                    onTap: () =>
                                        context.read<ExerciseSummaryBloc>().add(
                                          ExerciseGetSummary(SummaryPeriod.week),
                                        ),
                                  ),
                                  TabItem(
                                    label: 'Mes',
                                    onTap: () =>
                                        context.read<ExerciseSummaryBloc>().add(
                                          ExerciseGetSummary(SummaryPeriod.month),
                                        ),
                                  ),
                                  TabItem(
                                    label: 'Año',
                                    onTap: () =>
                                        context.read<ExerciseSummaryBloc>().add(
                                          ExerciseGetSummary(SummaryPeriod.year),
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.spacing.lg),
                    
                              // Reacts to the bloc
                              BlocBuilder<ExerciseSummaryBloc, ExerciseState>(
                                builder: (context, state) {
                                  if (state is ExerciseLoading) {
                                    return const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                    
                                  if (state is ExerciseSummaryLoaded) {
                                    final summary = state.summary;
                                    if (summary == null){
                                      return CustomTextWidget(label: 'Realiza caminatas para ver tu progreso', fontSize: context.fontsSize.body);
                                    }
                                    
                                    final steps = summary.metrics['Pasos'];
                                    final duration = summary.metrics['Duración'];
                                    final distance = summary.metrics['Distancia'];
                                    final burnedCalories = summary.metrics['Calorias quemadas'];
                                    final elevation = summary.metrics['Elevación'];
                                    final pace = summary.metrics['Ritmo'];
                                    final cadence = summary.metrics['Pasos por minuto'];
                                    // final duration = summary.metrics['Duración']!.sum;
                                    // debugPrint(formatDuration(Duration(seconds: duration.toInt())));

                                    debugPrint('${summary.startDate} ${summary.endDate}');
                                    debugPrint('${summary.recordCount}');
                                    
                    
                                    return Column(
                                      children: [
                                        CustomTextWidget(label: ' Periodo: ${formatDate(summary.startDate!)} - ${formatDate(summary.endDate!)}', fontSize: context.fontsSize.body, fontWeight: .w800,),
                                        SizedBox(height: context.spacing.md,),
                                        // CustomTextWidget(label: '${summary.recordCount}', fontSize: context.fontsSize.body),

                                        MetricSummaryCard(label: 'Pasos', metric: steps!, averageDecimals: 1,),
                                        SizedBox(height: context.spacing.sm,),
                                        DurationMetricCard(label: 'Duración', metric: duration!,),
                                        SizedBox(height: context.spacing.sm,),
                                        MetricSummaryCard(label: 'Distancia', metric: scaleMetric(distance!, 1/1000), averageDecimals: 1, titleSuffix: '(km)', totalDecimals: 1, maxDecimals: 1, minDecimals: 1,),
                                        SizedBox(height: context.spacing.sm,),
                                        MetricSummaryCard(label: 'Calorias quemadas', metric: burnedCalories!, titleSuffix: '(cal)', averageDecimals: 1, totalDecimals: 1, maxDecimals: 1, minDecimals: 1,),
                                        SizedBox(height: context.spacing.sm,),
                                        MetricSummaryCard(label: 'Elevación', metric: elevation!, titleSuffix: '(m)', averageDecimals: 1, totalDecimals: 1, maxDecimals: 1, minDecimals: 1,),
                                        SizedBox(height: context.spacing.sm,),
                                        MetricSummaryCard(label: 'Ritmo', metric: pace!, averageDecimals: 1, titleSuffix: '(min/kim)', totalDecimals: 1, maxDecimals: 1, minDecimals: 1,),
                                        SizedBox(height: context.spacing.sm,),
                                        MetricSummaryCard(label: 'Pasos por minuto', metric: cadence!, averageDecimals: 1,),
                                        SizedBox(height: context.spacing.sm,),

                                        // for (final entry
                                        //     in summary.metrics.entries)
                                        //   if (entry.value.count > 0)
                                        //     Padding(
                                        //       padding: EdgeInsets.only(
                                        //         bottom: context.spacing.sm,
                                        //       ),
                                        //       child: MetricSummaryCard(
                                        //         label: entry.key,
                                        //         metric: entry.value,
                                        //       ),
                                        //     ),
                                      ],
                                    );
                                  }
                    
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                    
                    
                    
                        TabPage(
                          title: 'Historial',
                          child: BlocBuilder<ExerciseGetAllBLoc, ExerciseState>(
                            builder: (context, state) {
                              if (state is ExerciseLoading) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                    
                              if (state is ExerciseListLoaded) {
                                final walks = state.data!.cast<Walk>();
                    
                                if (walks.isEmpty){
                                  return CustomTextWidget(label: 'Realiza caminatas para ver su historial', fontSize: context.fontsSize.body);
                                }        
                    
                                return Column(
                                  children: [
                                    for (final walk in walks)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: context.spacing.sm,
                                        ),
                                        // Replace with your own walk card
                                        child: ActivityCard(activity: walk,),
                                      ),
                                  ],
                                );
                              }
                    
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
