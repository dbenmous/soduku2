import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/screens/game.dart';
import 'package:flutter_sudoku/shared/localization.dart';

class LevelSelectSheet extends StatelessWidget {
  const LevelSelectSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Material( // Add Material widget for proper touch handling
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor, // Add background color
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              levelOption(context, 'Beginner'),
              thickDivider(),
              levelOption(context, 'Easy'),
              thickDivider(),
              levelOption(context, 'Medium'),
              thickDivider(),
              levelOption(context, 'Hard'),
              thickDivider(),
              levelOption(context, 'Expert'),
              thickDivider(),
              levelOption(context, 'Champion'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget levelOption(BuildContext context, String levelName) {
    String appLang = Hive.box('settings').get('language', defaultValue: 'EN');
    return InkWell( // Replace GestureDetector with InkWell
      onTap: () async {
        // Pop the bottom sheet first
        Navigator.of(context).pop();
        // Add a small delay to ensure smooth navigation
        await Future.delayed(const Duration(milliseconds: 50));
        // Check if context is still valid
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GamePage(difficulty: levelName, isPrevGame: false),
            ),
          );
        }
      },
      child: Container( // Wrap with Container for better touch area
        width: double.infinity, // Make sure it spans full width
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
        child: Center(
          child: Text(
            appText[appLang]![levelName.toLowerCase()]!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget thickDivider() {
    return const Divider(
      color: Colors.grey,
      thickness: 0.5,
      height: 1,
    );
  }
}