import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/activity_samples_dto.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/running_dto.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/excercise_repo.dart';
// import 'package:salud_ulv_app/src/features/data/source/local/services/current_user_session.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/db_config.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/exercise_sample_repo.dart';
import 'package:sqflite/sqflite.dart';

class RunningRepo implements IExerciseLocalRepo {
  Future<Database> get _db async => await AppDatabase.database;
  // final CurrentUserSession currentUserSession = CurrentUserSession();

  final _tableName = 'RunningActivity';

  @override
  Future<void> setIDs(
    String activityID,
    String userUUID,
    int categoryID,
    DateTime date,
  ) async {
    try {
      final db = await _db;

      final model = {
        'activityID': activityID,
        'userUUID': userUUID,
        'categoryID': categoryID,
        'registeredAt': date.toIso8601String(),
      };

      final id = await db.insert(_tableName, model);

      debugPrint('Created activity: $activityID');
      debugPrint('Inserted activity row: $id');

      final check = await db.query(
        _tableName,
        where: 'activityID = ?',
        whereArgs: [activityID],
      );

      debugPrint('ACTIVITY AFTER CREATION: $check');
    } catch (e, stackTrace) {
      debugPrint('ERROR SETTING ACTIVITY IDS: $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception("Error setting walk activity IDs");
    }
  }



  @override
  Future<void> save(IPhysicalActivity exercise) async {
    try {
      final db = await _db;
      final model = RunningDTO.fromDomain(exercise as Running).toMapFields();
      debugPrint('Saving running data to db');
      debugPrint(model.toString());

      // await db.update(
      //   _tableName,
      //   model,
      //   where: 'activityID == ?',
      //   whereArgs: [exercise.activityID],
      // );

      final updatedRows = await db.update(
        _tableName,
        model,
        where: 'activityID = ?',
        whereArgs: [exercise.activityID],
      );

      debugPrint(
        'Updated $updatedRows rows for activity ${exercise.activityID}',
      );
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error saving running activity");
    }
  }

  @override
  Future<String?> getRecentID(String userUUID) async {
    try {
      final db = await _db;

      final data = await db.query(
        _tableName,
        where: 'userUUID = ?',
        whereArgs: [userUUID],
        orderBy: 'registeredAt DESC',
        limit: 1,
      );

      if (data.isEmpty) return null;
      debugPrint(data.toString());

      final result = RunningDTO.fromMap(data.first).toDomain();
      // debugPrint(WalkDTO.fromMap(data.first).toString());
      // debugPrint('Date from db: ${result.registeredAt.toString()}');

      return result.activityID;
    } catch (e) {
      throw Exception("Error while getting recent running data");
    }
  }

  @override
  Future<IPhysicalActivity?> getRecent(String userUUID) async {
    try {
      final db = await _db;

      final data = await db.query(
        _tableName,
        where: 'userUUID = ?',
        whereArgs: [userUUID],
        orderBy: 'registeredAt DESC',
        limit: 1,
      );

      if (data.isEmpty) return null;
      // debugPrint('Recent data in db: $data');

      final result = RunningDTO.fromMap(data.first).toDomain();
      // debugPrint(WalkDTO.fromMap(data.first).toString());
      // debugPrint('Date from db: ${result.registeredAt.toString()}');

      return result;
    } catch (e) {
      throw Exception("Error while getting recent running data");
    }
  }

  @override
  Future<List<IPhysicalActivity>> getAll(String userUUID) async {
    try {
      final db = await _db;

      await db.delete(_tableName, where: 'distance == ?', whereArgs: [0]);

      // final result1 = await db.query(
      //   _tableName,
      //   where: 'userUUID = ?',
      //   whereArgs: [userUUID]
      // );

      // debugPrint('list');
      // debugPrint(userUUID);
      // debugPrint(result1.toString());

      final data = await db.query(
        _tableName,
        where: 'userUUID = ?',
        whereArgs: [userUUID],
        orderBy: 'registeredAt ASC',
      );

      final result = data
          .map((row) => RunningDTO.fromMap(row).toDomain())
          .toList();
      return result;
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error while getting all running data");
    }
  }

  // @override
  // Future<void> delete(String exerciseType, String activityID) async {
  //   try {
  //     final db = await _db;
  //     await db.delete(_tableName(exerciseType), where: 'activityID = ?', whereArgs: [activityID]);
  //   } catch (e) {
  //     throw Exception("Error deleting from $exerciseType");
  //   }
  // }
  @override
  Future<void> markAsSynced(String activityID) async {
    try {
      final db = await _db;

      await db.update(
        _tableName,
        {'isSynced': 1},
        where: 'activityID = ?',
        whereArgs: [activityID],
      );
    } catch (e) {
      return;
    }
  }

  @override
  Future<List<IPhysicalActivity>?> getUnsynced(String userUUID) async {
    try {
      final db = await _db;

      final data = await db.query(
        _tableName,
        where: 'userUUID = ? AND isSynced = ?',
        whereArgs: [userUUID, 0],
        orderBy: 'registeredAt DESC',
      );

      final result = data
          .map((row) => RunningDTO.fromMap(row).toDomain())
          .toList();
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> delete(String userUUID, String activityID) async {
    try {
      final db = await _db;

      await db.delete(
        _tableName,
        where: 'userUUID = ? AND activityID = ?',
        whereArgs: [userUUID, activityID],
      );
    } catch (e) {
      return;
    }
  }
}





class RunningSamplesRepo implements IActivitySampleRepo {
  Future<Database> get _db async => await AppDatabase.database;
  final _tableName = 'RunningActivitySample';

  @override
  Future<void> save(ActivitySample data) async {
    try {
      final db = await _db;

      final sample = data as RunningActivitySample;
      final model = RunningActivitySampleDTO.fromDomain(sample).toMap();

      final fks = await db.rawQuery("PRAGMA foreign_key_list('RunningActivitySample')");
debugPrint('FK REAL de la tabla: $fks');

final parentRunning = await db.query(
  'RunningActivity',
  where: 'activityID = ?',
  whereArgs: [sample.activityID],
);
final parentWalk = await db.query(
  'WalkActivity',
  where: 'activityID = ?',
  whereArgs: [sample.activityID],
);
debugPrint('Padre en Running: ${parentRunning.isNotEmpty} | en Walk: ${parentWalk.isNotEmpty}');

      final id = await db.insert(_tableName, model);

      debugPrint('Running sample inserted: row $id, activity ${sample.activityID}');
    } catch (e, stackTrace) {
      debugPrint('ERROR INSERTING RUNNING SAMPLE: $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception("Error in saving data");
    }
  }

  @override
  Future<List<IActivitySample>?> getSamples(String activityID) async {
    try {
      final db = await _db;

      final data = await db.query(
        _tableName,
        where: 'activityID = ?',
        whereArgs: [activityID],
        orderBy: 'timestamp_ms ASC',
      );

      return data
          .map((row) => RunningActivitySampleDTO.fromMap(row).toDomain())
          .toList();
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error in getting data");
    }
  }

  @override
  Future<void> delete(String activityID) async {
    try {
      final db = await _db;

      await db.delete(
        _tableName,
        where: 'activityID = ?',
        whereArgs: [activityID],
      );
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error in deleting data");
    }
  }
}