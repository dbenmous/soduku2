import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_sudoku/screens/game.dart';
import 'package:flutter_sudoku/screens/settings.dart';
import 'package:flutter_sudoku/shared/localization.dart';
import 'package:flutter_sudoku/widgets/home_page/level_select.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //
  onTap(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return const LevelSelectSheet();
      },
    );
  }

  //
  @override
  Widget build(BuildContext context) {
    String appLang = Hive.box('settings').get('language', defaultValue: 'EN');
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                const SizedBox(height: 20),
                // TITLE
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appText[appLang]!['title']!,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 5,
                          color: Colors.black87.withOpacity(.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appText[appLang]!['subtitle']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                          color: Colors.blue.shade900.withOpacity(.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // RANDOM GAME SECTION
                Expanded(
                  flex: 3,
                  child: randomGameSection(appLang, context),
                ),
                // NEW GAME BUTTON
                Expanded(
                  flex: 1,
                  child: Center(
                    child: MaterialButton(
                      height: 50,
                      minWidth: 240,
                      onPressed: () {
                        onTap(context);
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      color: Colors.blue.shade800.withOpacity(.8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side:
                        BorderSide(color: Colors.grey.shade300, width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        appText[appLang]!['new_game']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            // Floating Button in Top-Right
            Positioned(
              top: 15,
              right: 15,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(fromRoot: true),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                elevation: 10,
                child: const Icon(
                  Icons.settings,
                  size: 22,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget randomGameSection(String appLang, BuildContext context) {
    return Center(
      child: Container(
        height: 205,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 6,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                appText[appLang]!['random_game']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87.withOpacity(.8),
                ),
              ),
              Icon(
                Iconsax.calendar_1,
                size: 64,
                color: Colors.black87.withOpacity(.75),
              ),
              MaterialButton(
                height: 40,
                minWidth: 100,
                onPressed: () {
                  List<String> levels = [
                    'Beginner',
                    'Easy',
                    'Medium',
                    'Hard',
                    'Expert',
                    'Champion',
                  ];
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GamePage(
                        difficulty: (levels..shuffle()).first,
                        isPrevGame: false,
                      ),
                    ),
                  );
                },
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                color: Colors.grey.shade200,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  appText[appLang]!['play']!,
                  style: TextStyle(
                    color: Colors.black87.withOpacity(.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
