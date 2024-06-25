import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MinesweeperApp());
}

class MinesweeperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minesweeper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DifficultySelectionPage(),
    );
  }
}

class DifficultySelectionPage extends StatelessWidget {
  void _startGame(BuildContext context, int rows, int cols, int mines) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MinesweeperHomePage(rows: rows, cols: cols, mines: mines),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minesweeper - Select Difficulty'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _startGame(context, 5, 5, 5),
              child: Text('Easy'),
            ),
            ElevatedButton(
              onPressed: () => _startGame(context, 8, 8, 10),
              child: Text('Medium'),
            ),
            ElevatedButton(
              onPressed: () => _startGame(context, 10, 10, 15),
              child: Text('Hard'),
            ),
          ],
        ),
      ),
    );
  }
}

class MinesweeperHomePage extends StatefulWidget {
  final int rows;
  final int cols;
  final int mines;

  MinesweeperHomePage({required this.rows, required this.cols, required this.mines});

  @override
  _MinesweeperHomePageState createState() => _MinesweeperHomePageState();
}

class _MinesweeperHomePageState extends State<MinesweeperHomePage> {
  late List<List<String>> board;
  late List<List<bool>> revealed;
  late List<List<bool>> flagged;
  bool gameOver = false;
  bool firstClick = true;
  int remainingMines = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    board = List.generate(widget.rows, (_) => List.generate(widget.cols, (_) => '0'));
    revealed = List.generate(widget.rows, (_) => List.generate(widget.cols, (_) => false));
    flagged = List.generate(widget.rows, (_) => List.generate(widget.cols, (_) => false));
    gameOver = false;
    firstClick = true;
    remainingMines = widget.mines;
  }

  void _placeMines(int initialRow, int initialCol) {
    var rand = Random();
    int placedMines = 0;

    while (placedMines < widget.mines) {
      int row = rand.nextInt(widget.rows);
      int col = rand.nextInt(widget.cols);

      if (board[row][col] != 'M' && !_isInInitialArea(row, col, initialRow, initialCol)) {
        board[row][col] = 'M';
        placedMines++;
      }
    }

    _calculateNumbers();
  }

  bool _isInInitialArea(int row, int col, int initialRow, int initialCol) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int newRow = initialRow + i;
        int newCol = initialCol + j;
        if (newRow == row && newCol == col) {
          return true;
        }
      }
    }
    return false;
  }

  void _calculateNumbers() {
    for (int row = 0; row < widget.rows; row++) {
      for (int col = 0; col < widget.cols; col++) {
        if (board[row][col] == 'M') {
          _incrementNeighbors(row, col);
        }
      }
    }
  }

  void _incrementNeighbors(int row, int col) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (_isInBounds(newRow, newCol) && board[newRow][newCol] != 'M') {
          board[newRow][newCol] = (int.parse(board[newRow][newCol]) + 1).toString();
        }
      }
    }
  }

  bool _isInBounds(int row, int col) {
    return row >= 0 && row < widget.rows && col >= 0 && col < widget.cols;
  }

  void _reveal(int row, int col) {
    if (gameOver || !_isInBounds(row, col) || revealed[row][col] || flagged[row][col]) return;

    if (firstClick) {
      _placeMines(row, col);
      firstClick = false;
    }

    setState(() {
      revealed[row][col] = true;
    });

    if (board[row][col] == 'M') {
      _gameOver(false);
    } else if (board[row][col] == '0') {
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          _reveal(row + i, col + j);
        }
      }
    }

    if (_checkWin()) {
      _gameOver(true);
    }
  }

  void _toggleFlag(int row, int col) {
    if (gameOver || !_isInBounds(row, col) || revealed[row][col]) return;

    setState(() {
      flagged[row][col] = !flagged[row][col];
      remainingMines += flagged[row][col] ? -1 : 1;
    });
  }

  bool _checkWin() {
    for (int row = 0; row < widget.rows; row++) {
      for (int col = 0; col < widget.cols; col++) {
        if (board[row][col] != 'M' && !revealed[row][col]) {
          return false;
        }
      }
    }
    return true;
  }

  void _gameOver(bool won) {
    setState(() {
      gameOver = true;
    });
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(won ? 'You Win!' : 'Game Over'),
          content: Text(won ? 'Congratulations! You have won the game.' : 'You have hit a mine. Try again!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
              child: Text('Restart'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Back to Menu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoard() {
    double boardSize = MediaQuery.of(context).size.width * 0.9;
    double cellSize = boardSize / widget.cols;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: boardSize,
          height: boardSize,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.cols,
              childAspectRatio: 1.0,
            ),
            itemCount: widget.rows * widget.cols,
            itemBuilder: (context, index) {
              int row = index ~/ widget.cols;
              int col = index % widget.cols;
              return GestureDetector(
                onTap: () {
                  _reveal(row, col);
                },
                onLongPress: () {
                  _toggleFlag(row, col);
                },
                child: Container(
                  margin: EdgeInsets.all(2),
                  color: revealed[row][col] ? Colors.grey : Colors.blue,
                  child: Center(
                    child: Text(
                      revealed[row][col]
                          ? board[row][col]
                          : (flagged[row][col] ? '🚩' : ''),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Mines: $remainingMines',
          style: TextStyle(fontSize: 20),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minesweeper'),
        actions: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                'Mines: $remainingMines',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: _buildBoard(),
      ),
    );
  }
}
