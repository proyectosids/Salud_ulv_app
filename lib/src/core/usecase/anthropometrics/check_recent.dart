import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/anthro_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/anthropometric_usecase.dart';

class CheckRecentAnthroUseCase implements ICheckRecentAnthroUseCase {
  final IAnthropometricLocalRepo anthroRepo;
  final ICurrentUserSession currentUserSession;
  final IMemberLocalRepo memberLocalRepo;

  const CheckRecentAnthroUseCase(
    this.anthroRepo,
    this.currentUserSession,
    this.memberLocalRepo,
  );

  // @override
  // Future<(Map<String, ({num max, num min})>?, Map<String, num>?)> execute() async {
  @override
  Future<(Map<String, ({num max, num min})>?, Map<String, num>?)>
  execute() async {
    Map<String, ({num max, num min})> ranges;

    const Map<String, ({num max, num min})> anthroNormalValuesMen = {
      // 'Peso': (min: 50, max: 150),
      'Masa Músculo Esquelética': (min: 33, max: 40),
      'Masa grasa': (min: 1, max: 10),
      'Porcentaje grasa': (min: 8, max: 24),
      'IMC': (min: 20, max: 30),
      'ICC': (min: 0.75, max: 0.93),
    };

    const Map<String, ({num max, num min})> anthroNormalValuesWomen = {
      // 'Peso': (min: 50, max: 150),
      'Masa Músculo Esquelética': (min: 24, max: 30),
      'Masa grasa': (min: 1, max: 10),
      'Porcentaje grasa': (min: 21, max: 31),
      'IMC': (min: 18.5, max: 30),
      'ICC': (min: 0.55, max: 0.85),
    };
    debugPrint('inside usecase');

    final userUUID = await currentUserSession.getCurrentUserUUID();
    if (userUUID == null) return (null, null);
    final gender = await memberLocalRepo.getGender(userUUID);
    // if(gender == null) return (null, null);

    if (gender == 'male' || gender == null) {
      ranges = anthroNormalValuesMen;
    } else {
      ranges = anthroNormalValuesWomen;
    }

    final anthroData = await anthroRepo.getRecent(userUUID);
    debugPrint(anthroData.toString());
    if (anthroData == null) return (null, null);

    final Map<String, num> dataMap = {
      // 'Peso': anthroData.weight,
      'Masa Músculo Esquelética': anthroData.smm,
      'Masa grasa': anthroData.fatMass,
      'Porcentaje grasa': anthroData.bodyFatPercentage,
      'IMC': anthroData.bmi,
      'ICC': anthroData.whr,
    };
    debugPrint(dataMap.toString());

    final Map<String, num> alertValues = {};

    for (final entry in dataMap.entries) {
      final field = entry.key;
      final value = entry.value;

      debugPrint(field);
      debugPrint(value.toString());

      final range = ranges[field];
      debugPrint(range.toString());

      if (range == null) continue;

      if (value < range.min || value > range.max) {
        alertValues[field] = value;
        debugPrint(alertValues.toString());
        //   ranges[field] = range;
        // debugPrint(range.toString());
      }
    }

    debugPrint('outside loop');
    debugPrint(ranges.toString());
    debugPrint(alertValues.toString());

    return (ranges, alertValues);
  }
}
