import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/cycling_repo.dart';
// import 'package:path/path.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/get_all_exercise.dart';
// import 'package:salud_ulv_app/src/core/usecase/exercises/get_recent_exercise.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/get_recent_samples.dart';
// import 'package:salud_ulv_app/src/core/data/DTOs/walk_dto.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
// import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_repo.dart';
// import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_samples_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_bloc/exercise_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/main_wrapper.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/exercise/cycling/cycling_full_list_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/data_tiles.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/exercise_list_widgets.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/expandable_sheet.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/graphs.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/listviews.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/map.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/progress_meter.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/tabs_menu.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class CyclingRecordsPage extends StatelessWidget {
  const CyclingRecordsPage({super.key, this.initialActivityId});

  final String? initialActivityId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ExerciseGetAllBLoc(
            allExerciseUseCase: GetAllExerciseUseCase(
              CyclingRepo(),
              CurrentUserSession(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => ExerciseGetSamplesBLoc(
            getRecentSamplesUseCase: GetSamplesUseCase(CyclingSamplesRepo()),
          ),
        ),
      ],

      child: _WalkRecordsPage(initialActivityId: initialActivityId),
    );
  }
}

class _WalkRecordsPage extends StatefulWidget {
  const _WalkRecordsPage({this.initialActivityId});

  final String? initialActivityId;

  @override
  State<_WalkRecordsPage> createState() => _WalkRecordsPageState();
}

class _WalkRecordsPageState extends State<_WalkRecordsPage> {
  final _formKey = GlobalKey<FormState>();

  final MapController _mapController = MapController();

  // late List<Walk> records;
  // late List<LatLng> latPoints;
  List<Cycling> records = [];
  List<LatLng> points = [];
  int? _index;
  bool _satellite = false;

  // late bool lenghtAvaliable = 0 > records.length - 1;

  // late int _index = lenghtAvaliable ? 0 : records.length + 1;
  // late int _index = records.length -1;
  // bool _indexInitialized = false;
  bool get _hasPrevious => (_index ?? 0) > 0;
  bool get _hasNext => _index != null && _index! < records.length - 1;

  void _onWalksLoaded(List<Cycling> list) {
    records = list;
    if (_index != null) return;
    final requestedIndex = widget.initialActivityId == null
        ? -1
        : list.indexWhere(
            (record) => record.activityID == widget.initialActivityId,
          );
    _index = requestedIndex >= 0 ? requestedIndex : list.length - 1;
  }

  void _goPrevious() {
    if (!_hasPrevious) return;
    setState(() => _index = _index! - 1);
    _requestSamplesForCurrent(records[_index!].activityID!);
  }

  void _goNext() {
    if (!_hasNext) return;
    setState(() => _index = _index! + 1);
    _requestSamplesForCurrent(records[_index!].activityID!);
  }

  void _requestSamplesForCurrent(String activityID) {
    debugPrint('in sample event: activityID');
    context.read<ExerciseGetSamplesBLoc>().add(
      ExerciseGetSamplesEvent(activityID),
    );
  }

  void _onMapReady() {
    if (points.isEmpty) return;
    _mapController.move(points.first, 20);
  }

  @override
  void initState() {
    super.initState();
    context.read<ExerciseGetAllBLoc>().add((ExerciseGetAllEvent()));
    // context.read<ExerciseGetSamplesBLoc>().add(
    //   (ExerciseSamplesEvent(_activityID)),
    // );
    // context.read<AnthroGetAllBloc>().add(AnthroGetAllEvent());
    // context.read<AnthroByFieldBloc>().add(AnthroGetByFieldEvent('weight'));
  }

