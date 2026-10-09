abstract class IOtpRepo {
  Future<void> sendOTP(String email);
  Future<String?> verificationOTP(String otp, String email);
}
