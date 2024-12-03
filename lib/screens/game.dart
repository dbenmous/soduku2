import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sudoku/screens/home.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter_sudoku/utils/sudoku.dart';
import 'package:flutter_sudoku/widgets/game/board.dart';
import 'package:flutter_sudoku/widgets/game/upper_bar.dart';
import 'package:flutter_sudoku/widgets/game/info_section.dart';
import 'package:flutter_sudoku/widgets/game/numeric_button.dart';
import 'package:flutter_sudoku/widgets/game/functional_buttons.dart';
import 'package:confetti/confetti.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  late ConfettiController _confettiController;


  late Timer timer;
  Duration gameTime = const Duration();
  bool _showCompletionOverlay = false;

  // Ad-related variables
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  bool _isInterstitialAdReady = false;
  bool _isBannerAdReady = false;


  // Add with other ad variables
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  final String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID


  // Test ad unit IDs
  final String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  final String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('Interstitial ad successfully loaded');


          // Set ad callbacks
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isInterstitialAdReady = false;
              ad.dispose();
              print('Interstitial ad dismissed');

            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Failed to show interstitial ad: $error');
              _isInterstitialAdReady = false;
              ad.dispose();
            },
          );

          // Show ad when loaded
          if (_isInterstitialAdReady) {
            _interstitialAd?.show();
          }
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
    print('Loading interstitial ad...');

  }


  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
            print('Banner ad loaded successfully');

          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),

    );
    print('Loading banner ad...');


    _bannerAd?.load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('Rewarded ad successfully loaded');


          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isRewardedAdReady = false;
              ad.dispose();
              _loadRewardedAd(); // Load next ad
              print('Rewarded ad dismissed');

            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isRewardedAdReady = false;
              ad.dispose();
              _loadRewardedAd();
              print('Failed to show rewarded ad: $error');

            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded ad: $error');
          _isRewardedAdReady = false;
        },
      ),
    );print('Loading rewarded ad...');

  }

  Future<bool> _showRewardedAd() async {
    if (!_isRewardedAdReady) {
      // Load a new ad if not ready
      _loadRewardedAd();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading ad, please try again in a moment'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd?.show(
      onUserEarnedReward: (_, reward) {
        completer.complete(true);
      },
    );

    return completer.future;
  }

  // completion tracking and interstitial ad trigger
  Set<int> completedNumbers = {};
  bool _showingCompletionAd = false;

  void handleNumberCompletion(int number) {
    print('Number completion callback triggered for: $number');

    if (!completedNumbers.contains(number)) {
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          completedNumbers.add(number);
          print('Added number $number to completed numbers. Total: ${completedNumbers.length}');

          if (completedNumbers.length % 3 == 0) {
            print('Three numbers completed, showing ad');
            Fluttertoast.showToast(
              msg: "Completed 2 numbers!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
            _loadInterstitialAd();
          }
        });
      });
    }
  }

  void checkNumberCompletion(int number) {
    print('Checking completion for number: $number');

    if (!completedNumbers.contains(number)) {
      print('Number $number not yet in completedNumbers.');
      if (remainingValues[number] == 0) {
        // Number has been fully used
        completedNumbers.add(number);
        print('Number $number added to completedNumbers. Completed numbers: $completedNumbers');

        // Show a toast when 2 numbers are completed
        if (completedNumbers.length % 3 == 0) {
          print('Completed 3 numbers!');

          Fluttertoast.showToast(
            msg: "Completed 2 numbers!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Check if we've completed 2 numbers and not currently showing an ad
          if (!_showingCompletionAd) {
            _showingCompletionAd = true;

            // Load and show a new interstitial ad
            InterstitialAd.load(
              adUnitId: _interstitialAdUnitId,
              request: const AdRequest(),
              adLoadCallback: InterstitialAdLoadCallback(
                onAdLoaded: (ad) {
                  ad.fullScreenContentCallback = FullScreenContentCallback(
                    onAdDismissedFullScreenContent: (ad) {
                      _showingCompletionAd = false;
                      ad.dispose();
                    },
                    onAdFailedToShowFullScreenContent: (ad, error) {
                      _showingCompletionAd = false;
                      ad.dispose();
                      print('InterstitialAd failed to show: $error');
                    },
                  );
                  ad.show();
                },
                onAdFailedToLoad: (error) {
                  _showingCompletionAd = false;
                  print('InterstitialAd failed to load: $error');
                },
              ),
            );
          }
        }
      } else {
        print('Number $number still has remaining values: ${remainingValues[number]}');
      }
    } else {
      print('Number $number is already in completedNumbers.');
    }
  }




  Widget _buildCompletionOverlay() {
    String currentTime = '${gameTime.inMinutes.toString().padLeft(2, '0')}:${gameTime.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    String bestTime = Hive.box('settings').get(
        'best_time_${widget.difficulty.toLowerCase()}',
        defaultValue: '--:--'
    );

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appText[appLang]!['completed']!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  currentTime,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('Today', currentTime),
                      _buildDivider(),
                      _buildStatRow('All Time', bestTime),
                      _buildDivider(),
                      _buildStatRow('Difficulty', widget.difficulty),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildButton(
                  'New Game',
                      () {
                    setState(() {
                      _showCompletionOverlay = false;
                      setInGameValues();
                      resetTimer();
                      startTimer();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildButton(
                  'Main',
                      () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                          (route) => false,
                    );
                  },
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildButton(String text, VoidCallback onTap, {bool isSecondary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: isSecondary ? Colors.grey.shade200 : Colors.blue.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isSecondary ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }

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

    _confettiController = ConfettiController(duration: const Duration(seconds: 10));


    // Initialize ads
    _loadRewardedAd();
    _loadInterstitialAd();
    _loadBannerAd();

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
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    timer.cancel();
    sudokuBox.clear();
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);

    _confettiController.dispose();


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
    //double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
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
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: GameBoard(
                      sudoku: sudoku,
                      history: history,
                      sudokuBox: sudokuBox,
                      remainingValues: remainingValues,
                      checkSudokuCompleted: checkSudokuCompleted,
                      onNumberCompleted: handleNumberCompletion,

                    ),
                  ),
                ),
                const SizedBox(height: 0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: FunctionalButtons(
                    sudoku: sudoku,
                    history: history,
                    remainingValues: remainingValues,
                    checkSudokuCompleted: checkSudokuCompleted,
                    onHintWithAd: _showRewardedAd,  // rewarded

                  ),
                ),
                const SizedBox(height: 26),
                Expanded(
                  flex: 2,
                  child: numericSection(width),
                ),
                if (_isBannerAdReady)
                  SizedBox(
                    height: _bannerAd!.size.height.toDouble(),
                    width: _bannerAd!.size.width.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                const SizedBox(height: 2),
              ],
            ),
          ),
          if (_showCompletionOverlay)
            _buildCompletionOverlay(),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.05,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
              createParticlePath: drawStarPath,
            ),
          ),
        ],
      ),
    );
  }

  Path drawStarPath(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep), halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
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
        //bool fastModeActivated =
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
      setState(() {
        _showCompletionOverlay = true;
        _confettiController.play();

      });
      // Reset ad state for next game
      _loadRewardedAd();
      completedNumbers.clear();
      _showingCompletionAd = false;
    }

    if (Hive.box('settings').get('mistakesLimit', defaultValue: true)) {
      if (sudokuBox.get('mistakes', defaultValue: 0) >= 3) {
        showSudokuFailedDialog(context);
      }
    }
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
                        fontWeight: FontWeight.w400,
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