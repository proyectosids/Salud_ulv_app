import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_ruler_picker/flutter_ruler_picker.dart';
import 'package:salud_ulv_app/src/core/usecase/anthropometrics/save_usecase.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/anthro_dto.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/anthro_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/anthro_bloc/anthro_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/main_wrapper.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/containers.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/ruler_picker.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/snackbar.dart';

class RegisterAnthroPage extends StatelessWidget {
  const RegisterAnthroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SaveAnthroBloc(
        saveAnthroUsecase: SaveAnthroUsecase(
          AnthroLocalStorage(),
          CurrentUserSession(),
        ),
      ),

      child: const _RegisterAnthroPage(),
    );
  }
}

class _RegisterAnthroPage extends StatefulWidget {
  const _RegisterAnthroPage();

  @override
  State<_RegisterAnthroPage> createState() => _RegisterAnthroPageState();
}

class _RegisterAnthroPageState extends State<_RegisterAnthroPage> {
  // late final RulerPickerController _heightController;

  final _formKey = GlobalKey<FormState>();
  final _heightController = RulerPickerController(
    min: 150,
    max: 200,
    initialValue: 170,
  );
  final _weightController = RulerPickerController(
    min: 40,
    max: 150,
    initialValue: 70,
  );
  final _smmController = RulerPickerController(
    min: 20,
    max: 50,
    initialValue: 25,
  );
  final _fatMassController = RulerPickerController(
    min: 0,
    max: 15,
    initialValue: 7,
  );
  final _bodyFatPercentController = RulerPickerController(
    min: 5,
    max: 40,
    initialValue: 22,
  );
  final _bmiController = RulerPickerController(
    min: 15,
    max: 40,
    initialValue: 22,
  );
  final _whrController = RulerPickerController(
    min: 0.5,
    max: 1.5,
    initialValue: 1,
  );

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _smmController.dispose();
    _fatMassController.dispose();
    _bodyFatPercentController.dispose();
    _bmiController.dispose();
    _whrController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<SaveAnthroBloc>().add(
        SaveAnthroEvent(
          AnthropometricsDTO(
            height: _heightController.value.toDouble(),
            weight: _weightController.value.toDouble(),
            smm: _smmController.value.toDouble(),
            fatMass: _fatMassController.value.toDouble(),
            bodyFatPercentage: _bodyFatPercentController.value.toDouble(),
            bmi: _bmiController.value.toDouble(),
            whr: _whrController.value.toDouble(),
          ).toDomain(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      // colors: [context.colors.background, context.colors.background, context.colors.tertiary],
      // stops: [0, 0.35, 1],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.colors.background,
          elevation: 0,
        ),

        backgroundColor: Colors.transparent,
        body: SafeArea(
          // top: true,
          bottom: true,

          child: BlocListener<SaveAnthroBloc, AnthroState>(
            listener: (context, state) {
              if (state is AnthroSaved) {
                CustomSnackBar.showSuccess(context, 'Registro guardado');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainWrapper()),
                );
              }
              if (state is AnthroError) {
                CustomSnackBar.showError(context, state.message);
              }
            },

            child: BlocBuilder<SaveAnthroBloc, AnthroState>(
              builder: (context, state) {
                return Padding(
                  padding: EdgeInsets.all(context.spacing.md),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,

                      child: Column(
                        mainAxisAlignment: .center,
                        children: [
                          CustomTextWidget(
                            label: "Registro de datos antropométricos",
                            fontSize: context.fontsSize.display,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(height: context.spacing.md),
                          CustomTextWidget(
                            label:
                                'Ingresa tu datos corporales compartidos por Salud ULV o Nutrición ULV',
                            fontSize: context.fontsSize.caption,
                          ),
                          SizedBox(height: context.spacing.sm),
                          CustomTextWidget(
                            label:
                                'Si no conoces tus datos, acercate a estos departamentos para tu medición corporal',
                            fontSize: context.fontsSize.caption,
                          ),

                          SizedBox(height: context.spacing.xl),

                          BackgroundContainer(
                            // color: context.colors.secondary,
                            child: Column(
                              children: [
                                // CustomTextFormField(
                                //   label: 'Altura (cm)',
                                //   hintText: 'Ej: 175',
                                //   keyboardType: TextInputType.number,
                                //   controller: _heightController,
                                //   validator: (v) =>
                                //       numberValidator(v, 'Ingresa tu altura'),
                                // ),
                                // SizedBox(height: context.spacing.md),

                                // NumericRulerPicker(
                                //   controller: _heightController,
                                //   suffix: ' kg',
                                //   onValueChanged: (value) {
                                //     // setState(() => _heightController.value = value.toDouble());
                                //   },
                                //   ranges: const [
                                //     RulerRange(begin: 60, end: 80, scale: 1),
                                //   ],
                                // ),
                                NumericRulerPicker(
                                  controller: _heightController,
                                  suffix: ' cm',
                                  title: 'Altura',
                                ),
                                SizedBox(height: context.spacing.lg),

                                NumericRulerPicker(
                                  controller: _weightController,
                                  suffix: ' kg',
                                  title: 'Peso',
                                  step: 0.1,
                                ),
                                SizedBox(height: context.spacing.lg),

                                NumericRulerPicker(
                                  controller: _smmController,
                                  suffix: ' kg',
                                  title: 'Masa Músculo Esquelética',
                                  step: 0.1,
                                ),
                                SizedBox(height: context.spacing.lg),

                                NumericRulerPicker(
                                  controller: _fatMassController,
                                  suffix: ' kg',
                                  title: 'Masa de grasa',
                                  step: 0.1,
                                ),
                                SizedBox(height: context.spacing.lg),

                                NumericRulerPicker(
                                  controller: _bodyFatPercentController,
                                  suffix: ' %',
                                  title: 'Porcentaje de grasa',
                                  step: 0.1,
                                ),
                                SizedBox(height: context.spacing.lg),

                                NumericRulerPicker(
                                  controller: _bmiController,
                                  suffix: ' kg/m2',
                                  title: 'Indice de Masa Corporal',
                                  step: 0.1,
                                ),
                                SizedBox(height: context.spacing.lg),

                                NumericRulerPicker(
                                  controller: _whrController,
                                  suffix: ' ',
                                  title: 'Indice Cintura Cadera',
                                  step: 0.1,
                                ),
                                SizedBox(height: context.spacing.lg),
                              ],
                            ),
                          ),

                          SizedBox(height: context.spacing.lg),
                          SimpleButton(
                            label: 'Guardar',
                            fullWidth: true,
                            fontSize: context.fontsSize.body,
                            textColor: context.colors.onSecondary,
                            color: context.colors.secondary,
                            onPressed: () => _onSubmit(context),
                          ),
                          SizedBox(height: context.spacing.md),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
