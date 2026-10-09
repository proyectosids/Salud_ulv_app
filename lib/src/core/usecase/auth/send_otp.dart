import 'package:salud_ulv_app/src/core/repositories/repos/otp_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/check_connection_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';

class SendOtpUsecase implements ISendOTPUseCase {
  final ICheckConnectionRepo checkConnectionRepo;
  final IOtpRepo otpRepo;

  const SendOtpUsecase(this.checkConnectionRepo, this.otpRepo);

  @override
  Future<void> execute(String email) async {
    final hasConnection = await checkConnectionRepo.hasConnection();
    if (!hasConnection) return;

    await otpRepo.sendOTP(email);
  }
}
