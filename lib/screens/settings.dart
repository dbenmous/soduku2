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
backgroundColor: Colors.grey[50],
body: SafeArea(
child: Column(
children: [
// Header
Padding(
padding: const EdgeInsets.all(16.0),
child: Row(
children: [
GestureDetector(
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
Navigator.of(context).pop();
},
child: Container(
padding: const EdgeInsets.all(8),
child: Icon(
Icons.arrow_back_ios_new_rounded,
color: Colors.blue.shade900,
size: 24,
),
),
),
const SizedBox(width: 16),
Text(
appText[appLang]!['settings']!,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.w600,
color: Colors.black87,
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
),
const SizedBox(height: 8),

// Settings List
Expanded(
child: ValueListenableBuilder(
valueListenable: Hive.box('settings').listenable(),
builder: (context, value, child) {
return SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
child: Container(
margin: const EdgeInsets.symmetric(horizontal: 16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 2),
),
],
),
child: Column(
children: [
SettingsCard(
icon: Iconsax.audio_square,
text: appText[appLang]!['audio']!,
settName: 'audio',
defaultValue: false,
hasSlider: true,
showTopDivider: false,
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
),
);
},
),
),
],
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
this.showTopDivider = true,
});

final String text;
final IconData icon;
final String settName;
final bool defaultValue;
final bool hasSlider;
final bool showTopDivider;

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

return Column(
children: [
if (widget.showTopDivider)
Divider(
height: 1,
color: Colors.grey[200],
indent: 16,
endIndent: 16,
),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(
widget.icon,
size: 24,
color: Colors.blue.shade900,
),
const SizedBox(width: 16),
Expanded(
child: Text(
widget.text,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w500,
color: Colors.black87,
),
),
),
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
padding: const EdgeInsets.only(top: 16, left: 40),
child: Row(
children: [
Icon(
Icons.volume_down,
size: 20,
color: Colors.grey.shade600,
),
Expanded(
child: SliderTheme(
data: SliderThemeData(
activeTrackColor: Colors.blue.shade900,
thumbColor: Colors.blue.shade900,
overlayColor: Colors.blue.shade900.withOpacity(0.1),
),
child: Slider(
value: volume,
onChanged: (newValue) async {
setState(() {
Hive.box('settings').put('volume', newValue);
});
await SoundManager.testSound();
},
),
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
padding: const EdgeInsets.only(top: 8, left: 40),
child: Text(
widget.settName == 'audio'
? appText[appLang]!['audio_descr'] ?? 'Enable sound effects and adjust volume'
    : widget.settName == 'vibration'
? appText[appLang]!['vibration_descr'] ?? 'Enable haptic feedback'
    : appText[appLang]!['${widget.settName}_descr']!,
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade600,
),
),
),
],
),
),
],
);
}
}
