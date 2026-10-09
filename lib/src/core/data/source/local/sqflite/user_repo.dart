// import 'package:salud_ulv_app/src/features/data/source/local/services/current_user_session.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/db_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/user_dto.dart';

class UserLocalRepo implements IUsersLocalRepo, IUserLocalRepo {
  Future<Database> get _db async => await AppDatabase.database;
  // final CurrentUserSession currentUserSession = CurrentUserSession();

  @override
  Future<void> save(User user) async {
    try {
      final db = await _db;

      final existing = await db.query(
        'Users',
        where: 'userUUID = ?',
        whereArgs: [user.userUUID],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        debugPrint('User already exists locally, skipping overwrite');
        return;
      }

      final model = UserDTO.fromDomain(user).toMap();
      final mModel = {'userUUID': user.userUUID};

      await db.insert(
        'Users',
        model,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.insert(
        'Members',
        mModel,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception("Could not save user locally");
    }
  }

  @override
  Future<void> update(User user) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future<String?> getCurrentRole(String userUUID) async {
    try {
      final db = await _db;

      debugPrint(
        'In get current role: $userUUID [--------------------------DEBUG--------------------------]',
      );

      final result = await db.query(
        'Users',
        columns: ['currentRole'],
        where: 'userUUID = ?',
        whereArgs: [userUUID],
      );

      if (result.isEmpty) {
        debugPrint(
          'No user found for uuid: $userUUID [--------------------------DEBUG--------------------------]',
        );
        return null;
      }

      final role = result.first['currentRole'] as String?;

      debugPrint(
        'In db: Getting role $role [--------------------------DEBUG--------------------------]',
      );

      return role;
    } catch (e) {
      throw Exception(
        "Could not get role [--------------------------DEBUG--------------------------]",
      );
    }
  }

  @override
  Future<void> setCurrentRole(String userUUID, String currentRole) async {
    try {
      final db = await _db;

      final currentRoleModel = {'currentRole': currentRole};
      await db.update(
        'Users',
        currentRoleModel,
        where: 'userUUID = ?',
        whereArgs: [userUUID],
        conflictAlgorithm: .replace,
      );
    } catch (e) {
      throw Exception("Could not set role");
    }
  }

  @override
  Future<List<String>?> getRoles(String userUUID) async {
    try {
      final db = await _db;

      final result = await db.query(
        'Users',
        columns: ['roles'],
        where: 'userUUID = ?',
        whereArgs: [userUUID],
      );

      if (result.isEmpty) {
        return null;
      }

      final rawRoles = result.first['roles'] as String?;
      final decoded = jsonDecode(rawRoles!) as List;
      final roles = decoded.cast<String>();

      debugPrint('In db: Getting roles $roles');

      return roles;
    } catch (e) {
      throw Exception("Could not set user roles");
    }
  }

  @override
  @override
  Future<void> setRoles(String userUUID, List<String> roles) async {
    try {
      final db = await _db;
      debugPrint('In db: Saving roles $roles');
      final rolesModel = {'roles': jsonEncode(roles)};

      await db.update(
        'Users',
        rolesModel,
        where: 'userUUID = ?',
        whereArgs: [userUUID],
        conflictAlgorithm: .replace,
      );
    } catch (e) {
      throw Exception("Could not set user roles");
    }
  }

  @override
  Future<User?> getUser(String userUUID) async {
    try {
      final db = await _db;

      final user = await db.query(
        'Users',
        where: 'userUUID = ?',
        whereArgs: [userUUID],
      );

      if (user.isEmpty) return null;

      return UserDTO.fromMap(user.first).toDomain();
    } catch (e) {
      throw Exception("Couldn't get current user");
    }
  }

  @override
  Future<List<String>?> getName(String userUUID) async {
    try {
      final db = await _db;

      final result = await db.query(
        'Users',
        columns: ['firstname', 'surname', 'lastname'],
        where: 'userUUID = ?',
        whereArgs: [userUUID],
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;

      final names = [
        row['firstname'] as String? ?? '',
        row['surname'] as String? ?? '',
        row['lastname'] as String? ?? '',
      ];

      return names;
    } catch (e) {
      throw Exception("Could not get name");
    }
  }

  @override
  Future<void> delete(String uuid) async {
    try {
      final db = await _db;

      await db.delete('Users', where: 'userUUID = ?', whereArgs: [uuid]);

      return;
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Could not delete user");
    }
  }
}
