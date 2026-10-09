import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_repo.dart';

class TokenHandler implements ITokenRepo {
  @override
  Map<String, dynamic> decode(String token) {
    return JwtDecoder.decode(token);
  }

  @override
  bool isExpired(String token) {
    return JwtDecoder.isExpired(token);
  }

  (String?, String?) getCurrentUserIDs(String token) {
    final data = decode(token);

    final userUUID = data['uuid'] as String;
    final userCode = data['userCode'] as String;

    return (userUUID, userCode);
  }
}
