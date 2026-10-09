

import 'package:flutter/widgets.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/exercise_sample_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/excercise_usecases.dart';

class GetSamplesUseCase implements IGetSamplesUseCase{
  final IActivitySampleRepo activitySampleRepo;

  const GetSamplesUseCase(this.activitySampleRepo);

  @override
  Future<List<IActivitySample>?> execute(String activityID) async {

    debugPrint('gettind sample to db');
    final samples = await activitySampleRepo.getSamples(activityID);
    if(samples == null) return null;

    return samples;
  }
}