import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salud_ulv_app/src/core/config/app_config.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/cycling_dto.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/running_dto.dart';
import 'package:salud_ulv_app/src/core/data/source/network/authenticated_headers.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/excercise_repo.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/walk_dto.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';

class ExerciseController implements IExerciseExtRepo {
  final http.Client _client;
  final AuthenticatedHeadersProvider _headersProvider;
  final Uri Function(String path) _apiUri;

  ExerciseController({
    http.Client? client,
    ITokenStorageRepo? tokenStorage,
    Uri Function(String path)? apiUri,
  }) : _client = client ?? http.Client(),
       _headersProvider = AuthenticatedHeadersProvider(
         tokenStorage: tokenStorage,
       ),
       _apiUri = apiUri ?? AppConfig.apiUri;

  @override
  Future<void> send(IPhysicalActivity? exercise) async {
    final result = switch (exercise) {
      Walk walk => WalkDTO.fromDomain(walk).toMap(),
      Running running => RunningDTO.fromDomain(running).toMap(),
      Cycling cycling => CyclingDTO.fromDomain(cycling).toMap(),
      null => throw ArgumentError.notNull('exercise'),
      _ => throw UnsupportedError('Unsupported activity type'),
    };

    // El backend obtiene la identidad del JWT; nunca se confia en un UUID
    // enviado por el cliente para asociar una actividad.
    result.remove('userUUID');

    final response = await _client
        .post(
          _apiUri('/exercise/save'),
          headers: await _headersProvider.json(),

          body: jsonEncode(result),
        )
        .timeout(const Duration(seconds: 10));

    if (!isSuccessfulHttpStatus(response.statusCode)) {
      debugPrint(response.statusCode.toString());
      throw Exception('No se pudo sincronizar la actividad física');
    }

    debugPrint('Actividad física sincronizada');
  }
}
