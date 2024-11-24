import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/screens/settings.dart';
import 'package:flutter_sudoku/shared/localization.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  //
  late Box sudokuBox;
  late List sudokus;

  late String bestTime;
  late int perfectGameCount;

  Map<String, List> mappedSudokus = {
    'Beginner': [],
    'Easy': [],
    'Medium': [],
    'Hard': [],
    'Expert': [],
    'Champion': [],
  };

  String selectedCategory = 'Beginner';
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    sudokuBox = Hive.box('prev_sudokus');
    sudokus = sudokuBox.values.toList();

    for (var item in sudokus) {
      String difficulty = item['difficulty'];
      mappedSudokus[difficulty]!.add(item);
    }

    bestTime = _getBestTimeForCategory(selectedCategory);
    perfectGameCount = _getPerfectGameCountForCategory(selectedCategory);
  }

  String _getBestTimeForCategory(String category) {
    if (mappedSudokus[category]!.isEmpty) return '--:--';
    String best = mappedSudokus[category]!.first['duration'];
    for (var item in mappedSudokus[category]!) {
      if (item['duration'].compareTo(best) < 0) {
        best = item['duration'];
      }
    }
    return best;
  }

  int _getPerfectGameCountForCategory(String category) {
    int count = 0;
    for (var item in mappedSudokus[category]!) {
      if (item['perfectGame'].compareTo('true') == 0) {
        ++count;
      }
    }
    return count;
  }

  void onTap(int index) {
    setState(() {
      selectedIndex = index;
      selectedCategory = mappedSudokus.keys.elementAt(index);
      bestTime = _getBestTimeForCategory(selectedCategory);
      perfectGameCount = _getPerfectGameCountForCategory(selectedCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(keys: ['language']),
      builder: (context, value, child) {
        final String appLang =
        Hive.box('settings').get('language', defaultValue: 'EN');
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.stacked_bar_chart_sharp,
                        size: 96,
                        color: Colors.black87.withOpacity(.8),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          appText[appLang]!['statistics']!,
                          style: const TextStyle(
                            fontSize: 32,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSlidableLevels(appLang),
                      const SizedBox(height: 20),
                      CardSection(
                        size: 34,
                        text: appText[appLang]!['games_completed']!,
                        data: mappedSudokus[selectedCategory]!.length.toString(),
                        icon: Icons.playlist_add_check_circle_outlined,
                      ),
                      const SizedBox(height: 20),
                      CardSection(
                        size: 36,
                        text: appText[appLang]!['perfect_wins']!,
                        data: perfectGameCount.toString(),
                        icon: Icons.star_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      CardSection(
                        size: 34,
                        text: appText[appLang]!['best_time']!,
                        data: bestTime,
                        icon: Icons.timer_outlined,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                // Floating Action Button Positioned at the bottom-right
                Positioned(
                  bottom: 20,
                  right: 20,
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
                      size: 32,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildSlidableLevels(String appLang) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: mappedSudokus.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 10);
        },
        itemBuilder: (context, index) {
          return Container(
            decoration: selectedIndex == index
                ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 3,
                  color: Colors.black87,
                ),
              ),
            )
                : null,
            child: TextButton(
              onPressed: () {
                onTap(index);
              },
              child: Text(
                appText[appLang]![
                mappedSudokus.keys.elementAt(index).toLowerCase()]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  selectedIndex == index ? FontWeight.w700 : FontWeight.w500,
                  color: selectedIndex == index
                      ? Colors.black87.withOpacity(.8)
                      : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardSection extends StatelessWidget {
  const CardSection({
    super.key,
    required this.text,
    required this.data,
    required this.icon,
    required this.size,
  });

  final double size;
  final String text;
  final String data;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Row(children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(
                icon,
                color: Colors.black87.withOpacity(.8),
                size: size,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 21,
              color: Colors.black54.withOpacity(.9),
            ),
          ),
          Expanded(child: Container()),
          Text(
            data,
            style: TextStyle(
              fontSize: 32,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: Colors.black87.withOpacity(.8),
            ),
          ),
        ]),
      ),
    );
  }
}
