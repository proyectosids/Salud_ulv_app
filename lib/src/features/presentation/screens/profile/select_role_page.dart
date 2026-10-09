import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/core/usecase/profile/select_role_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/splash_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/buttons.dart';


class SelectRolePage extends StatelessWidget {
  const SelectRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectRoleBloc(
        selectRoleUseCase: SelectRoleUseCase(CurrentUserSession(), UserLocalRepo())),
      
      child: _SelectRolePage()
    );
  }
}


class _SelectRolePage extends StatefulWidget {
  const _SelectRolePage();

  @override
  State<_SelectRolePage> createState() => _SelectRolePageState();
}



class _SelectRolePageState extends State<_SelectRolePage> {

  // @override
  // void initState() {
  //   super.initState();
  //   context.read<GetProfileInfoBloc>().add(GetProfileEvent());
  //   context.read<CanChangeRoleBloc>().add(CanChangeRoleEvent());
  // }


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: context.colors.background,

      body: SafeArea(
        top: true,
        bottom: true,

        child: BlocListener<SelectRoleBloc, ProfileState>(
          listener: (context, state) {
            if (state is RoleSelected) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: .floating,
                  backgroundColor: context.colors.success  ,
                  content: Text('Rol cambiado a: ${state.role}'))
                );

              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashPage()));
        
              // if(state.role == 'Member'){
              //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MemberHomePage()));
              // } else if(state.role == 'Admin'){
              //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminHomePage()));
              // }
        
        
            }
          },
        
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: .stretch,
                children: [

                  Center(
                    // child: TitleWidget(title: "Selecciona un rol"),
                  ),
                  const SizedBox(height: 20),
                    
                  // ElevatedButton(
                  //   onPressed: () {
                  //     context.read<SelectRoleBloc>().add(SelectRoleEvent('Member'));
                  //   },
                  //   child: const Text('Miembro'),
                  // ),
                    
                  // const SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     context.read<SelectRoleBloc>().add(SelectRoleEvent('Admin'));
                  //   },
                    
                  //   child: const Text('Administrador'),
                  // ),
            
                  GridActionTile(
                    icon: FontAwesomeIcons.solidUser, 
                    label: "Miembro", 
                    onTap: () {context.read<SelectRoleBloc>().add(SelectRoleEvent('Member'));}
                  ),
            
                  const SizedBox(height: 20),
            
                  GridActionTile(
                    icon: FontAwesomeIcons.userShield, 
                    label: "Administrador", 
                    onTap: () {context.read<SelectRoleBloc>().add(SelectRoleEvent('Admin'));}
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}