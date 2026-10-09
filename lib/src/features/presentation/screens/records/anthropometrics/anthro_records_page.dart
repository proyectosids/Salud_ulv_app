import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/member_repo.dart';
import 'package:salud_ulv_app/src/core/models/anthropometrics.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/check_recent.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/get_byfield_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/getall_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
// import 'package:salud_ulv_app/src/core/usecase/anthropometrics/getall_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/anthro_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/anthropometrics/register_anthro_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/profile/profile_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/eval_value.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/exercise_list_widgets.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/value_range.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/containers.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/data_tiles.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class AnthroRecordsPage extends StatelessWidget {
  const AnthroRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (create) => GetAnthroAllBloc(
            getallAnthroUsecase: GetallAnthroUsecase(
              AnthroLocalStorage(),
              CurrentUserSession(),
            ),
          ),
        ),

        // BlocProvider(
        //   create: (context) => AnthroGetAllBloc(getallAnthroUsecase: GetallAnthroUsecase(AnthroLocalStorage()))),
        BlocProvider(
          create: (context) => GetAnthroByFieldBloc(
            getByfieldAnthroUsecase: GetByfieldAnthroUsecase(
              AnthroLocalStorage(),
              CurrentUserSession(),
            ),
          ),
        ),

        BlocProvider(
          create: ((context) => EvalRecentAnthroBloc(
            checkRecentAnthroUseCase: CheckRecentAnthroUseCase(
              AnthroLocalStorage(),
              CurrentUserSession(),
              MemberLocalRepo(),
            ),
          )),
        ),
      ],

      child: const _AnthroRecordsPage(),
    );
  }
}

class _AnthroRecordsPage extends StatefulWidget {
  const _AnthroRecordsPage();

  @override
  State<_AnthroRecordsPage> createState() => _AnthroRecordsPageState();
}

class _AnthroRecordsPageState extends State<_AnthroRecordsPage> {
  final _formKey = GlobalKey<FormState>();

  late List<Anthropometrics> records;

  late int _index = records.length - 1;

  bool get _hasPrevious => _index > 0;
  bool get _hasNext => _index < records.length - 1;

  void _goPrevious() {
    if (!_hasPrevious) return;
    setState(() => _index--);
  }

  void _goNext() {
    if (!_hasNext) return;
    setState(() => _index++);
  }

