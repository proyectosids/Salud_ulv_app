// import 'package:salud_ulv_app/src/core/models/user.dart';
// import 'package:salud_ulv_app/src/core/repositories/repos/auth_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/auth_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/check_connection_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/auth_command.dart';
// import 'package:uuid/uuid.dart';

class SignUpCredentialsUsecase implements ISignUpCredentialsUseCase{
  final IAuthExtRepo authRepo;
  final ICheckConnectionRepo checkConnectionRepo;

  const SignUpCredentialsUsecase(this.authRepo, this.checkConnectionRepo);

  @override
  Future<bool> execute(String userCode, String email, String password) async {

    final hasConnection = await checkConnectionRepo.hasConnection();
    if(!hasConnection) throw Exception("No internet");

    final command = AuthCommand(
      userCode: userCode, 
      email: email, 
      password: password
      );

    if(!command.isValidUserID()){
      throw ArgumentError('Formato de matrícula inválida');
    }

    if (!command.validateEmail()) {
      throw ArgumentError('Formato de correo inválido');
    }

    if (!command.validatePassword()) {
      throw ArgumentError('Ingresar correcto formato de contraseña');
    }

    // if(password != confirmedPw){
    //   throw ArgumentError('Contraseñas no coinciden');
    // }

    final userExists = await authRepo.userExists(userCode, email);
    if(userExists){
      throw Exception('Matrícula o correo ya registrados');
    }


    return true;
  }
}