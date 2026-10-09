import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/data/source/network/auth_controller.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token.dart';
import 'package:salud_ulv_app/src/core/models/admin.dart';
import 'package:salud_ulv_app/src/core/models/member.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/delete_acc_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/logout_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/can_change_roles_verifier.dart';
// import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/get_profile_info_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/member_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/set_gender.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/splash_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/launch_url.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/containers.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/popups.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/snackbar.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class ProfileMainPage extends StatelessWidget {
  const ProfileMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetProfileInfoBloc(
            getUserInfoUsecase: GetProfileInfoUsecase(
              UserLocalRepo(),
              CurrentUserSession(),
              MemberLocalRepo(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) =>
              LogoutBloc(logoutUseCase: LogoutUsecase(TokenStorage())),
        ),

        BlocProvider(
          create: (context) => CanChangeRoleBloc(
            canChangeRolesVerifier: CanChangeRolesVerifier(
              CurrentUserSession(),
              UserLocalRepo(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => DeleteAccBloc(
            deleteAccUseCase: DeleteAccUsecase(
              AuthHTTPController(),
              UserLocalRepo(),
              TokenHandler(),
              TokenStorage(),
            ),
          ),
        ),

        BlocProvider(
          create: (context) => SetGenderBloc(
            setGenderUseCase: SetGenderUseCase(
              MemberLocalRepo(),
              CurrentUserSession(),
            ),
          ),
        ),
      ],

      child: _ProfileMainPage(),
    );
  }
}

class _ProfileMainPage extends StatefulWidget {
  const _ProfileMainPage();

  @override
  State<_ProfileMainPage> createState() => _ProfileMainPageState();
}