  @override
  void initState() {
    super.initState();
    // context.read<GetAnthroRecentBloc>().add(AnthroGetRecentEvent());
    context.read<GetAnthroAllBloc>().add(AnthroGetAllEvent());
    context.read<EvalRecentAnthroBloc>().add(AnthroEvaluationEvent());
    // context.read<GetAnthroAllBloc>().add(A);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      // colors: [context.colors.background, context.colors.background, context.colors.tertiary],
      // stops: [0, 0.35, 1],

      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: context.colors.background,
          // toolbarHeight: 80,
          elevation: 0,
          // leading: IconButton(
          //   icon: Icon(Icons.arrow_back_ios_new, color: context.colors.primary),
          //   onPressed: () => Navigator.pop(context),
          // ),
          title: Text(
            'Antropometría',
            style: TextStyle(color: context.colors.textPrimary),
          ),
          centerTitle: true,

          actions: [
            CustomIconButton(
              icon: Icons.add_circle_rounded,
              label: "Agregar",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterAnthroPage()),
              ),
            ),
          ],
        ),

        body: SafeArea(
          top: true,
          bottom: true,

          child: MultiBlocListener(
            listeners: [
              BlocListener<GetAnthroAllBloc, AnthroState>(
                listener: (context, state) {
                  if (state is AnthroError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
              ),
              BlocListener<GetAnthroByFieldBloc, AnthroState>(
                listener: (context, state) {
                  if (state is AnthroError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
              ),
              BlocListener<EvalRecentAnthroBloc, AnthroState>(
                listener: (context, state) {
                  // if (state is AnthroError) {
                  //   CustomSnackBar.showError(context, state.message);
                  // }
                },
              ),
            ],

            child: SafeArea(
              child: SingleChildScrollView(
                key: _formKey,
                scrollDirection: .vertical,

                child: Column(
                  // mainAxisSize: .min,
                  children: [
                    BlocBuilder<GetAnthroAllBloc, AnthroState>(
                      builder: (context, state) {
                        if (state is AnthroLoading) {
                          return const CircularProgressIndicator();
                        }

                        if (state is AnthroListLoaded) {
                          if (state.data == null) {
                            return Column(
                              children: [
                                SizedBox(height: context.spacing.xxl),

                                CustomTextWidget(
                                  label:
                                      "Parece que no hay datos antropométicos registrados",
                                  fontWeight: FontWeight.w700,
                                  fontSize: context.fontsSize.title,
                                ),
                                SizedBox(height: context.spacing.md),
                                CustomTextWidget(
                                  label:
                                      "Agregalos para visualizar tu progreso personal",
                                  fontSize: context.fontsSize.body,
                                ),
                                SizedBox(height: context.spacing.lg),

                                SimpleButton(
                                  label: "Agregar datos",
                                  fontSize: context.fontsSize.body,
                                  color: context.colors.secondary,
                                  textColor: context.colors.onSecondary,
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

                          records = state.data!;
                          final current = records[_index];

                          return Padding(
                            padding: EdgeInsets.all(context.spacing.md),
                            child: Column(
                              mainAxisAlignment: .start,
                              children: [
                                RecordListPaginator(
                                  title: formatDateWithWord(
                                    current.registeredAt!,
                                  ),
                                  subtitle:
                                      'Registro ${_index + 1} de ${records.length}',
                                  hasPrevious: _hasPrevious,
                                  hasNext: _hasNext,
                                  onPrevious: _goPrevious,
                                  onNext: _goNext,
                                ),

                                SizedBox(height: context.spacing.sm),

                                BackgroundContainer(
                                  child: Column(
                                    // mainAxisAlignment: .start,
                                    crossAxisAlignment: .stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: .spaceEvenly,
                                        mainAxisSize: .min,
                                        crossAxisAlignment: .center,
                                        children: [
                                          GridDataTileTrasparent(
                                            label: 'Altura',
                                            data: current.height
                                                .toStringAsFixed(1),
                                            icon: FontAwesomeIcons.ruler,
                                            width: 150,
                                            sufix: 'cm',
                                          ),
                                          GridDataTileTrasparent(
                                            label: 'Peso',
                                            data: current.weight
                                                .toStringAsFixed(1),
                                            icon: FontAwesomeIcons.weightScale,
                                            width: 125,
                                            sufix: 'kg',
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: context.spacing.lg),
                                      CustomTextWidget(
                                        label: 'Rangos',
                                        fontSize: context.fontsSize.title,
                                        textAlign: .left,
                                        fontWeight: .w800,
                                      ),
                                      SizedBox(height: context.spacing.md),

                                      BlocBuilder<
                                        EvalRecentAnthroBloc,
                                        AnthroState
                                      >(
                                        builder: (context, state) {
                                          if (state is AnthroEvaluated &&
                                              !(state.anthroAlerts == null ||
                                                  state.anthroRanges == null)) {
                                            final anthroRanges =
                                                state.anthroRanges;
                                            final anthroAlerts =
                                                state.anthroAlerts;
                                            // final anthroDataList = [current.weight, current.smm, current.]
                                            debugPrint(anthroRanges.toString());
                                            debugPrint(anthroAlerts.toString());

                                            final currentValues = {
                                              'Peso': current.weight,
                                              'Masa Músculo Esquelética':
                                                  current.smm,
                                              'Masa grasa': current.fatMass,
                                              'Porcentaje grasa':
                                                  current.bodyFatPercentage,
                                              'IMC': current.bmi,
                                              'ICC': current.whr,
                                            };

                                            return Column(
                                              crossAxisAlignment: .stretch,
                                              children: [
                                                for (final entry
                                                    in anthroRanges!.entries)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom:
                                                          context.spacing.md,
                                                    ),
                                                    child: ValueRangeIndicator(
                                                      height: 10,
                                                      markerSize: 15,
                                                      fontSize: context
                                                          .fontsSize
                                                          .caption,
                                                      value:
                                                          currentValues[entry
                                                              .key]!, // the num value, e.g. 22.5
                                                      min: anthroRanges[entry.key]!
                                                          .min
                                                          .toDouble(), // matching min from ranges map
                                                      max: anthroRanges[entry.key]!
                                                          .max
                                                          .toDouble(), // matching max from ranges map
                                                      title: entry
                                                          .key, // 'Peso', 'SMM', etc.
                                                    ),
                                                  ),
                                                SizedBox(
                                                  height: context.spacing.sm,
                                                ),

                                                Column(
                                                  children: [
                                                    CustomTextWidget(
                                                      label:
                                                          "Para una evaluación precisa ingresa tu sexo en ",
                                                      fontSize: context
                                                          .fontsSize
                                                          .details,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          context.spacing.xs,
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const ProfileMainPage(),
                                                        ),
                                                      ),
                                                      child: CustomTextWidget(
                                                        label:
                                                            "Datos personales",
                                                        fontSize: context
                                                            .fontsSize
                                                            .details,
                                                        color:
                                                            context.colors.low,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                SizedBox(
                                                  height: context.spacing.lg,
                                                ),
                                                CustomTextWidget(
                                                  label: 'Resumen',
                                                  fontSize:
                                                      context.fontsSize.title,
                                                  textAlign: .left,
                                                  fontWeight: .w800,
                                                ),

                                                SizedBox(
                                                  height: context.spacing.sm,
                                                ),

                                                Row(
                                                  mainAxisAlignment:
                                                      .spaceEvenly,
                                                  crossAxisAlignment: .center,
                                                  mainAxisSize: .max,
                                                  children: [
                                                    CustomTextWidget(
                                                      label: 'Debajo del rango',
                                                      fontSize: context
                                                          .fontsSize
                                                          .caption,
                                                      color: context.colors.low,
                                                      fontWeight: .w800,
                                                      icon:
                                                          Icons.arrow_downward,
                                                      backgroundColor: context
                                                          .colors
                                                          .low
                                                          .withAlpha(25),
                                                      paddingSize:
                                                          context.spacing.sm,
                                                    ),
                                                    // SizedBox(wi: context.spacing.sm,),
                                                    CustomTextWidget(
                                                      label: 'Arriba del rango',
                                                      fontSize: context
                                                          .fontsSize
                                                          .caption,
                                                      color:
                                                          context.colors.danger,
                                                      fontWeight: .w800,
                                                      icon: Icons.arrow_upward,
                                                      backgroundColor: context
                                                          .colors
                                                          .danger
                                                          .withAlpha(25),
                                                      paddingSize:
                                                          context.spacing.sm,
                                                    ),
                                                  ],
                                                ),

                                                SizedBox(
                                                  height: context.spacing.lg,
                                                ),

                                                for (final entry
                                                    in anthroAlerts!.entries)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom:
                                                          context.spacing.sm,
                                                    ),
                                                    child: AnthroValueIndicator(
                                                      field: entry.key,
                                                      value: entry.value,
                                                      range:
                                                          anthroRanges[entry
                                                              .key]!,
                                                    ),
                                                  ),
                                              ],
                                            );
                                          }
                                          return CustomTextWidget(
                                            label: "No hay datos",
                                            fontSize: context.fontsSize.body,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // SizedBox(height: context.spacing.xl),

                                // --- Otros datos
                                // Align(
                                //   alignment: .centerLeft,
                                //   child: CustomTextWidget(
                                //     label: "Estadísticas",
                                //     fontSize: context.fontsSize.title,
                                //   ),
                                // ),
                                // SizedBox(height: context.spacing.sm),

                                // BackgroundContainer(
                                //   child: Column(children: [Text('hola')]),
                                // ),
                                // SizedBox(height: context.spacing.lg),

                                // --- Graficas
                                // Align(
                                //   alignment: .centerLeft,
                                //   child: CustomTextWidget(
                                //     label: "Progreso",
                                //     fontSize: context.fontsSize.title,
                                //   ),
                                // ),
                                // SizedBox(height: context.spacing.sm),

                                // BlocBuilder<GetAnthroAllBloc, AnthroState>(
                                //   builder: (context, state) {
                                //     if (state is AnthroListLoaded) {
                                //       final data = state.data!;
                                //       final buttonColor =
                                //           context.colors.surface;

                                //       return BackgroundContainer(
                                //         child: Column(
                                //           children: [
                                //             CustomListView(
                                //               addContentPadding: true,
                                //               spacing: context.spacing.sm,
                                //               widgets: [
                                //                 SimpleButton(
                                //                   label: "Altura",
                                //                   color: buttonColor,
                                //                   onPressed: () => _selectField(
                                //                     AnthroField.height,
                                //                   ),
                                //                 ),
                                //                 SimpleButton(
                                //                   label: "Peso",
                                //                   color: buttonColor,
                                //                   onPressed: () => _selectField(
                                //                     AnthroField.weight,
                                //                   ),
                                //                 ),
                                //                 SimpleButton(
                                //                   label: "SMM",
                                //                   color: buttonColor,
                                //                   onPressed: () => _selectField(
                                //                     AnthroField.smm,
                                //                   ),
                                //                 ),
                                //                 SimpleButton(
                                //                   label: "M.Grasa",
                                //                   color: buttonColor,
                                //                   onPressed: () => _selectField(
                                //                     AnthroField.fatMass,
                                //                   ),
                                //                 ),
                                //                 SimpleButton(
                                //                   label: "% Grasa",
                                //                   color: buttonColor,
                                //                   onPressed: () => _selectField(
                                //                     AnthroField
                                //                         .bodyFatPercentage,
                                //                   ),
                                //                 ),
                                //                 SimpleButton(
                                //                   label: "IMC",
                                //                   color: buttonColor,
                                //                   onPressed: () => _selectField(
                                //                     AnthroField.bmi,
                                //                   ),
                                //                 ),
                                //                 SimpleButton(
                                //                   label: "ICC",
                                //                   color: buttonColor,
                                //                   onPressed: () => _selectField(
                                //                     AnthroField.whr,
                                //                   ),
                                //                 ),
                                //               ],
                                //             ),

                                //             SizedBox(
                                //               height: context.spacing.lg,
                                //             ),

                                //             CustomDataChart(
                                //               type: ChartType.bar,
                                //               title: titleForSelectedField(
                                //                 _selectedField,
                                //               ),

                                //               times: data
                                //                   .map((s) => s.registeredAt)
                                //                   .toList(),

                                //               values: valuesForSelectedField(
                                //                 data,
                                //                 _selectedField,
                                //               ),
                                //             ),
                                //           ],
                                //         ),
                                //       );
                                //     }
                                //     return SizedBox();
                                //   },
                                // ),

                                // SizedBox(height: context.spacing.lg),

                                // const SizedBox(height: 20),

                                // BlocBuilder<GetAnthroByFieldBloc, AnthroState>(
                                //   builder: (context, state) {
                                //     if (state is AnthroLoading) {
                                //       return const CircularProgressIndicator();
                                //     }

                                //     if (state is AnthroFieldListLoaded) {
                                //       if (state.data == null ||
                                //           state.data!.isEmpty) {
                                //         return const SizedBox(
                                //           child: Text("No data"),
                                //         );
                                //       }
                                //       return SizedBox(
                                //         height: 200,
                                //         width: 200,
                                //         child: Text(state.data.toString()),
                                //       );
                                //     }

                                //     return const SizedBox(height: 40);
                                //   },
                                // ),

                                // const SizedBox(height: 30),
                                // ElevatedButton(
                                //   onPressed: () => Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) =>
                                //           AllAnthroRecordsPage(),
                                //     ),
                                //   ),
                                //   child: Text("Todos los records"),
                                // ),
                              ],
                            ),
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

enum AnthroField { height, weight, smm, fatMass, bodyFatPercentage, bmi, whr }

// Devuelve los valores correspondientes al campo seleccionado.
List<num> valuesForSelectedField(
  List<Anthropometrics> data,
  AnthroField field,
) {
  switch (field) {
    case AnthroField.height:
      return data.map((s) => s.height).toList();
    case AnthroField.weight:
      return data.map((s) => s.weight).toList();
    case AnthroField.smm:
      return data.map((s) => s.smm).toList();
    case AnthroField.fatMass:
      return data.map((s) => s.fatMass).toList();
    case AnthroField.bodyFatPercentage:
      return data.map((s) => s.bodyFatPercentage).toList();
    case AnthroField.bmi:
      return data.map((s) => s.bmi).toList();
    case AnthroField.whr:
      return data.map((s) => s.whr).toList();
  }
}

// Título opcional para mostrar arriba de la gráfica.
String titleForSelectedField(AnthroField field) {
  switch (field) {
    case AnthroField.height:
      return 'Altura';
    case AnthroField.weight:
      return 'Peso';
    case AnthroField.smm:
      return 'SMM';
    case AnthroField.fatMass:
      return 'Masa de Grasa';
    case AnthroField.bodyFatPercentage:
      return '% de Grasa';
    case AnthroField.bmi:
      return 'IMC';
    case AnthroField.whr:
      return 'ICC';
  }
}
