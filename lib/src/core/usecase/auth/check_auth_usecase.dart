import 'package:salud_ulv_app/src/core/models/roles.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';

class CheckAuthUsecase implements ICheckAuthUseCase {
  final ITokenStorageRepo tokenStorageRepo;
  final ITokenRepo tokenRepo;
  final ICurrentUserSession currentUserService;
  final IUserLocalRepo userLocalRepo;

  const CheckAuthUsecase(
    this.tokenStorageRepo,
    this.tokenRepo,
    this.currentUserService,
    this.userLocalRepo,
  );

  @override
  Future<UserRole?> execute() async {
    final token = await tokenStorageRepo.getUserToken();
    if (token == null) return null;

    final isExpired = tokenRepo.isExpired(token);
    if (isExpired) {
      await tokenStorageRepo.deleteToken();
      return null;
    }

    // Checks current tole and return the proper user type
    final userUUID = await currentUserService.getCurrentUserUUID();
    if (userUUID == null) return null;

    final role = await userLocalRepo.getCurrentRole(userUUID);
    final currentRole = role.toUserRole();

    // final userType = switch (currentRole) {
    //   "Member" => Member,
    //   "Admin" => Admin,
    //   _ => null
    // };

    return currentRole;
  }
}
