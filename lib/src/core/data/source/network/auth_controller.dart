import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salud_ulv_app/src/core/config/app_config.dart';
import 'package:salud_ulv_app/src/core/models/member.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/auth_repo.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/member_dto.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/user_dto.dart';

class AuthHTTPController implements IAuthExtRepo {
  AuthHTTPController({http.Client? client, Uri Function(String path)? apiUri})
    : _client = client ?? http.Client(),
      _apiUri = apiUri ?? AppConfig.apiUri;

  final http.Client _client;
  final Uri Function(String path) _apiUri;

  @override
  Future<bool> userExists(String userCode, String email) async {
    try {
      final request = await _client
          .post(
            _apiUri('/auth/user/exists'),
            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({"userCode": userCode, "email": email}),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (request.statusCode == 200) {
        debugPrint(request.statusCode.toString());
        return true;
        // throw Exception('Error al registrar usuario');
      }

      return false;
    } catch (e) {
      debugPrint(' $e');
      rethrow;
    }
  }

  @override
  Future<bool> registerMember(
    User user,
    String password,
    int typeID,
    String verificationToken,
  ) async {
    try {
      final userData = UserDTO.fromDomain(user).toJson();

      final body = jsonEncode({
        "user": userData,
        "password": password,
        "typeID": typeID,
        "verificationToken": verificationToken,
      });

      final request = await _client
          .post(
            _apiUri('/auth/register'),
            headers: {'Content-Type': 'application/json'},

            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (request.statusCode != 201) {
        debugPrint(request.statusCode.toString());
        throw AuthRequestException(switch (request.statusCode) {
          403 => 'La verificación de correo expiró. Solicita un código nuevo.',
          409 => 'Ya existe una cuenta con ese correo o matrícula.',
          _ => 'No fue posible crear la cuenta. Inténtalo nuevamente.',
        });
      }

      return true; // registered in API
    } catch (e) {
      debugPrint(' $e');
      rethrow;
    }
  }

  @override
  Future<String?> loginWithEmailOrCode(String input, String password) async {
    try {
      final request = await _client
          .post(
            _apiUri('/auth/login'),
            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({
              "input": input.toString(),
              "password": password.toString(),
            }),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (request.statusCode != 200) {
        debugPrint(request.statusCode.toString());
        throw AuthRequestException(
          request.statusCode == 401
              ? 'Usuario o contraseña incorrectos.'
              : 'No fue posible iniciar sesión. Inténtalo nuevamente.',
        );
      }

      final body = jsonDecode(request.body);
      final token = body['token'] as String;

      return token;
    } catch (e) {
      debugPrint(' $e');
      rethrow;
    }
  }

  @override
  Future<void> resetPasswordWithEmail(
    String email,
    String newPassword,
    String verificationToken,
  ) async {
    try {
      final response = await _client.post(
        _apiUri('/auth/changePw'),
        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({
          "email": email,
          "newPassword": newPassword,
          "verificationToken": verificationToken,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(response.statusCode.toString());
        throw Exception('Error al cambiar contraseña');
      }
    } catch (e) {
      debugPrint(' $e');
      rethrow;
    }
  }

  Future<void> registerMemberInfo(MemberInfo info) async {
    try {
      final data = MemberInfoDTO.fromDomain(info).toJson();

      final response = await _client
          .post(
            _apiUri('/auth/saveMemberInfo'),
            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({data}),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode != 200) {
        debugPrint(response.statusCode.toString());
        throw Exception('Error');
      }
    } catch (e) {
      debugPrint(' $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount(String email, String authToken) async {
    try {
      final response = await _client.delete(
        _apiUri('/auth/deleteAcc'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },

        body: jsonEncode({"email": email}),
      );

      if (response.statusCode != 200) {
        debugPrint(response.statusCode.toString());
        throw Exception('Error al borrar usuario');
      }

      return;
    } catch (e) {
      debugPrint(' $e');
      rethrow;
    }
  }
}

class AuthRequestException implements Exception {
  const AuthRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
