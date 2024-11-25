import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/utils/sudoku.dart';

class GridCell extends StatelessWidget {
  GridCell({
    super.key,
    required this.row,
    required this.col,
    required this.cell,
    required this.sudoku,
    required this.history,
    required this.remainingValues,
    required this.checkSudokuCompleted,
  });

  final int row;
  final int col;
  final SudokuCell cell;
  final List<MapEntry<String, String>> history;
  final Map<int, int> remainingValues;
  final List<List<SudokuCell>> sudoku;
  final VoidCallback checkSudokuCompleted;

  final Box sudokuBox = Hive.box('in_game_args');

  @override
  Widget build(BuildContext context) {
    BorderSide thickBorder = const BorderSide(width: 2, color: Colors.black);
    BorderSide thinBorder = const BorderSide(width: 1, color: Colors.grey);

    FontWeight prefilledWeight = FontWeight.w500;
    FontWeight latefilledWeight = FontWeight.w500;

    Color prefilledColor = Colors.black87.withOpacity(.8);
    Color incorrectColor = Colors.red.shade400;
    Color latefilledColor = Colors.blue.shade800;

    Color highlightBG = Colors.blue.shade100;
    Color rowColHighBG = Colors.blue.shade50;
    Color defaultBG = Colors.white;

    const double fontSize = 28;

    //
    String data = sudokuBox.get('xy', defaultValue: '99');
    int rowH = int.parse(data[0]);
    int colH = int.parse(data[1]);

    bool centerHighlight = (col == colH && row == rowH);
    bool horizontalVerticalHighlight = (col == colH || row == rowH);

    return ValueListenableBuilder(
      valueListenable:
      Hive.box('settings').listenable(keys: ['regHigh', 'numHigh']),
      builder: (context, value, child) {
        bool settingsValHigh = Hive.box('settings').get(
          'numHigh',
          defaultValue: true,
        );

        horizontalVerticalHighlight = horizontalVerticalHighlight &&
            Hive.box('settings').get(
              'regHigh',
              defaultValue: true,
            );

        int highlightValue = sudokuBox.get('highlightValue', defaultValue: 0);

        return Ink(
          decoration: BoxDecoration(
            color: centerHighlight
                ? highlightBG
                : horizontalVerticalHighlight
                ? rowColHighBG
                : defaultBG,
            border: Border(
              left: (col == 0 || col == 3 || col == 6)
                  ? thickBorder
                  : BorderSide.none,
              top: (row == 0 || row == 3 || row == 6)
                  ? thickBorder
                  : thinBorder,
              bottom: (row == 8) ? thickBorder : BorderSide.none,
              right: (col == 8) ? thickBorder : thinBorder,
            ),
          ),
          child: InkWell(
            onTap: () {
              // Select the cell by storing its coordinates
              sudokuBox.put('xy', '$row$col');
              sudokuBox.put('highlightValue', cell.currentValue);
            },
            child: cell.useAsNote
                ? NoteSection(
              notes: cell.notes,
              highlightVal: highlightValue,
              isSettingsActive: settingsValHigh,
            )
                : Center(
              child: Text(
                cell.isEmpty ? "" : cell.currentValue.toString(),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: cell.isPrefilled
                      ? prefilledWeight
                      : latefilledWeight,
                  color: cell.isPrefilled
                      ? prefilledColor
                      : !cell.isCompleted
                      ? incorrectColor
                      : latefilledColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NoteSection extends StatelessWidget {
  const NoteSection({
    super.key,
    required this.notes,
    required this.highlightVal,
    required this.isSettingsActive,
  });
  final List<int> notes;
  final int highlightVal;
  final bool isSettingsActive;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      children: List.generate(9, (index) {
        return Container(
          decoration: BoxDecoration(
            color: (isSettingsActive &&
                highlightVal == index + 1 &&
                notes.contains(index + 1))
                ? Colors.blue.shade100
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              notes.contains(index + 1) ? "${index + 1}" : "",
              style: const TextStyle(fontSize: 10),
            ),
          ),
        );
      }),
    );
  }
}