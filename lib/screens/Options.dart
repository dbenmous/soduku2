import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './settings.dart';
import './sound_manager.dart';
import './vibration_manager.dart';
import 'package:flutter_sudoku/shared/localization.dart';

class OptionsPage extends StatelessWidget {
const OptionsPage({super.key});

@override
Widget build(BuildContext context) {
String appLang = Hive.box('settings').get('language', defaultValue: 'EN');

return Scaffold(
backgroundColor: Colors.grey[50], // Very light grey background
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
appText[appLang]!['options'] ?? 'Options',
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.w600,
color: Colors.black87,
),
),
],
),
),
const SizedBox(height: 8),

// Options List
Container(
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
_buildOptionItem(
context,
icon: Iconsax.setting_2,
title: appText[appLang]!['settings'] ?? 'Settings',
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const SettingsPage(fromRoot: false),
),
);
},
showTopDivider: false,
),
_buildOptionItem(
context,
icon: Icons.privacy_tip_outlined,
title: appText[appLang]!['privacy'] ?? 'Privacy Policy',
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
// Navigate to Privacy Policy
},
),
_buildOptionItem(
context,
icon: Icons.rule_outlined,
title: appText[appLang]!['rules'] ?? 'Game Rules',
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
// Navigate to Rules
},
),
_buildOptionItem(
context,
icon: Icons.help_outline_rounded,
title: appText[appLang]!['how_to_play'] ?? 'How to Play',
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
// Navigate to How to Play
},
),
_buildOptionItem(
context,
icon: Icons.info_outline_rounded,
title: appText[appLang]!['about'] ?? 'About Game',
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
// Navigate to About
},
),
_buildOptionItem(
context,
icon: Icons.support_agent,
title: appText[appLang]!['help'] ?? 'Help & Support',
onTap: () async {
await SoundManager.playSound(SoundType.click);
await VibrationManager.vibrate();
// Navigate to Help
},
),
],
),
),
],
),
),
);
}

Widget _buildOptionItem(
BuildContext context, {
required IconData icon,
required String title,
required VoidCallback onTap,
bool showTopDivider = true,
}) {
return Column(
children: [
if (showTopDivider)
Divider(
height: 1,
color: Colors.grey[200],
indent: 16,
endIndent: 16,
),
InkWell(
onTap: onTap,
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
child: Row(
children: [
Icon(
icon,
size: 24,
color: Colors.blue.shade900,
),
const SizedBox(width: 16),
Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w500,
color: Colors.black87,
),
),
),
Icon(
Icons.chevron_right_rounded,
color: Colors.grey[400],
size: 24,
),
],
),
),
),
],
);
}
}
