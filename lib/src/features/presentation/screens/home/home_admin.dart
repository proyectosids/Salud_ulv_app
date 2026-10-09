import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/logout_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

// import 'package:salud_ulv_app/src/features/presentation/screens/records/get_exercise_admin_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              LogoutBloc(logoutUseCase: LogoutUsecase(TokenStorage())),
        ), // Logout
      ],
      child: const _AdminHomePage(),
    );
  }
}

class _AdminHomePage extends StatefulWidget {
  const _AdminHomePage();

  @override
  State<_AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<_AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushReplacementNamed(context, '/splash');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,

        body: _HomeTab(),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Admin Home"),
          const SizedBox(height: 30),

          // ElevatedButton(
          //   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GetAnthroAdminPage())),
          //   child: Text("Ver antropometricos")),
          const SizedBox(height: 20),

          // ElevatedButton(
          //   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GetActivityAdminPage())),
          //   child: Text("Ver actividades físicas"))
        ],
      ),
    );
  }
}
