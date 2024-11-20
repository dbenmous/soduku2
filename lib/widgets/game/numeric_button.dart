import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_sudoku/utils/sudoku.dart';

class NumericButton extends StatelessWidget {
  NumericButton({
    super.key,
    required this.num,
    required this.sudoku,
    required this.history,
    required this.gameTime,
    required this.difficulty,
    required this.penActivated,
    required this.remainingValues,
    required this.checkSudokuCompleted,
  });

  final int num;
  final String difficulty;
  final Duration gameTime;
  final bool penActivated;
  final Map<int, int> remainingValues;
  final List<List<SudokuCell>> sudoku;
  final VoidCallback checkSudokuCompleted;
  final List<MapEntry<String, String>> history;

  final Box sudokuBox = Hive.box('in_game_args');

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          String currentItem = sudokuBox.get('xy', defaultValue: '99');
          int row = int.parse(currentItem[0]);
          int col = int.parse(currentItem[1]);

          if ((row == 9 || col == 9)) return;

          // Normal fill mode
          if (!penActivated) {
            sudokuBox.put('highlightValue', num);

            // Attempt to fill the selected cell with the chosen number
            if (sudoku[row][col].toggleValue(num)) {
              sudokuBox.put('fill', '$row$col');

              // Value is incorrect
              if (!sudoku[row][col].isCompleted) {
                sudokuBox.put(
                  'mistakes',
                  sudokuBox.get('mistakes', defaultValue: 0) + 1,
                );
                history.add(MapEntry('wrong', '$row$col'));

                // Check for mistake limit
                if (Hive.box('settings')
                    .get('mistakesLimit', defaultValue: true) &&
                    sudokuBox.get('mistakes', defaultValue: 0) >= 3) {
                  // Trigger game over
                  checkSudokuCompleted();
                }
              }
              // Value is correct
              else {
                remainingValues[num] = (remainingValues[num]! - 1);
                history.add(MapEntry('correct', '$row$col'));
                sudokuBox.put('remainingVals', 0);

                // If the number is used up, deselect the cell
                if (remainingValues[num] == 0) {
                  sudokuBox.put('xy', '99');
                }
              }

              checkSudokuCompleted();
            }
          }
          // Pencil mode (adding notes)
          else {
            if (sudoku[row][col].toggleNote(num)) {
              sudokuBox.put('fill', '$row$col');
            }
          }
        },
        child: SizedBox(
          height: 65,
          width: width / 11,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    num.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87.withOpacity(.8),
                    ),
                  ),
                  Expanded(child: Container()),
                  Text(
                    remainingValues[num].toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45.withOpacity(.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
