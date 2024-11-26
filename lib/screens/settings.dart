import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './sound_manager.dart';
import './vibration_manager.dart';
import 'package:flutter_sudoku/shared/localization.dart';

class SettingsPage extends StatefulWidget {
const SettingsPage({super.key, required this.fromRoot});

final bool fromRoot;

@override
State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
@override
void initState() {
super.initState();
_initializeManagers();
}

Future<void> _initializeManagers() async {
await SoundManager.initialize();
await VibrationManager.initialize();
}

@override
Widget build(BuildContext context) {
String appLang = Hive.box('settings').get('language', defaultValue: 'EN');
return Scaffold(
body: SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
child: Column(
children: [
Row(
children: [
GestureDetector(
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
Navigator.of(context).pop();
},
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
child: Icon(
size: 26,
Icons.arrow_back_ios_new_rounded,
color: Colors.black87.withOpacity(.75),
),
),
),
const SizedBox(width: 20),
Text(
appText[appLang]!['settings']!,
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.w600,
color: Colors.black87.withOpacity(.8),
),
),
Expanded(child: Container()),
if (widget.fromRoot)
Padding(
padding: const EdgeInsets.all(8.0),
child: GestureDetector(
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();

String currentLang = Hive.box('settings')
    .get('language', defaultValue: 'EN');
String newLang = currentLang == 'EN' ? 'TR' : 'EN';
Hive.box('settings').put('language', newLang);
setState(() {});
},
child: SizedBox(
width: 48,
height: 48,
child: Image.asset('assets/language_$appLang.png'),
),
),
),
],
),
const SizedBox(height: 30),
Expanded(
child: ValueListenableBuilder(
valueListenable: Hive.box('settings').listenable(),
builder: (context, value, child) {
return SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
child: Column(
children: [
SettingsCard(
icon: Iconsax.audio_square,
text: appText[appLang]!['audio']!,
settName: 'audio',
defaultValue: false,
hasSlider: true,
),
SettingsCard(
text: appText[appLang]!['vibration']!,
icon: Icons.vibration_rounded,
settName: 'vibration',
defaultValue: false,
hasSlider: false,
),
SettingsCard(
text: appText[appLang]!['hint_limit']!,
icon: Icons.lightbulb_outline,
settName: 'hintLimit',
defaultValue: true,
hasSlider: false,
),
SettingsCard(
text: appText[appLang]!['mistake_limit']!,
icon: Icons.highlight_off_sharp,
settName: 'mistakesLimit',
defaultValue: true,
hasSlider: false,
),
SettingsCard(
text: appText[appLang]!['region_high']!,
icon: Icons.games_rounded,
settName: 'regHigh',
defaultValue: true,
hasSlider: false,
),
SettingsCard(
text: appText[appLang]!['number_high']!,
icon: Icons.numbers_outlined,
settName: 'numHigh',
defaultValue: true,
hasSlider: false,
),
],
),
);
},
),
),
],
),
),
),
);
}
}

class SettingsCard extends StatefulWidget {
const SettingsCard({
super.key,
required this.text,
required this.icon,
required this.settName,
required this.defaultValue,
required this.hasSlider,
});

final String text;
final IconData icon;
final String settName;
final bool defaultValue;
final bool hasSlider;

@override
State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
@override
void initState() {
super.initState();
_initializeFeature();
}

Future<void> _initializeFeature() async {
if (widget.settName == 'vibration') {
bool hasVibrator = await VibrationManager.isAvailable();
if (!hasVibrator) {
Hive.box('settings').put(widget.settName, false);
}
}
}

@override
Widget build(BuildContext context) {
bool value = Hive.box('settings').get(widget.settName, defaultValue: widget.defaultValue);
double volume = Hive.box('settings').get('volume', defaultValue: 0.5);
String appLang = Hive.box('settings').get('language', defaultValue: 'EN');

return Padding(
padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(8),
border: Border.all(color: Colors.grey.shade400, width: 1),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(
widget.icon,
color: Colors.black87.withOpacity(.8),
size: 32,
),
const SizedBox(width: 15),
Text(
widget.text,
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w500,
color: Colors.black54.withOpacity(.8),
),
),
Expanded(child: Container()),
Switch(
value: value,
onChanged: (newValue) async {
if (widget.settName == 'vibration' && !await VibrationManager.isAvailable()) {
return;
}

setState(() {
value = newValue;
Hive.box('settings').put(widget.settName, value);
});

if (newValue) {
if (widget.settName == 'vibration') {
await VibrationManager.testVibration();
} else if (widget.settName == 'audio') {
await SoundManager.testSound();
}
}
},
),
],
),
if (widget.hasSlider && value)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Row(
children: [
Icon(
Icons.volume_down,
size: 20,
color: Colors.grey.shade600,
),
Expanded(
child: Slider(
value: volume,
onChanged: (newValue) async {
setState(() {
Hive.box('settings').put('volume', newValue);
});
// Play test sound when adjusting volume
await SoundManager.testSound();
},
activeColor: Colors.blue.shade900,
),
),
Icon(
Icons.volume_up,
size: 20,
color: Colors.grey.shade600,
),
],
),
),
Padding(
padding: const EdgeInsets.only(
left: 16,
right: 16,
top: 10,
bottom: 6,
),
child: Text(
widget.settName == 'audio'
? appText[appLang]!['audio_descr'] ?? 'Enable sound effects and adjust volume'
    : widget.settName == 'vibration'
? appText[appLang]!['vibration_descr'] ?? 'Enable haptic feedback'
    : appText[appLang]!['${widget.settName}_descr']!,
maxLines: 5,
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade700,
),
),
),
],
),
),
);
}
}
