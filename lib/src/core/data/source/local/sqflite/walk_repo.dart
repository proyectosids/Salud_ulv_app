import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/activity_samples_dto.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/excercise_repo.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/walk_dto.dart';
// import 'package:salud_ulv_app/src/features/data/source/local/services/current_user_session.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/db_config.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/exercise_sample_repo.dart';
import 'package:sqflite/sqflite.dart';

class WalkRepo implements IExerciseLocalRepo {
  Future<Database> get _db async => await AppDatabase.database;
  // final CurrentUserSession currentUserSession = CurrentUserSession();

  final _tableName = 'WalkActivity';

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
      final model = WalkDTO.fromDomain(exercise as Walk).toMapFields();
      debugPrint('Saving walk data to db');
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
      throw Exception("Error saving walk activity");
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

      final result = WalkDTO.fromMap(data.first).toDomain();
      // debugPrint(WalkDTO.fromMap(data.first).toString());
      // debugPrint('Date from db: ${result.registeredAt.toString()}');

      return result.activityID;
    } catch (e) {
      throw Exception("Error while getting recent data");
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

      final result = WalkDTO.fromMap(data.first).toDomain();
      // debugPrint(WalkDTO.fromMap(data.first).toString());
      // debugPrint('Date from db: ${result.registeredAt.toString()}');

      return result;
    } catch (e) {
      throw Exception("Error while getting recent data");
    }
  }

  @override
  Future<List<IPhysicalActivity>> getAll(String userUUID) async {
    try {
      final db = await _db;

      // await db.delete(_tableName, where: 'steps == ?', whereArgs: [0]);

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
          .map((row) => WalkDTO.fromMap(row).toDomain())
          .toList();
      return result;
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error while getting all data");
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
          .map((row) => WalkDTO.fromMap(row).toDomain())
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

class WalkSamplesRepo implements IActivitySampleRepo {
  Future<Database> get _db async => await AppDatabase.database;
  final _tableName = 'WalkActivitySample';

  @override
  Future<void> save(ActivitySample data) async {
    try {
      final db = await _db;

      final sample = data as WalkActivitySample;
      final model = WalkActivitySampleDTO.fromDomain(sample).toMap();

      debugPrint('========== INSERT SAMPLE ==========');

      debugPrint('DB: $db');
      debugPrint('SAVE DB: ${identityHashCode(db)}');
      debugPrint('ID: [${sample.activityID}]');
      debugPrint('MODEL: $model');

      final id = await db.insert(_tableName, model);

      debugPrint('INSERTED ROW ID: $id');

      // Immediately query it using THE SAME db instance.
      final check = await db.query(
        _tableName,
        where: 'sampleID = ?',
        whereArgs: [id],
      );

      debugPrint('IMMEDIATE CHECK: $check');
    } catch (e, stackTrace) {
      debugPrint('ERROR INSERTING SAMPLE: $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception("Error in saving data");
    }
  }

  // @override
  // Future<List<IActivitySample>?>getSamples (String activityID) async {
  //   try {
  //     debugPrint('in db: $activityID');
  //     final db = await _db;

  //     final data = await db.query(
  //       _tableName,
  //       where: 'activityID = ?',
  //       whereArgs: [activityID],
  //       orderBy: 'timestamp_ms DESC');

  //     debugPrint('data samples from db: $data');

  //     final result = data.map((row) => WalkActivitySampleDTO.fromMap(row).toDomain()).toList();
  //     // debugPrint(result.toString());

  //     return result;

  //   } catch (e) {
  //     debugPrint(e.toString());
  //     throw Exception("Error in getting data");
  //   }
  // }

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

      // debugPrint('MATCHING ROWS: ${data.length}');
      // debugPrint('MATCHING DATA: $data');

      final result = data
          .map((row) => WalkActivitySampleDTO.fromMap(row).toDomain())
          .toList();

      // debugPrint('RESULT: ${result.length}');

      return result;
    } catch (e) {
      // debugPrint('GET SAMPLES ERROR: $e');
      // debugPrintStack(stackTrace: stackTrace);

      throw Exception("Error in getting data");
    }
  }

  @override
  Future<void> delete(String activityID) async {
    try {
      final db = await _db;

      await db.delete(
        _tableName,
        where: 'activityID == ?',
        whereArgs: [activityID],
      );
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error in deleting data");
    }
  }
}
