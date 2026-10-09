import 'package:salud_ulv_app/src/core/repositories/repos/otp_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/check_connection_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';

class VerifyOtpUsecase implements IVerifyOTPUseCase {
  final ICheckConnectionRepo checkConnectionRepo;
  final IOtpRepo otpRepo;
  final ITokenStorageRepo tokenStorageRepo;

  const VerifyOtpUsecase(
    this.checkConnectionRepo,
    this.otpRepo,
    this.tokenStorageRepo,
  );

  @override
  Future<bool?> execute(String otp, String email) async {
    final hasConnection = await checkConnectionRepo.hasConnection();
    if (!hasConnection) return null;

    final verificationToken = await otpRepo.verificationOTP(otp, email);
    if (verificationToken == null) {
      throw Exception("Código inválido o ya usado. Genera uno nuevo");
    }

    await tokenStorageRepo.saveOTPToken(verificationToken);
    return true;
  }
}
