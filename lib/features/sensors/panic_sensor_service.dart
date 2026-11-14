import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/app_constants.dart';

class PanicSensorService {
  static StreamSubscription<AccelerometerEvent>? _accelSub;
  static DateTime _lastShakeTime = DateTime.now();
  static bool _isFaceDown = false;

  static void startListening({required Function() onPanicTriggered}) {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      final double x = event.x;
      final double y = event.y;
      final double z = event.z;

      // 1. Detection: Flip Face-Down on desk (Z-axis deeply negative)
      // When screen is facing flat on desk, gravity points down through the screen (z ≈ -9.8 m/s²)
      if (z < -7.5) {
        if (!_isFaceDown) {
          _isFaceDown = true;
          onPanicTriggered();
        }
      } else {
        _isFaceDown = false;
      }

      // 2. Detection: Rapid Double-Shake Gesture
      final double gMagnitude = sqrt(x * x + y * y + z * z) - 9.8; // remove gravity
      if (gMagnitude > AppConstants.shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds < 600 &&
            now.difference(_lastShakeTime).inMilliseconds > 150) {
          // Double shake registered
          onPanicTriggered();
        }
        _lastShakeTime = now;
      }
    });
  }

  static void stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
  }
}
