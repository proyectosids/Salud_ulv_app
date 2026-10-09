import 'package:salud_ulv_app/src/core/repositories/repos/auth_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';

class ChangePwUseCase implements IChangePWUseCase {
  final IAuthExtRepo authRepo;
  final ITokenStorageRepo tokenStorageRepo;

  const ChangePwUseCase(this.authRepo, this.tokenStorageRepo);

  @override
  Future<void> execute(String email, String newPassword) async {
    final verificationToken = await tokenStorageRepo.getOTPToken();
    if (verificationToken == null) {
      throw Exception(
        'Debes verificar tu correo antes de cambiar la contraseña',
      );
    }
    await authRepo.resetPasswordWithEmail(
      email,
      newPassword,
      verificationToken,
    );
  }
}
