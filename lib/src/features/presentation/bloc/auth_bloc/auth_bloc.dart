import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';

class RegisterCredentialsBloc extends Bloc<AuthEvent, AuthState> {
  final ISignUpCredentialsUseCase signUpCredentialsUseCase;

  RegisterCredentialsBloc({required this.signUpCredentialsUseCase})
    : super(AuthInitial()) {
    on<RegisterCredentialsEvent>((event, emit) async {
      try {
        emit(AuthLoading());
        final isCorrect = await signUpCredentialsUseCase.execute(
          event.userCode,
          event.email,
          event.password
          // event.confirmedPw,
        );
        emit(ContinueAuth(isCorrect));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}

class SendOTPBloc extends Bloc<AuthEvent, AuthState> {
  final ISendOTPUseCase sendOTPUseCase;

  SendOTPBloc({required this.sendOTPUseCase}) : super(AuthInitial()) {
    on<SendOTPEvent>((event, emit) async {
      try {
        emit(AuthLoading());
        await sendOTPUseCase.execute(event.email);
        emit(OtpSent());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}

class CheckOTPBloc extends Bloc<AuthEvent, AuthState> {
  final IVerifyOTPUseCase verifyOTPUseCase;

  CheckOTPBloc({required this.verifyOTPUseCase}) : super(AuthInitial()) {
    on<CheckOPTEvent>((event, emit) async {
      try {
        emit(AuthLoading());
        final isVerified = await verifyOTPUseCase.execute(
          event.otp,
          event.email,
        );
        emit(ContinueAuth(isVerified!));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}

class RegisterUserBloc extends Bloc<AuthEvent, AuthState> {
  final IRegisterMemberUseCase registryUsecase;

  RegisterUserBloc({required this.registryUsecase}) : super(AuthInitial()) {
    on<RegisterEvent>((event, emit) async {
      try {
        emit(AuthLoading());
        await registryUsecase.execute(event.user, event.password, event.typeID);
        emit(
          Authenticated(),
        ); // The user automatically logs in after registration
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}

// class RegisterInfoBLoc extends Bloc<AuthEvent, AuthState>{
//   final IRegisterMemberInfoUseCase useCase ;

//   RegisterInfoBLoc({required this.useCase}) : super(AuthInitial()) {
//     on<RegisterInfoEvent>((event, emit) async {
//       try {
//         emit(AuthLoading());
//         await useCase.execute(event.info);
//         emit(Authenticated());

//       } catch (e) {
//         emit(AuthError(''));
//       }
//     });
//   }
// }

class LoginBloc extends Bloc<AuthEvent, AuthState> {
  final ILoginUseCase loginUsecase;

  LoginBloc({required this.loginUsecase}) : super(AuthInitial()) {
    on<LoginEvent>(_login);
  }

  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      await loginUsecase.execute(event.input, event.password);
      emit(Authenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}


class ChangePasswordBloc extends Bloc<AuthEvent, AuthState> {
  final IChangePWUseCase changePWUseCase;

  ChangePasswordBloc({required this.changePWUseCase}) : super(AuthInitial()) {
    on<ChangePasswordEvent>(_changePw);
  }

  Future<void> _changePw(ChangePasswordEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      await changePWUseCase.execute(event.email, event.newPassword);
      emit(PasswordChanged());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}



class LogoutBloc extends Bloc<AuthEvent, AuthState> {
  final ILogoutUseCase logoutUseCase;

  LogoutBloc({required this.logoutUseCase}) : super(AuthInitial()) {
    on<LogoutEvent>(_logout);
  }

  Future<void> _logout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      await logoutUseCase.execute();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}

class CheckRoleBLoc extends Bloc<AuthEvent, AuthState> {
  final ICheckAuthUseCase checkAuthUseCase;

  CheckRoleBLoc({required this.checkAuthUseCase}) : super(AuthInitial()) {
    on<CheckRoleEvent>((event, emit) async {
      try {
        final role = await checkAuthUseCase.execute();
        debugPrint(
          "Role in bloc: ${role.toString()} [--------------------------DEBUG--------------------------]",
        );
        if (role == null) {
          emit(Unauthenticated());
        } else {
          emit(CheckAuthenticated(role));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}

class CheckAuthBloc extends Bloc<AuthEvent, AuthState> {
  final ICheckAuthUseCase checkAuthUseCase;

  CheckAuthBloc({required this.checkAuthUseCase}) : super(AuthInitial()) {
    on<CheckAuthEvent>((event, emit) async {
      try {
        final role = await checkAuthUseCase.execute();
        if (role == null) {
          emit(Unauthenticated());
        } else {
          emit(Authenticated());
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}

class DeleteAccBloc extends Bloc<AuthEvent, AuthState> {
  final IDeleteAccUseCase deleteAccUseCase;

  DeleteAccBloc({required this.deleteAccUseCase}) : super(AuthInitial()) {
    on<DeleteAccountEvent>((event, emit) async {
      try {
        emit(AuthLoading());
        await deleteAccUseCase.execute();
        emit(Unauthenticated());

      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
