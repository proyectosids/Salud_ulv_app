import 'package:path/path.dart';
import 'package:salud_ulv_app/src/core/models/exercise_categories.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;
  AppDatabase._instance();
  static final AppDatabase instance = AppDatabase._instance();

  static Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'SaludULV.db');

    return await openDatabase(
      path,
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.update(
            'ActivityCategory',
            {'categoryName': 'walk'},
            where: 'categoryID = ?',
            whereArgs: [ExerciseCategoryIds.walk],
          );
          await db.update(
            'ActivityCategory',
            {'categoryName': 'running'},
            where: 'categoryID = ?',
            whereArgs: [ExerciseCategoryIds.running],
          );
          await db.insert('ActivityCategory', {
            'categoryID': ExerciseCategoryIds.cycling,
            'categoryName': 'cycling',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          await db.update('WalkActivity', {
            'categoryID': ExerciseCategoryIds.walk,
          });
          await db.update('RunningActivity', {
            'categoryID': ExerciseCategoryIds.running,
          });
          await db.update('CyclingActivity', {
            'categoryID': ExerciseCategoryIds.cycling,
          });
        }
      },

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Users (
            userUUID TEXT PRIMARY KEY NOT NULL,
            userCode TEXT UNIQUE NOT NULL,
            firstname TEXT NOT NULL,
            surname TEXT NOT NULL,
            lastname TEXT NOT NULL,
            email TEXT NOT NULL,
            currentRole TEXT DEFAULT NULL,
            roles TEXT DEFAULT NULL,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE Members (
            userUUID TEXT PRIMARY KEY,
            groupID INTEGER NULL,
            typeID INTERGER NULL,

            dateOfBirth TEXT DEFAULT NULL,
            age INTEGER DEFAULT NULL,
            level INTEGER NULL DEFAULT 0,
            gender TEXT DEFAULT NULL,
            
            FOREIGN KEY (userUUID) REFERENCES Users (userUUID) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
        CREATE TABLE Anthropometrics (
          anthropometricID TEXT PRIMARY KEY NOT NULL,
          userUUID TEXT NOT NULL,
          height REAL NOT NULL,
          weight REAL NOT NULL,
          smm REAL NOT NULL,
          fatMass REAL NOT NULL,
          bodyFatPercentage REAL NOT NULL,
          bmi REAL NOT NULL,
          whr REAL NOT NULL,
          registeredAt TEXT NOT NULL,
          
          isSynced INTEGER NOT NULL DEFAULT 0,

          FOREIGN KEY (userUUID) REFERENCES Users (userUUID) ON DELETE CASCADE
        )
      ''');

        // Categories
        await db.execute('''
        CREATE TABLE ActivityCategory (
          categoryID INTEGER PRIMARY KEY,
          categoryName TEXT NOT NULL
        )
      ''');

        // Sets categories
        await db.insert('ActivityCategory', {
          'categoryID': ExerciseCategoryIds.walk,
          'categoryName': 'walk',
        });
        await db.insert('ActivityCategory', {
          'categoryID': ExerciseCategoryIds.running,
          'categoryName': 'running',
        });
        await db.insert('ActivityCategory', {
          'categoryID': ExerciseCategoryIds.cycling,
          'categoryName': 'cycling',
        });

        await db.execute('''
        CREATE TABLE WalkActivity (
          activityID TEXT PRIMARY KEY NOT NULL,
          userUUID TEXT NOT NULL,
          categoryID INTEGER NOT NULL REFERENCES ActivityCategory(categoryID),
          registeredAt TEXT NOT NULL,

          duration_ms INTEGER DEFAULT 0,
          caloriesBurned REAL DEFAULT 0,

          distance REAL DEFAULT 0,
          avgPace REAL DEFAULT 0,
          elevationGain REAL DEFAULT 0,
          avgCadence REAL DEFAULT 0,
          heartRate REAL DEFAULT 0,

          steps INTEGER DEFAULT 0,
          avgSteps REAL DEFAULT 0,

          isSynced INTEGER NOT NULL DEFAULT 0,

          FOREIGN KEY (userUUID) REFERENCES Users (userUUID) ON DELETE CASCADE
        )
      '''); // Steps is null to allow devices with no accelerometer

        await db.execute('''
        CREATE INDEX idx_WalkActivity_activity_useruuid
        ON WalkActivity(activityID, userUUID)
      ''');

        // Exercise cache
        // Steps just for walking
        await db.execute('''
        CREATE TABLE WalkActivitySample (
          sampleID INTEGER PRIMARY KEY AUTOINCREMENT,
          activityID TEXT NOT NULL,

          timestamp_ms INTEGER DEFAULT 0,

          heartRate INTEGER DEFAULT 0,
          distance REAL DEFAULT 0,
          calories REAL DEFAULT 0,
          steps INTEGER DEFAULT 0,
          pace REAL DEFAULT 0,
          speed REAL DEFAULT 0,
          cadence REAL DEFAULT 0,
          elevation REAL DEFAULT 0,

          latitude REAL DEFAULT 0,
          longitude REAL DEFAULT 0,

          FOREIGN KEY (activityID) REFERENCES WalkActivity (activityID) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE INDEX idx_WalkActivitySample_activity_timestamp
        ON WalkActivitySample(activityID, timestamp_ms)
      ''');

        await db.execute('''
        CREATE TABLE RunningActivity (
          activityID TEXT PRIMARY KEY NOT NULL,
          userUUID TEXT NOT NULL,
          categoryID INTEGER NOT NULL REFERENCES ActivityCategory(categoryID),
          registeredAt TEXT NOT NULL,

          duration_ms INTEGER DEFAULT 0,
          caloriesBurned REAL DEFAULT 0,

          distance REAL DEFAULT 0,
          avgPace REAL DEFAULT 0,
          elevationGain REAL DEFAULT 0,
          avgCadence REAL DEFAULT 0,
          heartRate REAL DEFAULT 0,

          speed REAL DEFAULT 0,
          avgSpeed REAL DEFAULT 0,

          isSynced INTEGER NOT NULL DEFAULT 0,

          FOREIGN KEY (userUUID) REFERENCES Users (userUUID) ON DELETE CASCADE
        )
      '''); // Steps is null to allow devices with no accelerometer

        await db.execute('''
        CREATE INDEX idx_RunningActivity_activity_useruuid
        ON RunningActivity(activityID, userUUID)
      ''');

        // Exercise cache
        // Steps just for walking
        await db.execute('''
        CREATE TABLE RunningActivitySample (
          sampleID INTEGER PRIMARY KEY AUTOINCREMENT,
          activityID TEXT NOT NULL,

          timestamp_ms INTEGER DEFAULT 0,

          heartRate INTEGER DEFAULT 0,
          distance REAL DEFAULT 0,
          calories REAL DEFAULT 0,
          pace REAL DEFAULT 0,
          speed REAL DEFAULT 0,
          cadence REAL DEFAULT 0,
          elevation REAL DEFAULT 0,

          latitude REAL DEFAULT 0,
          longitude REAL DEFAULT 0,

          FOREIGN KEY (activityID) REFERENCES RunningActivity (activityID) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE INDEX idx_RunningActivitySample_activity_timestamp
        ON RunningActivitySample(activityID, timestamp_ms)
      ''');

        await db.execute('''
        CREATE TABLE CyclingActivity (
          activityID TEXT PRIMARY KEY NOT NULL,
          userUUID TEXT NOT NULL,
          categoryID INTEGER NOT NULL REFERENCES ActivityCategory(categoryID),
          registeredAt TEXT NOT NULL,

          duration_ms INTEGER DEFAULT 0,
          caloriesBurned REAL DEFAULT 0,

          distance REAL DEFAULT 0,
          avgPace REAL DEFAULT 0,
          elevationGain REAL DEFAULT 0,
          avgElevationGain REAL DEFAULT 0,
          avgCadence REAL DEFAULT 0,
          heartRate REAL DEFAULT 0,

          speed REAL DEFAULT 0,
          avgSpeed REAL DEFAULT 0,

          isSynced INTEGER NOT NULL DEFAULT 0,

          FOREIGN KEY (userUUID) REFERENCES Users (userUUID) ON DELETE CASCADE
        )
      '''); // Steps is null to allow devices with no accelerometer

        await db.execute('''
        CREATE INDEX idx_CyclingActivity_activity_useruuid
        ON CyclingActivity(activityID, userUUID)
      ''');

        // Exercise cache
        // Steps just for walking
        await db.execute('''
        CREATE TABLE CyclingActivitySample (
          sampleID INTEGER PRIMARY KEY AUTOINCREMENT,
          activityID TEXT NOT NULL,

          timestamp_ms INTEGER DEFAULT 0,

          heartRate INTEGER DEFAULT 0,
          distance REAL DEFAULT 0,
          calories REAL DEFAULT 0,
          pace REAL DEFAULT 0,
          speed REAL DEFAULT 0,
          cadence REAL DEFAULT 0,
          elevation REAL DEFAULT 0,

          latitude REAL DEFAULT 0,
          longitude REAL DEFAULT 0,

          FOREIGN KEY (activityID) REFERENCES CyclingActivity (activityID) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE INDEX idx_CyclingActivitySample_activity_timestamp
        ON CyclingActivitySample(activityID, timestamp_ms)
      ''');
      },
    );
  }
}
