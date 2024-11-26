import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/shared/localization.dart';

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.gameTime,
    required this.difficulty,
  });

  final String difficulty;
  final Duration gameTime;

  @override
  Widget build(BuildContext context) {
    String appLang = Hive.box('settings').get('language', defaultValue: 'EN');

    // Get best time for current difficulty
    String bestTime = Hive.box('settings').get(
        'best_time_${difficulty.toLowerCase()}',
        defaultValue: '00:00'
    );

    return ValueListenableBuilder(
      valueListenable:
      Hive.box('in_game_args').listenable(keys: ['time', 'mistakes']),
      builder: (context, value, child) {
        // Retrieve current time and mistakes
        String time = Hive.box('in_game_args').get('time', defaultValue: '0');
        int mistakes =
        Hive.box('in_game_args').get('mistakes', defaultValue: 0);

        // Parse time
        String min = time.split(':').first.padLeft(2, '0');
        String sec = time.split(':').last.padLeft(2, '0');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // All Time Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "All Time",
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 20,
                        color: Color(0xFF808080),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bestTime,  // Using the best time from storage
                        style: TextStyle(
                          color: Color(0xFF808080),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Difficulty Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Difficulty",
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appText[appLang]![difficulty.toLowerCase()]!,
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // Mistakes Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mistakes",
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: Hive.box('settings')
                        .listenable(keys: ['mistakesLimit']),
                    builder: (context, value, child) {
                      bool limit = Hive.box('settings')
                          .get('mistakesLimit', defaultValue: true);
                      return Text(
                        "${limit ? "$mistakes / 3" : "$mistakes"}",
                        style: TextStyle(
                          color: Color(0xFF808080),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Time Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Time",
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$min:$sec",
                    style: TextStyle(
                      color: Color(0xFF808080),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}