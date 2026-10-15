import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

final FlutterBackgroundService backgroundService = FlutterBackgroundService();

bool get isBackgroundServiceSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> initializeService() async {
  if (!isBackgroundServiceSupported) {
    debugPrint(
      'Background exercise service disabled on '
      '${kIsWeb ? 'web' : defaultTargetPlatform.name}.',
    );
    return;
  }

  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      autoStartOnBoot: false,
      initialNotificationTitle: 'Actividad',
      initialNotificationContent: 'Iniciando...',
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  bool isTracking = false;

  try {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('startTracking').listen((event) {
      isTracking = true;
    });

    service.on('pauseTracking').listen((event) {
      isTracking = false;
    });

    service.on('stopTracking').listen((event) {
      isTracking = false;
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Salud ULV",
            content: isTracking ? "Actividad en curso" : "Actividad en pausa",
          );
        }
      }

      debugPrint('Background service running');

      service.invoke('update', {'isTracking': isTracking});
    });
  } catch (e, st) {
    debugPrint('onStart error: $e\n$st');
  }
}

// ============================================================
// FUNCIONES PARA CONTROLAR EL SERVICIO DESDE LA APP
// ============================================================

Future<void> startBackgroundService() async {
  if (!isBackgroundServiceSupported) return;

  final service = FlutterBackgroundService();

  final isRunning = await service.isRunning();

  if (!isRunning) {
    await service.startService();
  }
}

void stopBackgroundService() {
  if (!isBackgroundServiceSupported) return;

  final service = FlutterBackgroundService();

  service.invoke('stopService');
}

void startExerciseTracking() {
  if (!isBackgroundServiceSupported) return;

  final service = FlutterBackgroundService();

  service.invoke('setAsForeground');
  service.invoke('startTracking');
}

void pauseExerciseTracking() {
  if (!isBackgroundServiceSupported) return;

  final service = FlutterBackgroundService();

  service.invoke('pauseTracking');
}

void stopExerciseTracking() {
  if (!isBackgroundServiceSupported) return;

  final service = FlutterBackgroundService();

  service.invoke('setAsBackground'); // demota una vez que termina el tracking

  service.invoke('stopTracking');
}

// ============================================================
// FINALIZAR EJERCICIO
// ============================================================

void finishExercise() {
  stopExerciseTracking();
  stopBackgroundService();
}
