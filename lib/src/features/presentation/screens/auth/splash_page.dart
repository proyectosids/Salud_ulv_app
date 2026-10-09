import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/check_auth_usecase.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/login_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/sign_up_page.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/video_widget.dart';
import 'package:video_player/video_player.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CheckAuthBloc(
            checkAuthUseCase: CheckAuthUsecase(
              TokenStorage(),
              TokenHandler(),
              CurrentUserSession(),
              UserLocalRepo(),
            ),
          ),
        ),

        // BlocProvider(
        //   create: (context) => )
      ],

      child: const _SplashPage(),
    );
  }
}

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    context.read<CheckAuthBloc>().add(CheckAuthEvent());

    _controller = VideoPlayerController.asset('assets/videos/splash_video1.mp4')
      ..initialize().then((_) {
        setState(() {}); // refresca cuando el video ya está listo
      });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: VideoBackgroundContainer(
        videoAsset: 'assets/videos/splash_video1.mp4',
        overlayOpacity: 0.65,
        colors: [
          Colors.black.withAlpha(100),
          Colors.black.withAlpha(200),
          Colors.black,
        ],
        stops: [0.4, 0.5, 0.7],

        child: SafeArea(
          top: true,
          bottom: true,

          child: BlocListener<CheckAuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Authenticated) {
                Navigator.of(context).pushReplacementNamed('/mainWrapper');
              }

              if (state is AuthError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },

            child: Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: Center(
                child: Column(
                  // mainAxisAlignment: .center,
                  crossAxisAlignment: .center,

                  children: [
                    Spacer(),

                    Align(
                      alignment: .bottomLeft,
                      child: Column(
                        crossAxisAlignment: .stretch,

                        children: [
                          Row(
                            mainAxisSize: .min,
                            children: [
                              GradientText(
                                text: "Salud ULV",
                                colors: [
                                  context.colors.primary,
                                  context.colors.secondary,
                                ],
                                fontSize: context.fontsSize.display,
                                fontWeight: FontWeight.w900,
                              ),

                              SizedBox(width: context.spacing.xxl),

                              Image.asset(
                                'assets/logos/logoV2.png',
                                height: 50,
                                width: 50,
                                // color: const Color.fromARGB(255, 29, 29, 29).withAlpha(1000),
                                colorBlendMode: BlendMode.modulate,
                              ),
                            ],
                          ),

                          SizedBox(height: context.spacing.sm),

                          CustomTextWidget(
                            label:
                                "Camina, corre y lleva tu progreso, siempre ADELANTE",
                            fontSize: context.fontsSize.body,
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: context.spacing.xl),

                          SimpleButton(
                            label: "Registrate",
                            fontSize: context.fontsSize.body,
                            color: Colors.transparent,
                            fullWidth: true,
                            textColor: context.colors.border,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpPage(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: context.spacing.sm),

                          // SizedBox(width: context.spacing.md),
                          SimpleButton(
                            label: "Inicia sesión",
                            fontSize: context.fontsSize.body,
                            color: Colors.transparent,
                            fullWidth: true,
                            textColor: context.colors.border,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignInPage(),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: context.spacing.md),
                        ],
                      ),
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
