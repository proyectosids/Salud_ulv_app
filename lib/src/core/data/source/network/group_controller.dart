import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salud_ulv_app/src/core/config/app_config.dart';
import 'package:salud_ulv_app/src/core/data/source/network/authenticated_headers.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/models/group.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/group_repo.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/group_dto.dart';

class GroupController implements IGroupRepo {
  final http.Client _client;
  final AuthenticatedHeadersProvider _headersProvider;
  final Uri Function(String path) _apiUri;

  GroupController({
    http.Client? client,
    ITokenStorageRepo? tokenStorage,
    Uri Function(String path)? apiUri,
  }) : _client = client ?? http.Client(),
       _headersProvider = AuthenticatedHeadersProvider(
         tokenStorage: tokenStorage,
       ),
       _apiUri = apiUri ?? AppConfig.apiUri;

  @override
  Future<List<IGroup>?> getGroupsList(int typeID) async {
    try {
      final response = await _client
          .get(
            _apiUri('/groups/get/$typeID'),
            headers: await _headersProvider.json(),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode != 200) {
        debugPrint(response.statusCode.toString());
        throw Exception('Couldnt load group info');
      }

      final body = jsonDecode(response.body);
      // debugPrint('Data from api: ${body['data']}');

      debugPrint('before converting api data');

      final data = (body['data'] as List)
          .map(
            (item) =>
                GroupDTO.fromJson(item as Map<String, dynamic>).toDomain(),
          )
          .toList();

      return data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> joinGroup(String userUUID, int groupID) async {
    try {
      final response = await _client
          .post(
            _apiUri('/groups/add'),

            headers: await _headersProvider.json(),

            // El backend obtiene el usuario del JWT. `userUUID` se conserva
            // en la interfaz por compatibilidad, pero no se envia por red.
            body: jsonEncode({"groupID": groupID}),
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      debugPrint('En http para api: datos enviados');

      if (response.statusCode != 201) {
        debugPrint(response.statusCode.toString());
        throw Exception('Couldnt register member to a group');
      }

      return;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<IGroup?> getMemberGroup(int groupID) async {
    try {
      final response = await _client
          .get(
            _apiUri('/groups/get/members/$groupID'),
            headers: await _headersProvider.json(),
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode != 200) {
        debugPrint(response.statusCode.toString());
        throw Exception('Couldnt load group info');
      }

      final body = jsonDecode(response.body);
      final data = GroupDTO.fromJson(body['data']).toDomain();

      debugPrint('Sending data to use case');
      return data;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