  @override
  Widget build(BuildContext context) {
    // final startPoint = walk.routePoints.isNotEmpty
    //     ? walk.routePoints.first
    //     : null;
    // final endPoint = walk.routePoints.isNotEmpty ? walk.routePoints.last : null;

    return Scaffold(
      backgroundColor: context.colors.background,

      appBar: AppBar(
        backgroundColor: context.colors.background,
        // toolbarHeight: 80,
        elevation: 0,

        actions: [
          CustomIconButton(
            icon: Icons.library_books,
            iconSize: context.iconSize.lg,
            label: "Historial",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllCyclingRecordsPage()),
            ),
          ),
        ],

        title: Text(
          'Running',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        top: true,
        bottom: true,

        child: MultiBlocListener(
          listeners: [
            BlocListener<ExerciseGetAllBLoc, ExerciseState>(
              listener: (context, state) {
                if (state is ExerciseListLoaded &&
                    (state.data?.isNotEmpty ?? false)) {
                  _onWalksLoaded(state.data!.cast<Cycling>());
                  _requestSamplesForCurrent(records[_index!].activityID!);
                }

                if (state is ExerciseError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            ),

            BlocListener<ExerciseGetSamplesBLoc, ExerciseState>(
              listener: (context, state) {
                if (state is ExerciseError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            ),

            // BlocListener<AnthroGetAllBloc, AnthroState>(
            //   listener: (context, state) {

            //     if(state is AnthroError){
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text(state.message)));
            //     }
            //   }
            // ),

            // BlocListener<AnthroByFieldBloc, AnthroState>(
            //   listener: (context, state) {
            //     if(state is AnthroError){
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text(state.message)));
            //     }
            //   }
            // ),
          ],

          child: SingleChildScrollView(
            key: _formKey,
            scrollDirection: .vertical,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(context.spacing.xxs),
                child: BlocBuilder<ExerciseGetAllBLoc, ExerciseState>(
                  builder: (context, state) {
                    debugPrint(state.toString());
                    if (state is ExerciseLoading) {
                      return const CircularProgressIndicator();
                    }

                    if (state is ExerciseListLoaded &&
                        state.data!.isEmpty != true &&
                        state.data != null) {
                      debugPrint(state.data.toString());
                      records = state.data!.cast<Cycling>();
                      debugPrint(_index.toString());
                      // _activityID = records[_index].activityID;
                      // debugPrint('when loading list: $_activityID');

                      _onWalksLoaded(state.data!.cast<Cycling>());
                      final run = records[_index!];

                      // if (records.isNotEmpty) {
                      //   debugPrint('dentro de condicional');
                      //   // _index = records.length - 1;
                      //   // _indexInitialized = true;
                      //   _requestSamplesForCurrent(_activityID!);
                      // }

                      // final walk = records[_index];

                      return BlocBuilder<ExerciseGetSamplesBLoc, ExerciseState>(
                        builder: (context, state) {
                          if (state is ExerciseSamplesLoaded &&
                              !(state.data == null || state.data!.isEmpty)) {
                            final data = state.data!
                                .whereType<CyclingActivitySample>()
                                .toList();

                            // debugPrint(data.first.activityID.toString());

                            final coordinates = data.map(
                              (s) => Coordinates(
                                latitude: s.latitude ?? 0,
                                longitude: s.longitude ?? 0,
                              ),
                            );

                            points = coordinates
                                .map((c) => LatLng(c.latitude, c.longitude))
                                .toList();

                            return Column(
                              children: [
                                RecordListPaginator(
                                  title: formatDateWithWord(run.registeredAt!),
                                  subtitle:
                                      'Registro ${_index! + 1} de ${records.length}',
                                  hasPrevious: _hasPrevious,
                                  hasNext: _hasNext,
                                  onPrevious: _goPrevious,
                                  onNext: _goNext,
                                ),

                                SizedBox(height: context.spacing.md),

                                SizedBox(
                                  height: 565,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: MapWidget(
                                          startPoint: points.first,
                                          endPoint: points.last,
                                          routePoints: points,
                                          mapController: _mapController,
                                          mapReady: _onMapReady,
                                          interactive: true,
                                          satellite: _satellite,
                                          showCurrentLocation: false,
                                        ),
                                      ),

                                      Positioned(
                                        right: 3,
                                        top: 3,
                                        child: SimpleButton(
                                          icon: Icons.layers,
                                          onPressed: () => setState(() {
                                            setState(() {
                                              _satellite = !_satellite;
                                            });
                                          }),
                                        ),
                                      ),

                                      ExpandableSheet(
                                        maxSize: 1,
                                        minSize: 0.18,
                                        initialSize: 0.18,
                                        padding: context.spacing.xxs,
                                        child: Column(
                                          children: [
                                            TabbedContainer(
                                              pages: [
                                                TabPage(
                                                  title: 'Resumen',
                                                  child: Column(
                                                    children: [
                                                      CircularProgressMeter(
                                                        amount: run.distance!,
                                                        goalAmount: 10000,
                                                        label: 'Distancia',
                                                      ),

                                                      CustomListView(
                                                        scrollable: true,
                                                        runSpacing:
                                                            context.spacing.xxs,
                                                        spacing:
                                                            context.spacing.md,
                                                        // addContentPadding: true,
                                                        orientation: .vertical,
                                                        lines: 2,
                                                        widgets: [
                                                          GridDataTileTrasparent(
                                                            icon:
                                                                FontAwesomeIcons
                                                                    .stopwatch,
                                                            label: 'Duración',
                                                            data:
                                                                formatDuration(
                                                                  run.duration!,
                                                                ),
                                                            // sufix: 'm'
                                                          ),
                                                          GridDataTileTrasparent(
                                                            icon:
                                                                FontAwesomeIcons
                                                                    .ruler,
                                                            label: 'Distancia',
                                                            data: run.distance!
                                                                .toStringAsFixed(
                                                                  1,
                                                                ),
                                                            sufix: 'm',
                                                          ),
                                                          GridDataTileTrasparent(
                                                            icon:
                                                                FontAwesomeIcons
                                                                    .fire,
                                                            label: 'Calorías',
                                                            data: run
                                                                .caloriesBurned!
                                                                .toStringAsFixed(
                                                                  1,
                                                                ),
                                                            sufix: 'cal',
                                                          ),
                                                          GridDataTileTrasparent(
                                                            icon:
                                                                FontAwesomeIcons
                                                                    .mountain,
                                                            label:
                                                                'Elevación ganada',
                                                            data: run
                                                                .elevationGain!
                                                                .toStringAsFixed(
                                                                  1,
                                                                ),
                                                            sufix: 'm',
                                                          ),
                                                          GridDataTileTrasparent(
                                                            icon: FontAwesomeIcons
                                                                .personBiking,
                                                            label:
                                                                'Velocidad maxima',
                                                            data:
                                                                '${run.avgSpeed!.toStringAsFixed(1)} m/s',
                                                            // sufix: '',
                                                          ),
                                                          GridDataTileTrasparent(
                                                            icon:
                                                                FontAwesomeIcons
                                                                    .timeline,
                                                            label: 'Ritmo',
                                                            data: run.avgPace!
                                                                .toStringAsFixed(
                                                                  1,
                                                                ),
                                                            sufix: 'min/km',
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                TabPage(
                                                  title: 'Estadísticas',
                                                  child: Column(
                                                    children: [
                                                      CustomDataChart(
                                                        grid: true,
                                                        valueData: run.speed!
                                                            .toStringAsFixed(0),
                                                        title: 'Velocidad',
                                                        type: .line,
                                                        values: data
                                                            .map(
                                                              (s) =>
                                                                  s.steps ?? 0,
                                                            )
                                                            .toList(),
                                                        times: data
                                                            .map(
                                                              (s) =>
                                                                  s.timestampMs ??
                                                                  Duration.zero,
                                                            )
                                                            .toList(),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            context.spacing.lg,
                                                      ),

                                                      CustomDataChart(
                                                        grid: true,
                                                        valueData:
                                                            '${run.distance!.toStringAsFixed(0)} m',
                                                        title: 'Distancia',
                                                        // type: .line,
                                                        values: data
                                                            .map(
                                                              (s) =>
                                                                  s.distance ??
                                                                  0,
                                                            )
                                                            .toList(),
                                                        times: data
                                                            .map(
                                                              (s) =>
                                                                  s.timestampMs ??
                                                                  Duration.zero,
                                                            )
                                                            .toList(),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            context.spacing.lg,
                                                      ),

                                                      CustomDataChart(
                                                        grid: true,
                                                        valueData:
                                                            '${run.elevationGain!.toStringAsFixed(1)} m',
                                                        title: 'Elevación',
                                                        // type: .line,
                                                        values: data
                                                            .map(
                                                              (s) =>
                                                                  s.elevation ??
                                                                  0,
                                                            )
                                                            .toList(),
                                                        times: data
                                                            .map(
                                                              (s) =>
                                                                  s.timestampMs ??
                                                                  Duration.zero,
                                                            )
                                                            .toList(),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            context.spacing.lg,
                                                      ),

                                                      CustomDataChart(
                                                        grid: true,
                                                        // inverted: true,
                                                        valueData:
                                                            '${run.avgPace!.toStringAsFixed(1)} min/km',
                                                        title: 'Ritmo',
                                                        // type: .bar,
                                                        values: data
                                                            .map(
                                                              (s) =>
                                                                  s.pace ?? 0,
                                                            )
                                                            .toList(),
                                                        times: data
                                                            .map(
                                                              (s) =>
                                                                  s.timestampMs ??
                                                                  Duration.zero,
                                                            )
                                                            .toList(),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            context.spacing.lg,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // TabPage(
                                                //   title: 'Algo mas',
                                                //   child: Text('hi'),
                                                // ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            // return Text('hi inside');
                          }
                          return CircularProgressIndicator();
                        },
                      );
                    }
                    return Column(
                      children: [
                        // SizedBox(height: context.spacing.md),
                        SizedBox(height: context.spacing.xxl),

                        CustomTextWidget(
                          label:
                              "Al parecer aún no has registrado una sesión de ciclismo",
                          fontWeight: FontWeight.w700,
                          fontSize: context.fontsSize.title,
                        ),
                        SizedBox(height: context.spacing.md),
                        CustomTextWidget(
                          label:
                              "Registra sesiones de ciclismo para visualizar la ruta recorrida, datos y estadísticas",
                          fontSize: context.fontsSize.body,
                        ),
                        SizedBox(height: context.spacing.lg),

                        SimpleButton(
                          label: "Comenzar sesión",
                          fontSize: context.fontsSize.body,
                          color: context.colors.secondary,
                          textColor: context.colors.onSecondary,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainWrapper(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),

      // floatingActionButtonLocation: .endTop,
      // floatingActionButton: FloatingActionButton(
      //       onPressed: () => Navigator.push(
      //                               context,
      //                               MaterialPageRoute(
      //                                 builder: (context) => AllWalkRecordsPage(),
      //                               ),
      //                             ),
      //       // mini: true,
      //       backgroundColor: context.colors.surface,
      //       child: Icon(Icons.library_books, color: context.colors.textPrimary),
      //     ),
    );
  }
}
