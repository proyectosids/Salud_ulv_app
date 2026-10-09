import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/core/config/app_config.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString: '''
API_URL=http://localhost:3030
OTP_SEND_PATH=/auth/otp/send
OTP_VERIFY_PATH=/auth/otp/verify
''',
    );
  });

  tearDown(dotenv.clean);

  test('builds API URIs from the environment file configuration', () {
    expect(
      AppConfig.apiUri('/status'),
      Uri.parse('http://localhost:3030/status'),
    );
    expect(AppConfig.otpSendPath, '/auth/otp/send');
    expect(AppConfig.otpVerifyPath, '/auth/otp/verify');
  });
}
