import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/screens/game.dart';
import 'package:flutter_sudoku/shared/localization.dart';

class LevelSelectSheet extends StatelessWidget {
  const LevelSelectSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), // Transparent space
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // Box color
          borderRadius: BorderRadius.circular(16), // Uniform corner radius
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16), // Padding at the top
            levelOption(context, 'Beginner'),
            thickDivider(), // Thicker grey line
            levelOption(context, 'Easy'),
            thickDivider(),
            levelOption(context, 'Medium'),
            thickDivider(),
            levelOption(context, 'Hard'),
            thickDivider(),
            levelOption(context, 'Expert'),
            thickDivider(),
            levelOption(context, 'Champion'),
            const SizedBox(height: 16), // Padding at the bottom
          ],
        ),
      ),
    );
  }

  Widget levelOption(BuildContext context, String levelName) {
    String appLang = Hive.box('settings').get('language', defaultValue: 'EN');
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GamePage(difficulty: levelName, isPrevGame: false),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
        child: Center(
          child: Text(
            appText[appLang]![levelName.toLowerCase()]!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.blue, // Text color blue
            ),
          ),
        ),
      ),
    );
  }

  Widget thickDivider() {
    return const Divider(
      color: Colors.grey,
      thickness: 0.5, // Thicker separator line
      height: 1,
    );
  }
}