class _ProfileMainPageState extends State<_ProfileMainPage> {
  late String? email;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    context.read<GetProfileInfoBloc>().add(GetProfileEvent());
    context.read<CanChangeRoleBloc>().add(CanChangeRoleEvent());
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
        title: Text(
          'Perfil',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        top: true,
        bottom: true,

        child: MultiBlocListener(
          listeners: [
            BlocListener<GetProfileInfoBloc, ProfileState>(
              listener: (context, state) {
                if (state is ProfileError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            ),

            BlocListener<LogoutBloc, AuthState>(
              listener: (context, state) {
                if (state is Unauthenticated) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SplashPage()),
                  );
                }
                if (state is AuthError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            ),

            BlocListener<DeleteAccBloc, AuthState>(
              listener: (context, state) {
                if (state is Unauthenticated) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SplashPage()),
                  );
                }
                if (state is AuthError) {
                  CustomSnackBar.showError(context, state.message);
                }
              },
            ),

            BlocListener<SetGenderBloc, ProfileState>(
              listener: ((context, state) {
                if (state is ProfileDataSet) {
                  CustomSnackBar.showSuccess(
                    context,
                    "Datos guardado exitosamente",
                  );
                }
                if (state is ProfileError) {
                  CustomSnackBar.showError(context, state.message);
                }
              }),
            ),

            // BlocListener<CanChangeRoleBloc, ProfileState>(
            //   listener: (context, state) {
            //     if (state is CanChangeRole) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text('Rol seleccionado: ${state.role}')),
            //       );
            //     }
            //   }),
          ],

          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.sm),
              child: Center(
                child: Column(
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .stretch,
                  children: [
                    // const SizedBox(height: 20),

                    // Image.asset(
                    //   'assets/logos/logoV2.png',
                    //   width: 100,
                    //   height: 100,
                    // ),

                    // const SizedBox(height: 20),
                    BlocBuilder<GetProfileInfoBloc, ProfileState>(
                      builder: (context, state) {
                        // final spacing = context.spacing;

                        if (state is ProfileLoaded) {
                          debugPrint(
                            'IU profile user type: ${(state.user is User)}',
                          );
                          if (state.user is Member) {
                            final member = state.user as Member;
                            email = member.email!;
                            debugPrint('In the UI profile: $member');

                            return BackgroundContainer(
                              child: Column(
                                mainAxisAlignment: .center,
                                // crossAxisAlignment: .center,
                                children: [
                                  InitialsAvatar(
                                    firstName: member.firstname!,
                                    lastName: member.surname!,
                                    size: context.iconSize.xxl,
                                  ),
                                  SizedBox(height: context.spacing.md),

                                  CustomTextWidget(
                                    labelPrefix:
                                        '${member.firstname} ${member.surname} ${member.lastname}',
                                    label: '',
                                    fontSize: context.fontsSize.body,
                                    // backgroundColor: context.colors.secondary.withAlpha(50),
                                    // paddingSize: context.spacing.sm,
                                  ),
                                  SizedBox(height: context.spacing.sm),
                                  CustomTextWidget(
                                    label: member.email!,
                                    fontSize: context.fontsSize.caption,
                                    // labelPrefix: 'Correo: ',
                                    // backgroundColor: context.colors.secondary.withAlpha(50),
                                    // paddingSize: context.spacing.sm,
                                  ),
                                  // SizedBox(height: context.spacing.sm),
                                  // CustomTextWidget(
                                  //   label: member.userCode!,
                                  //   fontSize: context.fontsSize.caption,
                                  //   labelPrefix: 'Matrícula: ',
                                  //   // backgroundColor: context.colors.secondary.withAlpha(50),
                                  //   // paddingSize: context.spacing.sm,
                                  // ),
                                  SizedBox(height: context.spacing.lg),

                                  Row(
                                    mainAxisAlignment: .spaceEvenly,
                                    crossAxisAlignment: .center,
                                    mainAxisSize: .max,
                                    children: [
                                      // SizedBox(height: context.spacing.sm),
                                      CustomTextWidget(
                                        label: member.userCode!,
                                        fontSize: context.fontsSize.caption,
                                        labelPrefix: 'Matrícula: ',
                                        // backgroundColor: context.colors.secondary.withAlpha(50),
                                        // paddingSize: context.spacing.sm,
                                      ),

                                      if (member.gender != null) ...[
                                        CustomTextWidget(
                                          label: member.gender == 'male'
                                              ? 'Masculino'
                                              : 'Femenino',
                                          fontSize: context.fontsSize.caption,
                                          labelPrefix: 'Sexo: ',
                                          // backgroundColor: context.colors.secondary.withAlpha(50),
                                          // paddingSize: context.spacing.sm,
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: context.spacing.sm),

                                  CustomTextWidget(
                                    label: formatDate(member.createdAt!),
                                    fontSize: context.fontsSize.caption,
                                    labelPrefix: 'Miembro desde: ',
                                    // backgroundColor: context.colors.secondary.withAlpha(50),
                                    // paddingSize: context.spacing.sm,
                                  ),
                                ],
                              ),
                            );
                          } else if (state.user is Admin) {
                            final user = state.user as User;

                            return Column(
                              mainAxisAlignment: .center,
                              children: [
                                TextTile(label: user.userCode!),
                                Text('ID: ${user.userUUID} '),
                                Text('Matricula: ${user.userCode} '),
                                Text(
                                  '${user.firstname} ${user.surname} ${user.lastname}',
                                ),
                                Text('Correo: ${user.email} '),
                                Text('Perfil: ${user.currentRole} '),
                              ],
                            );
                          }

                          // else {
                          //   final user = state.user as User;

                          //   return Column(
                          //     mainAxisAlignment: .center,
                          //     children: [
                          //       TextTile(label: user.userCode!,),
                          //       Text('ID: ${user.userUUID} '),
                          //       Text('Matricula: ${user.userCode} '),
                          //       Text('${user.firstname} ${user.surname} ${user.lastname}'),
                          //       Text('Correo: ${user.email} '),
                          //       Text('Perfil: ${user.currentRole} '),
                          //     ],
                          //   );
                          // }
                        }

                        return const SizedBox();
                      },
                    ),
                    SizedBox(height: context.spacing.xl),

                    // SizedBox(height: context.spacing.md),

                    // // SectionTitle(title: 'Datos personales'), // Section
                    // const SizedBox(height: 10),
                    BackgroundContainer(
                      child: Column(
                        // mainAxisAlignment: .sr,
                        crossAxisAlignment: .stretch,
                        children: [
                          CustomTextWidget(
                            label: "Datos",
                            fontSize: context.fontsSize.title,
                            textAlign: .left,
                          ),
                          SizedBox(height: context.spacing.sm),

                          // IconTextTile(
                          //   icon: Icons.person_search,
                          //   label: "Registrar antopometricos",
                          //   onTap: () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => RegisterAnthroPage(),
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(height: context.spacing.sm),
                          IconTextTile(
                            icon: Icons.person,
                            label: "Personales",
                            onTap: () => CustomDialog.show(
                              context,
                              title: 'Datos personales',
                              showCloseButton: true,
                              // showOkButton: true,
                              child: Column(
                                children: [
                                  IconTextTile(
                                    icon: Icons.person_3,
                                    label: "Sexo",
                                    onTap: () => CustomDialog.show(
                                      context,
                                      okLabel: 'Guardar',
                                      onOkPressed: () => {
                                        context.read<SetGenderBloc>().add(
                                          SetGenderEvent(_selectedGender!),
                                        ),
                                        context.read<GetProfileInfoBloc>().add(
                                          GetProfileEvent(),
                                        ),
                                      },
                                      title: 'Elige tu sexo',
                                      showOkButton: true,
                                      child: StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: CustomSelectableCard(
                                                  value: 'male',
                                                  groupValue: _selectedGender,
                                                  onChanged: (value) {
                                                    setState(
                                                      () => _selectedGender =
                                                          value,
                                                    ); // updates page state
                                                    setDialogState(
                                                      () {},
                                                    ); // tells the dialog to rebuild too
                                                  },
                                                  title: 'Masculino',
                                                ),
                                              ),
                                              SizedBox(
                                                width: context.spacing.sm,
                                              ),
                                              Expanded(
                                                child: CustomSelectableCard(
                                                  value: 'female',
                                                  groupValue: _selectedGender,
                                                  onChanged: (value) {
                                                    setState(
                                                      () => _selectedGender =
                                                          value,
                                                    );
                                                    setDialogState(() {});
                                                  },
                                                  title: 'Femenino',
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: context.spacing.lg),

                          CustomTextWidget(
                            label: 'Apariencia',
                            fontSize: context.fontsSize.title,
                            textAlign: .left,
                          ),
                          SizedBox(height: context.spacing.sm),
                          const _ThemeModeSelector(),
                          SizedBox(height: context.spacing.lg),

                          CustomTextWidget(
                            label: "Cuenta",
                            fontSize: context.fontsSize.title,
                            textAlign: .left,
                          ),
                          SizedBox(height: context.spacing.sm),

                          IconTextTile(
                            icon: Icons.password,
                            label: "Eliminar cuenta",
                            onTap: () => CustomAlertDialog.show(
                              context,
                              title: "Borrar cuenta",
                              message:
                                  "¿Seguro que quiere borrar su cuenta? Todo los datos y progreso de la cuenta $email se perderán",
                              onTap: () => context.read<DeleteAccBloc>().add(
                                DeleteAccountEvent(),
                              ),
                            ),
                          ),
                          SizedBox(height: context.spacing.sm),

                          IconTextTile(
                            icon: Icons.logout,
                            label: "Cerrar sesión",
                            onTap: () => CustomAlertDialog.show(
                              context,
                              title: "Cerrar sesión",
                              message: "¿Quieres cerrar sesión?",
                              onTap: () =>
                                  context.read<LogoutBloc>().add(LogoutEvent()),
                            ),
                          ),
                          SizedBox(height: context.spacing.lg),

                          CustomTextWidget(
                            label: "Información",
                            fontSize: context.fontsSize.title,
                            textAlign: .left,
                          ),
                          SizedBox(height: context.spacing.sm),

                          IconTextTile(
                            icon: Icons.privacy_tip,
                            label: "Política de Privacidad",
                            onTap: () => launchUrls(
                              'https://ajrn-8bit.github.io/privacy_policies/salud-ulv/index.html',
                            ),
                          ),
                          SizedBox(height: context.spacing.sm),

                          // IconTextTile(
                          //   icon: Icons.info,
                          //   label: "Acerca de la aplicación",
                          //   onTap: () => {}
                          // ),
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

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerScope.of(context);
    final modeLabel = switch (controller.mode) {
      ThemeMode.system => 'Usar configuración del dispositivo',
      ThemeMode.light => 'Modo claro',
      ThemeMode.dark => 'Modo oscuro',
    };

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Cambiar apariencia',
      initialValue: controller.mode,
      onSelected: controller.setMode,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: _ThemeModeOption(
            icon: Icons.brightness_auto_rounded,
            label: 'Sistema',
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: _ThemeModeOption(
            icon: Icons.light_mode_rounded,
            label: 'Claro',
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: _ThemeModeOption(
            icon: Icons.dark_mode_rounded,
            label: 'Oscuro',
          ),
        ),
      ],
      child: Semantics(
        button: true,
        label: 'Apariencia: $modeLabel',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(switch (controller.mode) {
            ThemeMode.system => Icons.brightness_auto_rounded,
            ThemeMode.light => Icons.light_mode_rounded,
            ThemeMode.dark => Icons.dark_mode_rounded,
          }, color: context.colors.secondary),
          title: const Text('Tema de la aplicación'),
          subtitle: Text(modeLabel),
          trailing: const Icon(Icons.expand_more_rounded),
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }
}
