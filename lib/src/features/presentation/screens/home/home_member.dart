import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/get_recent_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/send_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/logout_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/get_recent_exercise.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/send_exercise.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/get_profile_info_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/get_user_name.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/anthropometrics/anthro_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/exercise/walk/walk_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/animations.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/containers.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/data_tiles.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/listviews.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/snackbar.dart';
import 'package:salud_ulv_app/src/features/services/check_connection.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/anthro_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/member_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/running_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/cycling_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/network/anthro_controller.dart';
import 'package:salud_ulv_app/src/core/data/source/network/exercise_controller.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/anthropometrics/register_anthro_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/profile/profile_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class MemberHomePage extends StatelessWidget {
  const MemberHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Logout
        BlocProvider(
          create: (context) => SendAnhroBloc(
            sendAnthroUsecase: SendAnthroUsecase(
              AnthroLocalStorage(),
              AnthroController(),
              CurrentUserSession(),
              CheckConnection(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => SendExerciseBloc(
            sendExerciseUseCase: SendExerciseUseCase(
              [WalkRepo(), RunningRepo(), CyclingRepo()],
              ExerciseController(),
              CurrentUserSession(),
              CheckConnection(),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => GetUserNameBloc(
            getUserName: GetUserNameUseCase(
              currentUserSession: CurrentUserSession(),
              userLocalRepo: UserLocalRepo(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) =>
              LogoutBloc(logoutUseCase: LogoutUsecase(TokenStorage())),
        ),

        BlocProvider(
          create: (context) => GetProfileInfoBloc(
            getUserInfoUsecase: GetProfileInfoUsecase(
              UserLocalRepo(),
              CurrentUserSession(),
              MemberLocalRepo(),
            ),
          ),
        ), // Send anthro data

        BlocProvider(
          create: (context) => ExerciseGetRecentBloc(
            recentExerciseUseCase: GetRecentExerciseUseCase(
              WalkRepo(),
              CurrentUserSession(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => GetAnthroRecentBloc(
            getRecentAnthroUsecase: GetRecentAnthroUsecase(
              AnthroLocalStorage(),
              CurrentUserSession(),
            ),
          ),
        ),
      ],
      child: const _MemberHomePage(),
    );
  }
}

class _MemberHomePage extends StatefulWidget {
  const _MemberHomePage();

  @override
  State<_MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<_MemberHomePage> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String _formatDuration(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    context.read<GetUserNameBloc>().add(GetUserNameEvent());
    context.read<ExerciseGetRecentBloc>().add((ExerciseGetRecentEvent()));
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
    return GradientBackground(
      // colors: [context.colors.onPrimary, context.colors.background],
      // stops: [0, 0.3],
      child: Scaffold(
        backgroundColor: Colors.transparent,

        body: SafeArea(
          top: true,
          bottom: true,

          child: MultiBlocListener(
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
                      "Datos antropométricos compartidos con Salud ULV",
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

              // BlocListener<GetUserNameBloc, ProfileState>(
              //   listener: (context, state) {
              //     if(state is ){
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(
              //           behavior: .floating,
              //           backgroundColor: context.colors.success  ,
              //           content: Text('Datos antropométricos compartidos con Salud ULV'))
              //         );
              //     }
              //   }
              // ),
              BlocListener<SendExerciseBloc, ExerciseState>(
                listener: (context, state) {
                  if (state is ExerciseSent) {
                    CustomSnackBar.showSuccess(
                      context,
                      'Actividades físicas sincronizadas con Salud ULV',
                    );
                  }
                },
              ),
            ],

            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(context.spacing.md),

                child: Column(
                  // mainAxisAlignment: .center,
                  // crossAxisAlignment: .stretch,
                  children: [
                    BlocBuilder<GetUserNameBloc, ProfileState>(
                      builder: (context, state) {
                        if (state is UserNameLoaded) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CustomTextWidget(
                                  label: "¡Hola, ${state.name[0]}!",
                                  fontSize: context.fontsSize.headline,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileMainPage(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    InitialsAvatar(
                                      firstName: state.name[0],
                                      lastName: state.name[1],
                                      size: context.iconSize.xl + 20,
                                    ),
                                    // CustomTextWidget(label: 'Perfil', fontSize: context.fontsSize.caption),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),

                    SizedBox(height: context.spacing.lg),

                    BlocBuilder<ExerciseGetRecentBloc, ExerciseState>(
                      builder: (context, state) {
                        if (state is ExerciseLoading) {
                          return const CircularProgressIndicator();
                        }
                        debugPrint(state.toString());

                        if (state is ExerciseRecentLoaded) {
                          if (state.data == null) {
                            return Column(
                              children: [
                                // SizedBox(height: context.spacing.md),
                                CustomTextWidget(
                                  label:
                                      "¿Quieres ver tus actividades recientes?",
                                  fontSize: context.fontsSize.body,
                                  fontWeight: FontWeight.w700,
                                ),
                                SizedBox(height: context.spacing.md),
                                // CustomTextWidget(
                                //   label:
                                //       "Agrega una caminata visualizar tu progreso personal",
                                //   fontSize: context.fontsSize.body,
                                // ),
                                SizedBox(height: context.spacing.md),

                                // SimpleButton(
                                //   label: "Agregar caminata",
                                //   color: context.colors.secondary,
                                //   textColor: context.colors.textSecondary,
                                //   onPressed: () => Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) => MainWrapper(),
                                //     ),
                                //   ),
                                // ),
                                CustomTextWidget(
                                  label:
                                      'Desliza a la derecha para comenzar una actividad',
                                  fontSize: context.fontsSize.caption,
                                  icon: Icons.arrow_right,
                                  iconSize: context.iconSize.xl,
                                ),
                              ],
                            );
                          }

                          // return RecentAnthropometricListView(data: state.data);

                          final walk = state.data! as Walk;
                          debugPrint('act in ui ${walk.activityID}');

                          return Column(
                            // mainAxisAlignment: .center,
                            crossAxisAlignment: .start,
                            children: [
                              Row(
                                // crossAxisAlignment: .stretch,
                                mainAxisAlignment: .spaceBetween,
                                children: [
                                  CustomTextWidget(
                                    // label: "Haz logrado ${walk.steps} pasos",
                                    label: 'Caminata reciente',
                                    fontSize: context.fontsSize.body,
                                    fontWeight: FontWeight.w700,
                                  ),

                                  // SizedBox(width: context.spacing.xxl,),
                                  SimpleButton(
                                    label: "Ver más",
                                    // color: Colors.transparent,
                                    fontSize: context.fontsSize.details,
                                    color: context.colors.surface,
                                    // borderColor: context.colors.textPrimary,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const WalkRecordsPage(),
                                      ),
                                    ),
                                  ),

                                  // GestureDetector(
                                  //   child: CustomTextWidget(
                                  //     label: "Ver más",
                                  //     fontSize: context.fontsSize.caption,
                                  //     fontWeight: FontWeight.w700,
                                  //   ),
                                  //   onTap: () => Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) =>
                                  //           const WalkRecordsPage(),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),

                              // SizedBox(height: context.spacing.md),
                              GestureDetector(
                                onLongPress: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WalkRecordsPage(),
                                  ),
                                ),
                                child: AutoScrollAnimation(
                                  // enabled: true,
                                  // speed: 10,
                                  builder: (context, controller) => CustomListView(
                                    controller: controller,
                                    orientation: .horizontal,
                                    scrollable: true,

                                    // spacing: 34,
                                    // runSpacing: 34,
                                    widgets: [
                                      GridDataTile(
                                        icon: FontAwesomeIcons
                                            .personWalkingDashedLineArrowRight,
                                        label: "Pasos",
                                        data: walk.steps!.toStringAsFixed(0),
                                        // sufix: 'm',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.ruler,
                                        label: "Distancia",
                                        data: walk.distance!.toStringAsFixed(2),
                                        sufix: 'm',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.stopwatch,
                                        label: "Duración",
                                        // data: '${walk.duration!.inHours}:${walk.duration!.inMinutes / 60}:${walk.duration!.inSeconds / 60}',
                                        data: _formatDuration(walk.duration!),
                                        sufix: '',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.fireFlameCurved,
                                        label: "Calorias quemadas",
                                        data: walk.caloriesBurned!
                                            .toStringAsFixed(2),
                                        sufix: 'cal',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.mountain,
                                        label: "Elevación ganada",
                                        data: walk.elevationGain!
                                            .toStringAsFixed(2),
                                        sufix: 'm',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.timeline,
                                        label: "Ritmo",
                                        data: walk.avgPace!.toStringAsFixed(2),
                                        sufix: 'min/km',
                                      ),

                                      // GridDataTile(
                                      //   icon: FontAwesomeIcons.shoePrints,
                                      //   label: "Pasos por minuto",
                                      //   data: walk.avgSteps!.toStringAsFixed(1),
                                      //   sufix: 'min/km'
                                      // ),
                                      GridDataTile(
                                        icon: FontAwesomeIcons.personWalking,
                                        label: "Pasos por minuto",
                                        data: walk.avgCadence!.toStringAsFixed(
                                          2,
                                        ),
                                        sufix: '',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              //
                            ],
                          );
                        }

                        return const SizedBox();
                      },
                    ),

                    SizedBox(height: context.spacing.lg),

                    BlocBuilder<GetAnthroRecentBloc, AnthroState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const CircularProgressIndicator();
                        }

                        if (state is AnthroRecentLoaded) {
                          if (state.data == null) {
                            return Column(
                              children: [
                                // SizedBox(height: context.spacing.md),
                                CustomTextWidget(
                                  label:
                                      "¿Quieres ver tus antropométricos recientes?",
                                  fontSize: context.fontsSize.body,
                                  fontWeight: FontWeight.w700,
                                ),
                                SizedBox(height: context.spacing.md),

                                // CustomTextWidget(
                                //   label:
                                //       "Agrega una caminata visualizar tu progreso personal",
                                //   fontSize: context.fontsSize.body,
                                // ),
                                // SizedBox(height: context.spacing.lg),
                                SimpleButton(
                                  label: "Agregar antropométricos",
                                  textColor: context.colors.onSecondary,
                                  color: context.colors.secondary,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RegisterAnthroPage(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: .start,

                            children: [
                              Row(
                                // crossAxisAlignment: .stretch,
                                mainAxisAlignment: .spaceBetween,
                                children: [
                                  CustomTextWidget(
                                    label: "Antropometría reciente",
                                    fontSize: context.fontsSize.body,
                                    fontWeight: FontWeight.w700,
                                  ),

                                  // SizedBox(width: context.spacing.xxl,),
                                  SimpleButton(
                                    label: "Ver más",
                                    fontSize: context.fontsSize.details,
                                    color: context.colors.surface,
                                    // borderColor: context.colors.textPrimary,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AnthroRecordsPage(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // SizedBox(height: context.spacing.md),
                              GestureDetector(
                                onLongPress: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AnthroRecordsPage(),
                                  ),
                                ),
                                child: AutoScrollAnimation(
                                  // enabled: true,
                                  // speed: 10,
                                  builder: (context, controller) => CustomListView(
                                    controller: controller,
                                    widgets: [
                                      GridDataTile(
                                        icon: FontAwesomeIcons.person,
                                        iconColor: context.colors.secondary,
                                        label: "Altura",
                                        data: "${(state.data!.height) / 100}",
                                        sufix: 'm',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.weightScale,
                                        iconColor: context.colors.secondary,
                                        label: "Peso",
                                        // data: '${walk.duration!.inHours}:${walk.duration!.inMinutes / 60}:${walk.duration!.inSeconds / 60}',
                                        data: state.data!.weight.toString(),
                                        sufix: 'kg',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.dumbbell,
                                        iconColor: context.colors.secondary,
                                        label: "SMM",
                                        data: state.data!.smm.toString(),
                                        sufix: 'kg',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.weightHanging,
                                        iconColor: context.colors.secondary,
                                        label: "M. Grasa",
                                        data: state.data!.fatMass.toString(),
                                        sufix: 'kg',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.percent,
                                        iconColor: context.colors.secondary,
                                        label: "Grasa ",
                                        data: state.data!.bodyFatPercentage
                                            .toString(),
                                        sufix: '%',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.weightScale,
                                        iconColor: context.colors.secondary,
                                        label: "IMC",
                                        data: state.data!.bmi.toString(),
                                        sufix: 'kg/m²',
                                      ),

                                      GridDataTile(
                                        icon: FontAwesomeIcons.rulerHorizontal,
                                        iconColor: context.colors.secondary,
                                        label: "ICC",
                                        data: state.data!.whr.toString(),
                                        // sufix: '',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
