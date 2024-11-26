import 'package:vibration/vibration.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum VibrationPattern {
light,
medium,
heavy,
error,
success
}

class VibrationManager {
static bool? _hasVibrator;

static Future<void> initialize() async {
_hasVibrator = await Vibration.hasVibrator();
}

static Future<void> vibrate({VibrationPattern pattern = VibrationPattern.light}) async {
if (!Hive.box('settings').get('vibration', defaultValue: false)) return;

if (_hasVibrator ?? false) {
switch (pattern) {
case VibrationPattern.light:
Vibration.vibrate(duration: 50);
break;
case VibrationPattern.medium:
Vibration.vibrate(duration: 100);
break;
case VibrationPattern.heavy:
Vibration.vibrate(duration: 200);
break;
case VibrationPattern.error:
Vibration.vibrate(pattern: [0, 50, 100, 50]);
break;
case VibrationPattern.success:
Vibration.vibrate(pattern: [0, 50, 50, 50]);
break;
}
}
}

static Future<bool> isAvailable() async {
if (_hasVibrator == null) {
await initialize();
}
return _hasVibrator ?? false;
}

static Future<void> testVibration() async {
await vibrate(pattern: VibrationPattern.medium);
}
}
