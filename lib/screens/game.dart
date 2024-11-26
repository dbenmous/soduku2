import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sudoku/screens/home.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/utils/sudoku.dart';
import 'package:flutter_sudoku/widgets/game/board.dart';
import 'package:flutter_sudoku/widgets/game/upper_bar.dart';
import 'package:flutter_sudoku/widgets/game/info_section.dart';
import 'package:flutter_sudoku/widgets/game/numeric_button.dart';
import 'package:flutter_sudoku/widgets/game/functional_buttons.dart';

import 'package:flutter_sudoku/shared/localization.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.difficulty,
    required this.isPrevGame,
  });

  final bool isPrevGame;
  final String difficulty;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  String appLang = Hive.box('settings').get('language', defaultValue: 'EN');
  late Box sudokuBox;
  List<MapEntry<String, String>> history = [];
  Map<int, int> remainingValues = {};
  late List<List<SudokuCell>> sudoku;

  late Timer timer;
  Duration gameTime = const Duration();

  void setInGameValues() {
    sudokuBox.clear();

    history.clear();
    remainingValues.clear();
    sudoku = SudokuProvider.makeNewSudoku(difficulty: widget.difficulty);

    for (int i = 0; i < 9; i++) {
      remainingValues[i + 1] = 9;
    }
    for (var line in sudoku) {
      for (var item in line) {
        if (item.isCompleted) {
          remainingValues[item.actualValue] =
          (remainingValues[item.actualValue]! - 1);
        }
      }
    }
  }

  void checkAndUpdateBestTime(String currentTime) {
    var settingsBox = Hive.box('settings');
    String bestTime = settingsBox.get(
        'best_time_${widget.difficulty.toLowerCase()}',
        defaultValue: '99:99'
    );

    int currentSeconds = _convertTimeToSeconds(currentTime);
    int bestSeconds = _convertTimeToSeconds(bestTime);

    if (currentSeconds < bestSeconds) {
      settingsBox.put('best_time_${widget.difficulty.toLowerCase()}', currentTime);
      showNewBestTimeDialog(context, currentTime);
    }
  }

  int _convertTimeToSeconds(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void showNewBestTimeDialog(BuildContext context, String newBestTime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
            ),
            title: Center(
              child: Text(
                appText[appLang]!['new_best_time'] ?? 'New Best Time!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  color: Colors.black87.withOpacity(.8),
                ),
              ),
            ),
            content: Text(
              newBestTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blue.shade900.withOpacity(.7),
                    ),
                    height: 40,
                    child: Text(
                      appText[appLang]!['ok'] ?? 'OK',
                      style: const TextStyle(
                        fontFamily: 'f',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    sudokuBox = Hive.box('in_game_args');
    sudokuBox.clear();

    setInGameValues();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) async {
        await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return landingScreen(
                context,
                appText[appLang]!['title']!,
                appText[appLang]!['subtitle']!,
                appText[appLang]!['start_game']!,
                appText[appLang]!['difficulty']!,
                appText[appLang]![widget.difficulty.toLowerCase()]!);
          },
        );
      },
    );

    WakelockPlus.enable();
  }

  @override
  void dispose() {
    timer.cancel();
    sudokuBox.clear();
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        if (timer.isActive) stopTimer();
        showPauseDialog(context, widget.difficulty);
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 2),
            UpperBar(
              name: widget.difficulty,
              moveBackButton: () {
                stopTimer();
              },
              pauseDialog: () {
                showPauseDialog(context, widget.difficulty);
              },
            ),
            const SizedBox(height: 0),
            InfoSection(
              gameTime: gameTime,
              difficulty: widget.difficulty,
            ),
            const SizedBox(height: 2),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: GameBoard(
                  sudoku: sudoku,
                  history: history,
                  sudokuBox: sudokuBox,
                  remainingValues: remainingValues,
                  checkSudokuCompleted: checkSudokuCompleted,
                ),
              ),
            ),
            const SizedBox(height: 0), // Reduced space before buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // Match InfoSection padding
              child: FunctionalButtons(
                sudoku: sudoku,
                history: history,
                remainingValues: remainingValues,
                checkSudokuCompleted: checkSudokuCompleted,
              ),
            ),
            const SizedBox(height: 26), // Reduced space after buttons
            Expanded(
              flex: 2,
              child: numericSection(width),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget numericSection(double width) {
    return ValueListenableBuilder(
      valueListenable: sudokuBox.listenable(keys: [
        'penMode',
        'fastMode',
        'remainingVals',
        'fastModeValue',
        'highlightValue',
      ]),
      builder: (context, value, child) {
        bool penActivated =
        sudokuBox.get('penMode', defaultValue: false);
        bool fastModeActivated =
        sudokuBox.get('fastMode', defaultValue: true);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width / 30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i in remainingValues.entries
                      .where((element) => element.value != 0)
                      .toList())
                    NumericButton(
                      num: i.key,
                      sudoku: sudoku,
                      history: history,
                      gameTime: gameTime,
                      penActivated: penActivated,
                      difficulty: widget.difficulty,
                      remainingValues: remainingValues,
                      checkSudokuCompleted: checkSudokuCompleted,
                    )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void startTimer({bool restrart = false}) {
    if (restrart) {
      sudokuBox.put('time', '0:0');
      resetTimer();
    }
    timer = Timer.periodic(const Duration(seconds: 1), (_) => addTime());
  }

  void stopTimer() => timer.cancel();

  void resetTimer() => gameTime = const Duration();

  void addTime() {
    gameTime = Duration(seconds: gameTime.inSeconds + 1);
    updateTimer();
  }

  void updateTimer() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String min = twoDigits(gameTime.inMinutes);
    String sec = twoDigits(gameTime.inSeconds.remainder(60));

    sudokuBox.put('time', '$min:$sec');
  }

  void checkSudokuCompleted() {
    bool completed = sudoku.expand((e) => e).toList().every(
          (element) => element.isCompleted,
    );

    if (completed) {
      stopTimer();
      String currentTime = '${gameTime.inMinutes.toString().padLeft(2, '0')}:${gameTime.inSeconds.remainder(60).toString().padLeft(2, '0')}';
      checkAndUpdateBestTime(currentTime);
      showSudokuCompletedDialog(context, widget.difficulty);
    }

    if (Hive.box('settings').get('mistakesLimit', defaultValue: true)) {
      if (sudokuBox.get('mistakes', defaultValue: 0) >= 3) {
        showSudokuFailedDialog(context);
      }
    }
  }

  void endOfGame() {
    Box prevSudokus = Hive.box('prev_sudokus');

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String min = twoDigits(gameTime.inMinutes);
    String sec = twoDigits(gameTime.inSeconds.remainder(60));
    DateTime date = DateTime.now();

    int totMistakes = sudokuBox.get('mistakes', defaultValue: 0);
    int totHint = sudokuBox.get('hintCount', defaultValue: 0);

    bool perfectGame = totMistakes == 0 && totHint == 0;

    Map<String, String> stats = {
      'difficulty': widget.difficulty,
      'perfectGame': perfectGame.toString(),
      'date': '${date.day}/${date.month}/${date.year}',
      'time': '${twoDigits(date.hour)}:${twoDigits(date.minute)}',
      'duration': '$min:$sec',
    };

    prevSudokus.add(stats);

    // First navigate to home page and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
          (route) => false,
    );
  }

  void showPauseDialog(BuildContext context, String difficulty) {
    if (timer.isActive) stopTimer();

    String time = sudokuBox.get('time', defaultValue: '0');
    String min = time.split(':').first.padLeft(2, '0');
    String sec = time.split(':').last.padLeft(2, '0');

    GestureDetector resumeButton = GestureDetector(
      onTap: () {
        if (!timer.isActive) {
          startTimer();
        }
        Navigator.of(context).pop();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue.shade900.withOpacity(.7),
        ),
        height: 40,
        child: Text(
          appText[appLang]!['resume']!,
          style: const TextStyle(
            fontFamily: 'f',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );

    GestureDetector restartButton = GestureDetector(
      onTap: () {
        setState(() {
          setInGameValues();
        });
        resetTimer();
        startTimer();
        Navigator.of(context).pop();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue.shade900.withOpacity(.7),
        ),
        height: 40,
        child: Text(
          appText[appLang]!['restart']!,
          style: const TextStyle(
            fontFamily: 'f',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );

    BackdropFilter dialog = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
    ),
    title: Center(
    child: Text(
    appText[appLang]!['paused']!,
    style: TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 3,
    color: Colors.black87.withOpacity(.8),
    ),
    ),
    ),
    content: SizedBox(
    height: 90,
    child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Column(
    children: [
    Text(appText[appLang]!['time']!,
        style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 10),
      Text(
        '$min:$sec',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.black87.withOpacity(.8),
        ),
      ),
      ],
    ),
      Expanded(child: Column()),
      Column(
        children: [
          Text(appText[appLang]!['difficulty']!,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Text(
            appText[appLang]![difficulty.toLowerCase()]!,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black87.withOpacity(.8),
            ),
          ),
        ],
      ),
      ],
    ),
    ),
        ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              resumeButton,
              const SizedBox(height: 10),
              restartButton,
            ],
          ),
        )
      ],
    ),
    );

    showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
    return dialog;
    },
    );
  }

  void showSudokuCompletedDialog(BuildContext context, String difficulty) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String min = twoDigits(gameTime.inMinutes);
    String sec = twoDigits(gameTime.inSeconds.remainder(60));

    GestureDetector homeButton = GestureDetector(
      onTap: () {
        endOfGame();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue.shade900.withOpacity(.7),
        ),
        height: 40,
        child: Text(
          appText[appLang]!['home']!,
          style: const TextStyle(
            fontFamily: 'f',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );

    BackdropFilter dialog = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        title: Center(
          child: Text(
            appText[appLang]!['completed']!,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: Colors.black87.withOpacity(.8),
            ),
          ),
        ),
        content: SizedBox(
          height: 90,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(appText[appLang]!['time']!,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(
                      '$min:$sec',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87.withOpacity(.8),
                      ),
                    ),
                  ],
                ),
                Expanded(child: Column()),
                Column(
                  children: [
                    Text(appText[appLang]!['difficulty']!,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(
                      appText[appLang]![difficulty.toLowerCase()]!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87.withOpacity(.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: homeButton,
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }

  void showSudokuFailedDialog(BuildContext context) {
    BackdropFilter dialog = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              appText[appLang]!['title']!,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: Colors.black87.withOpacity(.7),
              ),
            ),
            Text(
              appText[appLang]!['subtitle']!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        content: SizedBox(
          height: 90,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Center(
              child: Text(
                appText[appLang]!['failed']!,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                      (route) => false,
                );
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.blue.shade900.withOpacity(.8),
                ),
                height: 40,
                child: Text(
                  appText[appLang]!['home']!,
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 2,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }

  Widget landingScreen(BuildContext context, String title, String subtitle,
      String strtGme, String diffText, String difficulty) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: Colors.black87.withOpacity(.7),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        content: SizedBox(
          height: 90,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                Text(
                  diffText,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  difficulty,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87.withOpacity(.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.isPrevGame) {
                      startTimer(restrart: true);
                    } else {
                      startTimer();
                    }
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blue.shade900.withOpacity(.8),
                    ),
                    height: 40,
                    child: Text(
                      strtGme,
                      style: const TextStyle(
                        fontSize: 18,
                        letterSpacing: 2,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}