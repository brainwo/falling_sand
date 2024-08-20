import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        child: FallingSand(
          height: 50,
          width: 50,
        ),
      ),
    );
  }
}

class FallingSand extends StatefulWidget {
  const FallingSand({super.key, required this.width, required this.height});
  final int width, height;

  @override
  State<FallingSand> createState() => _FallingSandState();
}

class _FallingSandState extends State<FallingSand>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  late final TickerFuture tickerFuture;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(tick);
    tickerFuture = ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  var delta = const Duration();

  final width = 50;
  final height = 50;

  void tick(Duration duration) {
    if ((delta += duration) < const Duration(milliseconds: 50)) return;

    // iterate over the board and move every cell down if it is not at the bottom
    for (var col = 0; col < width; col++) {
      for (var row = height - 1; row >= 0; row--) {
        //
        var value = state[col][row];
        if (value == 1) {
          var canMoveDown = row + 1 < height && state[col][row + 1] != 1;

          if (canMoveDown) {
            setState(() {
              state[col][row + 1] = value;
              state[col][row] = 0;
            });
          }
        }
      }
    }
  }

  late var state = emptyState();

  List<List<int>> emptyState() => List.generate(
        width,
        (i) => List.generate(
          height,
          (j) => i == 0 && j == 0 ? 1 : 0,
        ),
      );

  final size = const Size.square(1000);

  Offset? position;
  int? prevXPos;
  int? prevYPos;
  int? prevVal;

  void positionToCellUpdate(
    Offset offset,
    int value, [
    bool create = false,
  ]) {
    final cellSize = Size(size.width / width, size.height / height);

    var x = max(0, offset.dx) ~/ cellSize.width;
    var y = max(0, offset.dy) ~/ cellSize.height;

    x = min(x, width - 1);
    y = min(y, width - 1);

    if (state[x][y] == value) return;

    if (prevXPos != null && prevYPos != null && prevVal != null) {
      // restore last state
      state[prevXPos!][prevYPos!] = prevVal!;
      prevXPos = null;
      prevYPos = null;
      prevVal = null;
    }

    // grab state before mutating

    if (!create) {
      prevVal = state[x][y];
      prevXPos = x;
      prevYPos = y;
    }

    setState(() {
      position = offset;
      state[x][y] = create ? 1 : value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints.tight(size),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all()),
          child: Listener(
            child: CustomPaint(
              size: size,
              painter: FallingSandPainter(state),
            ),
            onPointerHover: (event) {
              positionToCellUpdate(event.localPosition, 2);
            },
            onPointerMove: (event) {
              positionToCellUpdate(event.localPosition, 1, true);
            },
            onPointerDown: (event) {
              positionToCellUpdate(event.localPosition, 1, true);
            },
            onPointerUp: (event) {
              positionToCellUpdate(event.localPosition, 2);
            },
          ),
        ),
      ),
    );
  }
}

class FallingSandPainter extends CustomPainter {
  FallingSandPainter(this.state);
  final List<List<int>> state;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.square;

    final width = state.length;
    final height = state[0].length;
    final divisionX = size.width / width;
    final divisionY = size.height / height;
    final cellSize = Size(divisionX, divisionY);

    for (var col = 0; col < width; col++) {
      for (var row = 0; row < height; row++) {
        if (state[col][row] == 1) {
          canvas.drawRect(Offset(col * divisionX, row * divisionY) & cellSize,
              paint..color = Colors.black);
        }
        if (state[col][row] == 2) {
          canvas.drawRect(Offset(col * divisionX, row * divisionY) & cellSize,
              paint..color = Colors.green);
        }
        if (state[col][row] == 3) {
          canvas.drawRect(Offset(col * divisionX, row * divisionY) & cellSize,
              paint..color = Colors.red);
        }
      }
    }
  }

  @override
  bool shouldRepaint(FallingSandPainter oldDelegate) {
    return true;
  }
}
