import 'package:salud_ulv_app/src/core/models/roles.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/auth_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/check_connection_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';
import 'package:uuid/uuid.dart';

class RegisterUserUsecase implements IRegisterMemberUseCase {
  final IAuthExtRepo authExtRepo;
  final IUserLocalRepo userLocalRepo;
  final ICheckConnectionRepo checkConnectionRepo;
  final ITokenStorageRepo tokenStorageRepo;
  final ITokenRepo tokenRepo;

  const RegisterUserUsecase(
    this.authExtRepo,
    this.userLocalRepo,
    this.checkConnectionRepo,
    this.tokenStorageRepo,
    this.tokenRepo,
  );

  @override
  Future<void> execute(User user, String password, int typeID) async {
    final hasConnection = await checkConnectionRepo.hasConnection();
    if (!hasConnection) return;

    // sets users last fields
    // user.userUUID = "B6E2C4F8-9A3D-4E1C-8F6B-3D7A2E9C5F14";
    user.userUUID = Uuid().v4().toUpperCase();
    user.currentRole = RoleStrings.member;
    user.roles = [RoleStrings.member];
    user.createdAt = DateTime.now().toUtc();

    final verificationToken = await tokenStorageRepo.getOTPToken();
    if (verificationToken == null) {
      throw Exception('Debes verificar tu correo antes de registrarte');
    }

    // registers user in the API
    final registered = await authExtRepo.registerMember(
      user,
      password,
      typeID,
      verificationToken,
    );
    if (!registered) throw Exception('Error al registrar usuario');

    return;
  }
}
