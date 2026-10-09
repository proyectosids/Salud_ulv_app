import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/config/app_config.dart';
import 'package:salud_ulv_app/src/core/data/source/network/authenticated_headers.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/models/anthropometrics.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/anthro_repo.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/anthro_dto.dart';

class AnthroController implements IAnthropometricExtRepo {
  final http.Client _client;
  final AuthenticatedHeadersProvider _headersProvider;
  final Uri Function(String path) _apiUri;

  AnthroController({
    http.Client? client,
    ITokenStorageRepo? tokenStorage,
    Uri Function(String path)? apiUri,
  }) : _client = client ?? http.Client(),
       _headersProvider = AuthenticatedHeadersProvider(
         tokenStorage: tokenStorage,
       ),
       _apiUri = apiUri ?? AppConfig.apiUri;

  @override
  Future<void> send(Anthropometrics data) async {
    try {
      final anthroData = AnthropometricsDTO.fromDomain(data).toJson();

      // El backend asocia la medicion al usuario autenticado del JWT.
      anthroData.remove('userUUID');

      final response = await _client
          .post(
            _apiUri('/anthropometric/save'),
            headers: await _headersProvider.json(),

            body: jsonEncode(anthroData),
          )
          .timeout(Duration(seconds: 5));

      if (!isSuccessfulHttpStatus(response.statusCode)) {
        debugPrint(response.statusCode.toString());
        throw Exception('Error al registrar antropometricos');
      }

      debugPrint("Sending item to API");
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Anthropometrics>?> getAll() async {
    try {
      final response = await _client
          .get(
            _apiUri('/anthropometric/get/all'),
            headers: await _headersProvider.json(),
          )
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode != 200) {
        debugPrint(response.statusCode.toString());
        throw Exception('Couldnt get data');
      }

      final body = jsonDecode(response.body);
      debugPrint("Taking data from API");

      return (body['data'] as List)
          .map(
            (item) => AnthropometricsDTO.fromJson(
              item as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Anthropometrics>?> getByUserCode(String input) async {
    try {
      final response = await _client
          .get(
            _apiUri('/anthropometric/get/$input'),
            headers: await _headersProvider.json(),
          )
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode != 200) {
        debugPrint(response.statusCode.toString());
        throw Exception('Couldnt get data');
      }

      final body = jsonDecode(response.body);
      debugPrint("Taking data from API");

      return (body['data'] as List)
          .map(
            (item) => AnthropometricsDTO.fromJson(
              item as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>?> getByCodeAndField(
    String input,
    String field,
  ) {
    // TODO: implement getByField
    throw UnimplementedError();
  }
}
