
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/profile_usecase.dart';
// import 'package:salud_ulv_app/src/core/usecase/profile/get_profile_info_usecase.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/profile_bloc/profile_state.dart';

class GetProfileInfoBloc extends Bloc<ProfileEvent, ProfileState> {
  final IGetProfileInfoUsecase getUserInfoUsecase;

  GetProfileInfoBloc({required this.getUserInfoUsecase}): super(ProfileInitial()){
    on<GetProfileEvent>(_getUserInfo);
  }

  Future<void> _getUserInfo(GetProfileEvent event, Emitter<ProfileState> emit) async{
    try {
      emit(ProfileLoading());
      final user = await getUserInfoUsecase.execute();
      debugPrint('In profile bloc: $user');
      emit(ProfileLoaded(user!));
      
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}


class CanChangeRoleBloc extends Bloc<ProfileEvent, ProfileState>{
  final ICanChangeRole canChangeRolesVerifier;

  CanChangeRoleBloc({required this.canChangeRolesVerifier}) : super(ProfileInitial()) {
    on<CanChangeRoleEvent>((event, emit) async {
      try {
        emit(ProfileLoading());
        final canChange = await canChangeRolesVerifier.execute();
        debugPrint('In bloc can change role: $canChange');
        emit(CanChangeRole(canChange));
      } catch (e) {
        emit(ProfileError(''));
      }
    });
  }
}


class SelectRoleBloc extends Bloc<ProfileEvent, ProfileState>{
  final ISelectRoleUseCase selectRoleUseCase;

  SelectRoleBloc({required this.selectRoleUseCase}) : super(ProfileInitial()) {
    on<SelectRoleEvent>((event, emit) async {
      try {
        emit(ProfileLoading());
        final role = await selectRoleUseCase.execute(event.role);
        emit(RoleSelected(role!));
      } catch (e) {
        emit(ProfileError(''));
      }
    });
  }
}


class GetUserNameBloc extends Bloc<ProfileEvent, ProfileState>{
  final IGetUserNameUseCase getUserName;

  GetUserNameBloc({required this.getUserName}) : super(ProfileInitial()) {
    on<GetUserNameEvent>((event, emit) async {
      try {
        emit(ProfileLoading());
        final name = await getUserName.execute();
        emit(UserNameLoaded(name!));
      } catch (e) {
        emit(ProfileError(''));
      }
    });
  }
}

class SetGenderBloc extends Bloc<ProfileEvent, ProfileState>{
  final ISetGenderUseCase setGenderUseCase;

  SetGenderBloc({required this.setGenderUseCase}) : super(ProfileInitial()) {
    on<SetGenderEvent>((event, emit) async {
      try {
        emit(ProfileLoading());
        await setGenderUseCase.execute(event.gender);
        emit(ProfileDataSet());
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });
  }
}