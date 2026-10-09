import 'package:salud_ulv_app/src/core/repositories/repos/auth_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';

class DeleteAccUsecase implements IDeleteAccUseCase {
  final ITokenStorageRepo tokenStorageRepo;
  final ITokenRepo tokenRepo;
  final IUserLocalRepo userLocalRepo;
  final IAuthExtRepo authRepo;

  const DeleteAccUsecase(
    this.authRepo,
    this.userLocalRepo,
    this.tokenRepo,
    this.tokenStorageRepo,
  );

  @override
  Future<void> execute() async {
    final token = await tokenStorageRepo.getUserToken();
    if (token == null) return;

    final decodedToken = tokenRepo.decode(token);
    final data = decodedToken['user'];
    final email = data['email'];
    final uuid = data['userUUID'];
    if (email == null) return;

    await authRepo.deleteAccount(email, token);
    await userLocalRepo.delete(uuid);
    await tokenStorageRepo.deleteToken();
  }
}
