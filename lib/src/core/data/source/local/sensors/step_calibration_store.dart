import 'package:shared_preferences/shared_preferences.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';

class StepCalibrationStore implements IStepCalibrationRepo {
  const StepCalibrationStore();

  static const _keyPrefix = 'walking_step_length_meters_';

  @override
  Future<double?> loadStepLengthMeters(String userUUID) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getDouble('$_keyPrefix$userUUID');
  }

  @override
  Future<void> saveStepLengthMeters(String userUUID, double meters) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble('$_keyPrefix$userUUID', meters);
  }
}
