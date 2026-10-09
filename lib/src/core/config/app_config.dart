import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration loaded from the bundled `.env` file.
///
/// Only public configuration belongs here. Service credentials and private
/// API keys must remain on the backend because values compiled into a mobile
/// application can always be extracted.
abstract final class AppConfig {
  static String get _apiUrl => dotenv.get('API_URL', fallback: '');

  static String get otpSendPath =>
      dotenv.get('OTP_SEND_PATH', fallback: '/auth/otp/send');

  static String get otpVerifyPath =>
      dotenv.get('OTP_VERIFY_PATH', fallback: '/auth/otp/verify');

  static Uri apiUri(String path) {
    if (_apiUrl.trim().isEmpty) {
      throw StateError(
        'API_URL is not configured in the .env file.',
      );
    }

    final baseUri = Uri.tryParse(_apiUrl.trim());
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      throw StateError('API_URL must be an absolute HTTP(S) URL.');
    }

    if (baseUri.scheme != 'https' &&
        (kReleaseMode || baseUri.scheme != 'http')) {
      throw StateError('Production API_URL must use HTTPS.');
    }

    final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return baseUri.replace(path: '$normalizedBasePath$normalizedPath');
  }
}
