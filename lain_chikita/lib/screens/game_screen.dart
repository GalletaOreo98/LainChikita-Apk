import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  final Function callback;
  const GameScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<GameScreen> {
  double basketPositionX = 0;
  int score = 0;
  List<Offset> fallingObjects = [];
  bool gameRunning = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    gameRunning = true;
    fallingObjects = [];
    score = 0;
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      print("500");
      if (gameRunning) {
        widget.callback();
          fallingObjects.add(Offset(
            Random().nextDouble() * MediaQuery.of(context).size.width,
            0,
          ));
        
      } else {
        timer.cancel();
      }
    });

    Timer.periodic(Duration(milliseconds: 50), (timer) {
      print(widget.runtimeType);
      if (gameRunning) {
        List<Offset> objectsToRemove = [];
        
          fallingObjects = fallingObjects.map((object) => Offset(object.dx, object.dy + 5)).toList();

          fallingObjects.removeWhere((object) {
            if (object.dy > MediaQuery.of(context).size.height) {
              return true;
            } else if ((object.dx > basketPositionX &&
                    object.dx < basketPositionX + MediaQuery.of(context).size.width * 0.1) &&
                object.dy > MediaQuery.of(context).size.height - 100) {
              score += 10;
              objectsToRemove.add(object);
              return true;
            }
            return false;
          });

          fallingObjects.removeWhere((object) => objectsToRemove.contains(object));
        widget.callback();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catch Game'),
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            basketPositionX += details.delta.dx;
          });
        },
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.blueGrey[200],
            ),
            Positioned(
              left: basketPositionX,
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.1,
                height: 50,
                color: Colors.green,
              ),
            ),
            ...fallingObjects.map((object) {
              return Positioned(
                left: object.dx,
                top: object.dy,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.05,
                  height: MediaQuery.of(context).size.width * 0.05,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
            Positioned(
              top: 10,
              right: 10,
              child: Text(
                'Score: $score',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
