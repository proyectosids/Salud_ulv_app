
// import 'package:salud_ulv_app/src/core/models/member.dart';
import 'package:salud_ulv_app/src/core/models/roles.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';


abstract class ISignUpCredentialsUseCase{
  Future<bool> execute(String userCode, String email, String password);
}

abstract class IRegisterMemberUseCase{
  Future<void> execute(User user, String password, int typeID);
}

// abstract class IRegisterMemberUseCase{
//   Future<void> execute(Member memberInfo);
// }

abstract class ILoginUseCase{ // check if change to type instead of string
  Future<void> execute(String input, String password);
}

abstract class ISendOTPUseCase{
  Future<void> execute(String email);
}

abstract class IVerifyOTPUseCase{
  Future<bool?> execute(String otp, String email);
}


abstract class ICheckAuthUseCase{
  Future<UserRole?> execute();  // return the proper user type
}


abstract class IChangePWUseCase{
  Future<void> execute(String email, String newPassword);
}


abstract class ILogoutUseCase{
  Future<void> execute();
}


abstract class IDeleteAccUseCase{
  Future<void> execute();
}