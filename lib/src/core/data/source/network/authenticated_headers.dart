import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';

class AuthenticationRequiredException implements Exception {
  final String message;

  const AuthenticationRequiredException([
    this.message = 'La sesión no está disponible. Inicia sesión nuevamente.',
  ]);

  @override
  String toString() => message;
}

class AuthenticatedHeadersProvider {
  final ITokenStorageRepo tokenStorage;

  AuthenticatedHeadersProvider({ITokenStorageRepo? tokenStorage})
    : tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, String>> json() async {
    final token = (await tokenStorage.getUserToken())?.trim();
    if (token == null || token.isEmpty) {
      throw const AuthenticationRequiredException();
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}

bool isSuccessfulHttpStatus(int statusCode) =>
    statusCode >= 200 && statusCode < 300;
