import 'package:salud_ulv_app/src/core/models/user.dart';

abstract class AuthEvent {}

class CheckOPTEvent extends AuthEvent {
  final String otp;
  final String email;

  CheckOPTEvent(this.otp, this.email);
}

class SendOTPEvent extends AuthEvent {
  final String email;

  SendOTPEvent(this.email);
}


class RegisterCredentialsEvent extends AuthEvent {
  final String userCode;
  final String email;
  final String password;
  // final String confirmedPw;

  RegisterCredentialsEvent({
    required this.userCode,
    required this.email,
    required this.password,
    // required this.confirmedPw,
  });
}

class RegisterEvent extends AuthEvent {
  final User user;
  final String password;
  final int typeID;

  RegisterEvent({required this.user, required this.password, required this.typeID});
}

// class RegisterInfoEvent extends AuthEvent {
//   final MemberInfo info;

//   RegisterInfoEvent(this.info);
// }

class LoginEvent extends AuthEvent {
  final String input;
  final String password;

  LoginEvent({required this.input, required this.password});
}

class CheckAuthEvent extends AuthEvent {}

class CheckRoleEvent extends AuthEvent {}



class ChangePasswordEvent extends AuthEvent{
    final String email;
  final String newPassword;
  ChangePasswordEvent({required this.email, required this.newPassword});
}



class DeleteAccountEvent extends AuthEvent{}

class LogoutEvent extends AuthEvent {}
