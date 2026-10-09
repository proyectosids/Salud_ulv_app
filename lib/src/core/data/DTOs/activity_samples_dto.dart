import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';


class ActivitySampleDTO {
  final int? sampleID;
  final String activityID;
  final Duration? timestampMs;

  final int? heartRate;
  final double? distance;
  final double? calories;
  final double? pace;
  final double? speed;
  final double? cadence;
  final double? elevation;

  final double? latitude;
  final double? longitude;

  ActivitySampleDTO({
    this.sampleID,
    required this.activityID,
    required this.timestampMs,
    this.heartRate,
    this.distance,
    this.calories,
    this.pace,
    this.speed,
    this.cadence,
    this.elevation,
    this.latitude,
    this.longitude,
  });

  factory ActivitySampleDTO.fromDomain(ActivitySample sample) {
    return ActivitySampleDTO(
      sampleID: sample.sampleID,
      activityID: sample.activityID,
      timestampMs: sample.timestampMs,
      heartRate: sample.heartRate,
      distance: sample.distance,
      calories: sample.calories,
      pace: sample.pace,
      speed: sample.speed,
      cadence: sample.cadence,
      elevation: sample.elevation,
      latitude: sample.latitude,
      longitude: sample.longitude,
    );
  }

  factory ActivitySampleDTO.fromMap(Map<String, dynamic> map) {
    return ActivitySampleDTO(
      sampleID: map['sampleID'] as int?,
      activityID: map['activityID'] as String,
      timestampMs: map['timestamp_ms'] != null
          ? Duration(milliseconds: map['timestamp_ms'] as int)
          : null,

      heartRate: map['heartRate'] as int?,
      distance: (map['distance'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),
      pace: (map['pace'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      cadence: (map['cadence'] as num?)?.toDouble(),
      elevation: (map['elevation'] as num?)?.toDouble(),

      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'sampleID': sampleID,
      'activityID': activityID,
      'timestamp_ms': timestampMs?.inMilliseconds,

      'heartRate': heartRate,
      'distance': distance,
      'calories': calories,
      'pace': pace,
      'speed': speed,
      'cadence': cadence,
      'elevation': elevation,

      'latitude': latitude,
      'longitude': longitude,
    };
  }

  ActivitySample toDomain() {
    return ActivitySample(
      sampleID: sampleID,
      activityID: activityID,
      timestampMs: timestampMs,
      heartRate: heartRate,
      distance: distance,
      calories: calories,
      pace: pace,
      speed: speed,
      cadence: cadence,
      elevation: elevation,
      latitude: latitude,
      longitude: longitude,
    );
  }
}











class WalkActivitySampleDTO extends ActivitySampleDTO {
  final int? steps;

  WalkActivitySampleDTO({
    super.sampleID,
    required super.activityID,
    required super.timestampMs,
    super.heartRate,
    super.distance,
    super.calories,
    this.steps,
    super.pace,
    super.speed,
    super.cadence,
    super.elevation,
    super.latitude,
    super.longitude,
  });

  factory WalkActivitySampleDTO.fromDomain(
    WalkActivitySample sample,
  ) {
    return WalkActivitySampleDTO(
      sampleID: sample.sampleID,
      activityID: sample.activityID,
      timestampMs: sample.timestampMs,
      heartRate: sample.heartRate,
      distance: sample.distance,
      calories: sample.calories,
      steps: sample.steps,
      pace: sample.pace,
      speed: sample.speed,
      cadence: sample.cadence,
      elevation: sample.elevation,
      latitude: sample.latitude,
      longitude: sample.longitude,
    );
  }

  factory WalkActivitySampleDTO.fromMap(
    Map<String, dynamic> map,
  ) {
    return WalkActivitySampleDTO(
      sampleID: map['sampleID'] as int?,
      activityID: map['activityID'] as String,
      timestampMs: map['timestamp_ms'] != null
          ? Duration(milliseconds: map['timestamp_ms'] as int)
          : null,

      heartRate: map['heartRate'] as int?,
      distance: (map['distance'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),

      steps: map['steps'] as int?,

      pace: (map['pace'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      cadence: (map['cadence'] as num?)?.toDouble(),
      elevation: (map['elevation'] as num?)?.toDouble(),

      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'steps': steps,
    };
  }

  @override
  WalkActivitySample toDomain() {
    return WalkActivitySample(
      sampleID: sampleID,
      activityID: activityID,
      timestampMs: timestampMs,
      heartRate: heartRate,
      distance: distance,
      calories: calories,
      steps: steps,
      pace: pace,
      speed: speed,
      cadence: cadence,
      elevation: elevation,
      latitude: latitude,
      longitude: longitude,
    );
  }
}








class RunningActivitySampleDTO extends ActivitySampleDTO {
  RunningActivitySampleDTO({
    super.sampleID,
    required super.activityID,
    required super.timestampMs,
    super.heartRate,
    super.distance,
    super.calories,
    super.pace,
    super.speed,
    super.cadence,
    super.elevation,
    super.latitude,
    super.longitude,
  });

  factory RunningActivitySampleDTO.fromDomain(
    RunningActivitySample sample,
  ) {
    return RunningActivitySampleDTO(
      sampleID: sample.sampleID,
      activityID: sample.activityID,
      timestampMs: sample.timestampMs,
      heartRate: sample.heartRate,
      distance: sample.distance,
      calories: sample.calories,
      pace: sample.pace,
      speed: sample.speed,
      cadence: sample.cadence,
      elevation: sample.elevation,
      latitude: sample.latitude,
      longitude: sample.longitude,
    );
  }

  factory RunningActivitySampleDTO.fromMap(
    Map<String, dynamic> map,
  ) {
    return RunningActivitySampleDTO(
      sampleID: map['sampleID'] as int?,
      activityID: map['activityID'] as String,
      timestampMs: map['timestamp_ms'] != null
          ? Duration(milliseconds: map['timestamp_ms'] as int)
          : null,

      heartRate: map['heartRate'] as int?,
      distance: (map['distance'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),

      pace: (map['pace'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      cadence: (map['cadence'] as num?)?.toDouble(),
      elevation: (map['elevation'] as num?)?.toDouble(),

      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  // toMap() se hereda de ActivitySampleDTO: no hay columnas extra en
  // RunningActivitySample, así que no hace falta sobrescribirlo.

  @override
  RunningActivitySample toDomain() {
    return RunningActivitySample(
      sampleID: sampleID,
      activityID: activityID,
      timestampMs: timestampMs,
      heartRate: heartRate,
      distance: distance,
      calories: calories,
      pace: pace,
      speed: speed,
      cadence: cadence,
      elevation: elevation,
      latitude: latitude,
      longitude: longitude,
    );
  }
}







class CyclingActivitySampleDTO extends ActivitySampleDTO {
  CyclingActivitySampleDTO({
    super.sampleID,
    required super.activityID,
    required super.timestampMs,
    super.heartRate,
    super.distance,
    super.calories,
    super.pace,
    super.speed,
    super.cadence,
    super.elevation,
    super.latitude,
    super.longitude,
  });

  factory CyclingActivitySampleDTO.fromDomain(
    CyclingActivitySample sample,
  ) {
    return CyclingActivitySampleDTO(
      sampleID: sample.sampleID,
      activityID: sample.activityID,
      timestampMs: sample.timestampMs,
      heartRate: sample.heartRate,
      distance: sample.distance,
      calories: sample.calories,
      pace: sample.pace,
      speed: sample.speed,
      cadence: sample.cadence,
      elevation: sample.elevation,
      latitude: sample.latitude,
      longitude: sample.longitude,
    );
  }

  factory CyclingActivitySampleDTO.fromMap(
    Map<String, dynamic> map,
  ) {
    return CyclingActivitySampleDTO(
      sampleID: map['sampleID'] as int?,
      activityID: map['activityID'] as String,
      timestampMs: map['timestamp_ms'] != null
          ? Duration(milliseconds: map['timestamp_ms'] as int)
          : null,

      heartRate: map['heartRate'] as int?,
      distance: (map['distance'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),

      pace: (map['pace'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      cadence: (map['cadence'] as num?)?.toDouble(),
      elevation: (map['elevation'] as num?)?.toDouble(),

      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  CyclingActivitySample toDomain() {
    return CyclingActivitySample(
      sampleID: sampleID,
      activityID: activityID,
      timestampMs: timestampMs,
      heartRate: heartRate,
      distance: distance,
      calories: calories,
      pace: pace,
      speed: speed,
      cadence: cadence,
      elevation: elevation,
      latitude: latitude,
      longitude: longitude,
    );
  }
}