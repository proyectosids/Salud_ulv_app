import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:salud_ulv_app/src/core/config/app_config.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/otp_repo.dart';

/// OTP client routed through the Salud ULV backend.
///
/// The backend owns the provider credentials. Keeping those credentials out of
/// this client prevents them from being recovered from an APK, IPA, or web
/// bundle.
class OtpServices implements IOtpRepo {
  const OtpServices();

  @override
  Future<void> sendOTP(String email) async {
    final response = await http
        .post(
          AppConfig.apiUri(AppConfig.otpSendPath),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 202) {
      throw Exception('No se pudo enviar el código de verificación.');
    }
  }

  @override
  Future<String?> verificationOTP(String otp, String email) async {
    final response = await http
        .post(
          AppConfig.apiUri(AppConfig.otpVerifyPath),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'otp': otp}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final verificationToken = body['verificationToken'];
      if (verificationToken is! String || verificationToken.isEmpty) {
        throw Exception('El servidor no devolvió una verificación válida.');
      }
      return verificationToken;
    }
    if ({400, 401, 409}.contains(response.statusCode)) return null;

    throw Exception('No se pudo verificar el código.');
  }
}
