import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/data/DTOs/exercise_dto.dart';

class CyclingDTO extends AerobicsDTO {
  final double? speed;
  final double? avgSpeed;
  final double? avgElevation;

  CyclingDTO({
    required super.activityID,
    required super.userUUID,
    required super.category,
    required super.duration,
    required super.caloriesBurned,
    required super.registeredAt,
    required super.distance,
    required super.avgPace,
    required super.elevationGain,
    required super.avgCadence,
    super.heartRate,
    required this.avgElevation,
    required this.speed,
    required this.avgSpeed,
  });

  factory CyclingDTO.fromDomain(Cycling activity) {
    return CyclingDTO(
      activityID: activity.activityID,
      userUUID: activity.userUUID,
      category: activity.category,
      duration: activity.duration,
      caloriesBurned: activity.caloriesBurned,
      registeredAt: activity.registeredAt,
      distance: activity.distance,
      avgPace: activity.avgPace,
      elevationGain: activity.elevationGain,
      avgCadence: activity.avgCadence,
      heartRate: activity.heartRate,
      avgElevation: activity.avgElevation,
      speed: activity.speed,
      avgSpeed: activity.avgSpeed,
    );
  }

  factory CyclingDTO.fromMap(Map<String, dynamic> map) {
    return CyclingDTO(
      activityID: map['activityID'] as String?,
      userUUID: map['userUUID'] as String?,
      category: map['categoryID'] as int?,
      duration: Duration(milliseconds: (map['duration_ms'] as int?) ?? 0),
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0,
      registeredAt: map['registeredAt'] != null
          ? DateTime.parse(map['registeredAt'] as String).toLocal()
          : DateTime.now(),

      distance: (map['distance'] as num?)?.toDouble() ?? 0,
      avgPace: (map['avgPace'] as num?)?.toDouble() ?? 0,
      elevationGain: (map['elevationGain'] as num?)?.toDouble() ?? 0,
      avgCadence: (map['avgCadence'] as num?)?.toDouble() ?? 0,
      heartRate: (map['heartRate'] as num?)?.toDouble() ?? 0,

      // Columna: avgElevationGain -> Campo: avgElevation
      avgElevation: (map['avgElevationGain'] as num?)?.toDouble() ?? 0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0,
      avgSpeed: (map['avgSpeed'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'avgElevationGain': avgElevation,
      'speed': speed,
      'avgSpeed': avgSpeed,
    };
  }

  Map<String, dynamic> toMapFields() {
    return {
      'duration_ms': duration?.inMilliseconds,
      'caloriesBurned': caloriesBurned,
      'registeredAt': registeredAt?.toIso8601String(),

      'distance': distance,
      'avgPace': avgPace,
      'elevationGain': elevationGain,
      'avgElevationGain': avgElevation,
      'avgCadence': avgCadence,
      'heartRate': heartRate,

      'speed': speed,
      'avgSpeed': avgSpeed,
    };
  }

  Cycling toDomain() {
    return Cycling(
      activityID: activityID,
      userUUID: userUUID,
      category: category,
      duration: duration,
      caloriesBurned: caloriesBurned,
      registeredAt: registeredAt,
      distance: distance,
      avgPace: avgPace,
      elevationGain: elevationGain,
      avgCadence: avgCadence,
      avgElevation: avgElevation,
      speed: speed,
      avgSpeed: avgSpeed,
    );
  }
}