import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/member_repo.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/change_password.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/check_credentials_eval_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/login_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/register_member_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/send_otp.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/verify_otp_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/network/otp_controller.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/main_wrapper.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/input_validators.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/launch_url.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/input_fields.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/snackbar.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/stepper.dart';
import 'package:salud_ulv_app/src/features/services/check_connection.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/network/auth_controller.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/login_page.dart';
// import 'package:salud_ulv_app/src/features/presentation/screens/auth/registry_info_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/containers.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class ChangePwPage extends StatelessWidget {
  const ChangePwPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ChangePasswordBloc(
            changePWUseCase: ChangePwUseCase(
              AuthHTTPController(),
              TokenStorage(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => SendOTPBloc(
            sendOTPUseCase: SendOtpUsecase(
              CheckConnection(),
              const OtpServices(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => CheckOTPBloc(
            verifyOTPUseCase: VerifyOtpUsecase(
              CheckConnection(),
              const OtpServices(),
              TokenStorage(),
            ),
          ),
        ),
      ],

      child: const _ChangePwPage(),
    );
  }
}

class _ChangePwPage extends StatefulWidget {
  // final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  const _ChangePwPage();

  @override
  State<_ChangePwPage> createState() => _ChangePwPageState();
}

class _ChangePwPageState extends State<_ChangePwPage> {
  // Need of controller for a custom texform entry
  // final _formKey = GlobalKey<FormState>();
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());

  // final isLoading = false;

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  // final _confirmPwdController = TextEditingController();

  final _otpController = TextEditingController();

  //   DateTime? _dateOfBirth;
  // String? _dobError;
  // int _typeID = 1;
  int _currentStep = 0;
  bool _finalSubmissionInProgress = false;
  bool _setupEmailCompleted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    // _confirmPwdController.dispose();

    _otpController.dispose();

    super.dispose();
  }

  bool get isLoading {
    switch (_currentStep) {
      case 0:
        return context.watch<SendOTPBloc>().state is AuthLoading;

      case 1:
        return context.watch<CheckOTPBloc>().state is AuthLoading;

      case 2:
        return _finalSubmissionInProgress;

      default:
        return false;
    }
  }

  void _onStepContinue() {
    final isValid = _formKeys[_currentStep].currentState!.validate();
    if (!isValid) return;

    if (_currentStep == 0) {
      context.read<SendOTPBloc>().add(
        SendOTPEvent(_emailController.text.trim()),
      );
    } else if (_currentStep == 1) {
      context.read<CheckOTPBloc>().add(
        CheckOPTEvent(_otpController.text.trim(), _emailController.text.trim()),
      );
    } else {
      _onFinalSubmit();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _onFinalSubmit() {
    if (_finalSubmissionInProgress) return;

    setState(() => _finalSubmissionInProgress = true);

    if (_setupEmailCompleted) {
      context.read<ChangePasswordBloc>().add(
        ChangePasswordEvent(
          email: _emailController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: [
        context.colors.tertiary,
        context.colors.secondary,
        // context.colors.primary,
      ],
      stops: [0, 0.5],

      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: true,
          bottom: true,

          child: MultiBlocListener(
            listeners: [
              BlocListener<ChangePasswordBloc, AuthState>(
                listener: (context, state) {
                  if (state is PasswordChanged) {
                    CustomSnackBar.showSuccess(
                      context,
                      "Contraseña cambiada exitosamente",
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInPage(),
                      ),
                    );
                  }

                  if (state is AuthError) {
                    setState(() => _finalSubmissionInProgress = false);
                    CustomSnackBar.showError(context, state.message);
                  }
                },
              ),

              BlocListener<SendOTPBloc, AuthState>(
                listener: (context, state) {
                  if (state is OtpSent) {
                    CustomSnackBar.showSuccess(
                      context,
                      "Código de verificación enviado",
                    );

                    if (_currentStep == 0) {
                      setState(() => _currentStep = 1);
                    }
                  }

                  if (state is AuthError) {
                    CustomSnackBar.showError(context, state.message);
                  }
                },
              ),

              BlocListener<CheckOTPBloc, AuthState>(
                listener: (context, state) {
                  if (state is ContinueAuth) {
                    if (state.isCorrect) {
                      setState(() {
                        _currentStep++;
                        _setupEmailCompleted = true;
                      });
                    } else {
                      CustomSnackBar.showError(
                        context,
                        "Corrobore su código o genere uno nuevo",
                      );
                    }
                  }

                  if (state is AuthError) {
                    CustomSnackBar.showError(context, state.message);
                  }
                },
              ),
            ],

            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(context.spacing.sm),
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,

                  children: [
                    SizedBox(height: context.spacing.xxl),

                    CustomTextWidget(
                      label: "Cambio de contraseña",
                      color: context.colors.textSecondary,
                      fontSize: context.fontsSize.display,
                      fontWeight: FontWeight.w700,
                    ),

                    SizedBox(height: context.spacing.sm),

                    CustomTextWidget(
                      label:
                          "Si has olvidado tu contraseña, no te preocupes, puedes cambiarla y entrar nuevamente a la app",
                      color: context.colors.textSecondary,
                      fontSize: context.fontsSize.body,
                      // fontWeight: FontWeight.w700,
                    ),

                    SizedBox(height: context.spacing.md),

                    BackgroundContainer(
                      // pHeight: 600,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomStepper(
                            currentStep: _currentStep,
                            stepTitles: [
                              'Verificación de correo',
                              'Código de verificación',
                              'Nuevas credenciales',
                            ],

                            isLoading: isLoading,

                            onContinue: _onStepContinue,
                            onCancel: isLoading ? null : _onStepCancel,

                            stepContent: switch (_currentStep)
                            // ─────────────────────────────
                            // STEP 0 - CREDENCIALES
                            // ─────────────────────────────
                            {
                              0 => Form(
                                key: _formKeys[0],
                                child: BlocBuilder<ChangePasswordBloc, AuthState>(
                                  builder: (context, _) {
                                    return Column(
                                      children: [
                                        CustomTextWidget(
                                          label:
                                              "Ingrese el correo electrónico que utilizó para crear su cuenta",
                                          fontSize: context.fontsSize.caption,
                                        ),
                                        SizedBox(height: context.spacing.md),

                                        CustomTextFormField(
                                          label: "Correo electrónico",
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          prefixIcon: FontAwesomeIcons.envelope,
                                          validator: (v) => inputValidator(
                                            v,
                                            "Ingresa un correo electrónico",
                                          ),
                                        ),
                                        
                                        // SizedBox(height: context.spacing.md,),

                                        // SimpleButton(label: "Enviar", onPressed: () => context.read<SendOTPBloc>().add(SendOTPEvent(_emailController.text.trim())))
                                      ],
                                    );
                                  },
                                ),
                              ),

                              // ─────────────────────────────
                              // STEP 1 - VERIFICAR CORREO
                              // ─────────────────────────────
                              1 => Form(
                                key: _formKeys[1],
                                child: BlocBuilder<CheckOTPBloc, AuthState>(
                                  builder: (context, _) {
                                    return Column(
                                      // mainAxisAlignment: .start,
                                      // crossAxisAlignment: .start,
                                      mainAxisSize: .min,

                                      children: [
                                        CustomTextWidget(
                                          label:
                                              "Hemos enviado un código de verificación al correo ${_emailController.text}.",
                                          fontSize: context.fontsSize.caption,
                                          textAlign: .left,
                                        ),

                                        SizedBox(height: context.spacing.md),

                                        CustomTextWidget(
                                          label:
                                              "Si no encuentra el código, revise en la sección de Spam",
                                          fontSize: context.fontsSize.caption,
                                          textAlign: .left,
                                        ),

                                        SizedBox(height: context.spacing.lg),

                                        // CustomTextFormField(
                                        //   label: 'Código',
                                        //   controller: _otpController,
                                        //   prefixIcon: FontAwesomeIcons.key,
                                        //   keyboardType: TextInputType.number,
                                        //   validator: (v) => inputValidator(
                                        //     v,
                                        //     'Ingresa el código enviado',
                                        //   ),
                                        //   // errorText: otpError,
                                        // ),
                                        OtpInput(
                                          length: 4,
                                          controller: _otpController,
                                        ),

                                        SizedBox(height: context.spacing.md),

                                        GestureDetector(
                                          onTap: () {
                                            context.read<SendOTPBloc>().add(
                                              SendOTPEvent(
                                                _emailController.text.trim(),
                                              ),
                                            );
                                          },
                                          child: CustomTextWidget(
                                            label: "Reenviar código",
                                            fontSize: context.fontsSize.caption,
                                            color: context.colors.secondary,
                                            textAlign: .right,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              // ─────────────────────────────
                              // STEP 2 - INFORMACIÓN PERSONAL
                              // ─────────────────────────────
                              2 => Form(
                                key: _formKeys[2],
                                child: BlocBuilder<ChangePasswordBloc, AuthState>(
                                  builder: (context, _) {
                                    return Column(
                                      children: [
                                        CustomTextWidget(label: "Ingrese su nueva contraseña", fontSize: context.fontsSize.caption),
                                        SizedBox(height: context.spacing.md,),

                                        CustomPasswordField(
                                          label: "Contraseña",
                                          controller: _newPasswordController,
                                          validator: (v) => inputValidator(
                                            v,
                                            "Ingresa una contraseña",
                                          ),
                                        ),

                                        // SizedBox(height: context.spacing.md),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              _ => const SizedBox.shrink(),
                            },
                          ),

                          SizedBox(height: context.spacing.lg),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     CustomTextWidget(
                          //       label: "¿Ya tienes una cuenta?",
                          //       fontSize: context.fontsSize.caption,
                          //     ),

                          //     SizedBox(width: context.spacing.xs),

                          //     GestureDetector(
                          //       onTap: () => Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (context) => SignInPage(),
                          //         ),
                          //       ),
                          //       child: CustomTextWidget(
                          //         label: "Inicia sesión",
                          //         fontSize: context.fontsSize.caption,
                          //         color: context.colors.success,
                          //       ),
                          //     ),
                          //   ],
                          // ),

                          // SizedBox(height: context.spacing.md),

                          // Column(
                          //   mainAxisAlignment: .center,
                          //   children: [
                          //     CustomTextWidget(
                          //       label:
                          //           "Al crear una cuenta, esta aceptando nuestra ",
                          //       fontSize: context.fontsSize.details,
                          //     ),
                          //     SizedBox(width: context.spacing.xs),

                          //     GestureDetector(
                          //       onTap: () => launchUrls(
                          //         'https://ajrn-8bit.github.io/privacy_policies/salud-ulv/index.html',
                          //       ),

                          //       child: CustomTextWidget(
                          //         label: "Politica de Privacidad.",
                          //         fontSize: context.fontsSize.details,
                          //         color: context.colors.textPrimary,
                          //         fontWeight: .w700,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),

                    // SizedBox(height: context.spacing.xl),
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

// class MinimalStepper extends StatefulWidget {
//   const MinimalStepper({
//     super.key,
//     required this.steps,
//     required this.onFinish,
//   });

//   final List<StepData> steps;
//   final VoidCallback onFinish;

//   @override
//   State<MinimalStepper> createState() => _MinimalStepperState();
// }

// class StepData {
//   StepData({required this.formKey, required this.content});
//   final GlobalKey<FormState> formKey;
//   final Widget content;
// }

// class _MinimalStepperState extends State<MinimalStepper> {
//   int _currentStep = 0;

//   bool get _isLastStep => _currentStep == widget.steps.length - 1;

//   void _handleNext() {
//     final isValid = widget.steps[_currentStep].formKey.currentState!.validate();
//     if (!isValid) return; // errors already show on the fields

//     if (_isLastStep) {
//       widget.onFinish();
//     } else {
//       setState(() => _currentStep += 1);
//     }
//   }

//   void _handleBack() {
//     if (_currentStep > 0) setState(() => _currentStep -= 1);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final spacing = context.spacing;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         // --- progress bars ---
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
//           child: Row(
//             children: List.generate(widget.steps.length, (i) {
//               final isActive = i <= _currentStep;
//               return Expanded(
//                 child: Container(
//                   height: 3,
//                   margin: EdgeInsets.symmetric(horizontal: spacing.xxs),
//                   decoration: BoxDecoration(
//                     color: isActive ? colors.primary : colors.border,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ),

//         // --- current step content ---
//         Expanded(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: spacing.lg),
//             child: Form(
//               key: widget.steps[_currentStep].formKey,
//               child: widget.steps[_currentStep].content,
//             ),
//           ),
//         ),

//         // --- footer controls ---
//         Padding(
//           padding: EdgeInsets.all(spacing.lg),
//           child: Center(
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (_currentStep > 0) ...[
//                   TextButton(
//                     onPressed: _handleBack,
//                     child: Text(
//                       'Back',
//                       style: TextStyle(color: colors.textSecondary),
//                     ),
//                   ),
//                   SizedBox(width: spacing.md),
//                 ],
//                 AppButton(
//                   label: _isLastStep ? 'Finish' : 'Next',
//                   onPressed: _handleNext,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// BlocBuilder<RegisterBloc, AuthState>(
//           builder: (context, state) {
//             return Padding(
//                 padding: const EdgeInsets.all(15),
//                 child: SingleChildScrollView(
//                   child: Form(
//                     key: _formKey,

//                     child: Column(
//                       mainAxisAlignment: .center,
//                       children: [
//                       const Text('Sign Up', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 32),

//                        TextFormField(
//                         controller: _userCodeController,
//                         decoration: const InputDecoration(labelText: 'User code'),
//                         keyboardType: TextInputType.numberWithOptions(),
//                         validator: (v) => v!.isEmpty ? 'Enter your first name' : null,
//                       ),
//                       const SizedBox(height: 12),

//                       // TextFormField(
//                       //   controller: _firstnameController,
//                       //   decoration: const InputDecoration(labelText: 'First Name'),
//                       //   validator: (v) => v!.isEmpty ? 'Enter your first name' : null,
//                       // ),
//                       // const SizedBox(height: 12),

//                       // TextFormField(
//                       //   controller: _surnameController,
//                       //   decoration: const InputDecoration(labelText: 'Surname'),
//                       //   validator: (v) => v!.isEmpty ? 'Enter your surname' : null,
//                       // ),
//                       // const SizedBox(height: 12),

//                       // TextFormField(
//                       //   controller: _lastnameController,
//                       //   decoration: const InputDecoration(labelText: 'Last Name'),
//                       //   validator: (v) => v!.isEmpty ? 'Enter your last name' : null,
//                       // ),
//                       // const SizedBox(height: 12),

//                       TextFormField(
//                         controller: _emailController,
//                         decoration: const InputDecoration(labelText: 'Email'),
//                         validator: (v) => v!.isEmpty ? 'Enter your email' : null,
//                       ),
//                       const SizedBox(height: 12),

//                       TextFormField(
//                         controller: _passwordController,
//                         decoration: const InputDecoration(labelText: 'Password'),
//                         obscureText: true,
//                         validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
//                         onChanged: (_) {
//                           if (_confirmPwdController.text.isNotEmpty) {
//                             _formKey.currentState?.validate();
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 12),

//                       TextFormField(
//                         controller: _confirmPwdController,
//                         decoration: const InputDecoration(labelText: 'Confirm password'),
//                         obscureText: true,
//                         validator: (v) {
//                           if (v == null || v.isEmpty) return 'Please confirm your password';
//                           if (v != _passwordController.text) return 'Passwords do not match';
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 32),

//                       state is AuthLoading
//                           ? const CircularProgressIndicator()
//                           : ElevatedButton(
//                               onPressed: () => _onSubmit(context),
//                               child: const Text('Create Account'),
//                             ),

//                        Row(
//                           mainAxisAlignment: .center,
//                           children:[
//                             Text("¿Tienes una cuenta?", style: TextStyle(fontFamily: "Lato", fontSize: 12, color: Colors.black)),
//                             const SizedBox(width: 5),

//                             GestureDetector(
//                               onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInPage())),
//                               child: Text("Inicia sesión", style: TextStyle(fontFamily: "Lato", fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyan.shade400))),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//           },
//         ),
