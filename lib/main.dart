import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/screens/host.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter('sudoku');
  await Hive.openBox('settings');
  await Hive.openBox('in_game_args');
  await Hive.openBox('prev_sudokus');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sudoku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const HostPage(),
    );
  }
}
