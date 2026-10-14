import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/login_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/member_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/change_pw_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/main_wrapper.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/input_validators.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/launch_url.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/containers.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/input_fields.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';
import 'package:salud_ulv_app/src/features/services/check_connection.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/network/auth_controller.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/sign_up_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        loginUsecase: LoginUsecase(
          AuthHTTPController(),
          TokenHandler(),
          TokenStorage(),
          CheckConnection(),
          UserLocalRepo(),
          MemberLocalRepo(),
        ),
      ),
      child: const _SignInPage(),
    );
  }
}

class _SignInPage extends StatefulWidget {
  // final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  const _SignInPage();

  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  // Need of controller for a custom texform entry
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
        LoginEvent(
          input: _inputController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      stops: [0.5, 0.6],
      colors: [
        context.colors.tertiary,
        context.colors.secondary,
        // context.colors.primary,
      ],

      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: true,
          bottom: true,

          child: BlocListener<LoginBloc, AuthState>(
            listener: (context, state) {
              if (state is Authenticated) {
                // switch (state.currentRole) {
                //   case 'Member':
                //     Navigator.of(context).pushReplacementNamed('/home/user');
                //     break;
                //   case 'C':
                //     Navigator.of(context).pushReplacementNamed('/home/coach');
                //     break;
                //   case 'A':
                //     Navigator.of(context).pushReplacementNamed('/home/admin');
                //     break;
                //   default:
                //     Navigator.of(context).pushReplacementNamed('/login');
                // }

                debugPrint('🚀 NAVEGANDO AL MAIN');

                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => MainWrapper()),
                // );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainWrapper()),
                  (route) => false,
                );
              }
              if (state is AuthError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },

            child: BlocBuilder<LoginBloc, AuthState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.all(15),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,

                      child: Column(
                        mainAxisAlignment: .center,
                        crossAxisAlignment: .start,
                        mainAxisSize: .min,
                        children: [
                          SizedBox(height: context.spacing.xxl),

                          CustomTextWidget(
                            label: "¡Hola de Nuevo!",
                            color: context.colors.textSecondary,
                            fontSize: context.fontsSize.display,
                            fontWeight: FontWeight.w700,
                          ),

                          SizedBox(height: context.spacing.sm),

                          CustomTextWidget(
                            label: "Bienvenido de regreso a Salud ULV",
                            color: context.colors.textSecondary,
                            fontSize: context.fontsSize.body,
                            // fontWeight: FontWeight.w700,
                          ),

                          SizedBox(height: context.spacing.xl),

                          BackgroundContainer(
                            // fullWidth: true,
                            pHeight: 500,
                            child: Column(
                              children: [
                                CustomTextWidget(
                                  label: "Inicia sesión",
                                  fontSize: context.fontsSize.title,
                                  fontWeight: .w700,
                                ),
                                SizedBox(height: context.spacing.md),

                                CustomTextFormField(
                                  label: "Matrícula o correo electrónico",
                                  controller: _inputController,
                                  prefixIcon: FontAwesomeIcons.at,
                                  validator: (v) => inputValidator(
                                    v,
                                    "Porfavor ingresa un identificador",
                                  ),
                                ),
                                SizedBox(height: context.spacing.md),

                                CustomPasswordField(
                                  label: "Contraseña",
                                  controller: _passwordController,
                                  validator: (v) => inputValidator(
                                    v,
                                    "Porfavor ingresa tu contraseña",
                                  ),
                                ),
                                SizedBox(height: context.spacing.xxl),

                                state is AuthLoading
                                    ? const CircularProgressIndicator()
                                    : SimpleButton(
                                        label: "Entrar",
                                        fullWidth: true,
                                        textColor: context.colors.onTertiary,
                                        color: context.colors.tertiary,
                                        onPressed: () => _onSubmit(context),
                                      ),

                                SizedBox(height: context.spacing.lg),

                                Row(
                                  mainAxisAlignment: .center,
                                  children: [
                                    CustomTextWidget(
                                      label: "¿Has olvidado tu contraseña?",
                                      fontSize: context.fontsSize.caption,
                                    ),
                                    SizedBox(width: context.spacing.xs),

                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ChangePwPage(),
                                        ),
                                      ),
                                      child: CustomTextWidget(
                                        label: "Restablecela",
                                        fontSize: context.fontsSize.caption,
                                        color: context.colors.success,
                                      ),
                                    ),
                                  ],
                                ),


                                SizedBox(height: context.spacing.sm),
                                Row(
                                  mainAxisAlignment: .center,
                                  children: [
                                    CustomTextWidget(
                                      label: "¿No tienes una cuenta?",
                                      fontSize: context.fontsSize.caption,
                                    ),
                                    SizedBox(width: context.spacing.xs),

                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SignUpPage(),
                                        ),
                                      ),
                                      child: CustomTextWidget(
                                        label: "Registrate",
                                        fontSize: context.fontsSize.caption,
                                        color: context.colors.success,
                                      ),
                                    ),
                                  ],
                                ),

                                // SizedBox(height: context.spacing.xl,),
                                SizedBox(height: context.spacing.xxl),
                                SizedBox(height: context.spacing.xxl),

                                Column(
                                  mainAxisAlignment: .center,
                                  children: [
                                    CustomTextWidget(
                                      label:
                                          "Al iniciar sesión con una cuenta, esta aceptando nuestra ",
                                      fontSize: context.fontsSize.details,
                                    ),
                                    SizedBox(width: context.spacing.xs),

                                    GestureDetector(
                                      onTap: () => launchUrls(
                                        'https://ajrn-8bit.github.io/privacy_policies/salud-ulv/index.html',
                                      ),

                                      child: CustomTextWidget(
                                        label: "Politica de Privacidad.",
                                        fontSize: context.fontsSize.details,
                                        color: context.colors.textPrimary,
                                        fontWeight: .w700,
                                      ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
