
import 'package:salud_ulv_app/src/core/models/roles.dart';

abstract class AuthState{}

class AuthInitial extends AuthState{}
class AuthLoading extends AuthState{}

class Authenticated extends AuthState{}
class ContinueAuth extends AuthState{
  final bool isCorrect;
  ContinueAuth(this.isCorrect);
}

class CheckAuthenticated extends AuthState{
  final UserRole role;
  CheckAuthenticated(this.role);
}


class LoginAuthenticated extends AuthState{
  final String currentRole;
  LoginAuthenticated(this.currentRole);
}

class OtpSent extends AuthState{}

class PasswordChanged extends AuthState{}

class Unauthenticated extends AuthState{}

class AuthError extends AuthState{
  final String message;
  AuthError(this.message);
}