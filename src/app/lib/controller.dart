import 'package:flame/sprite.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:math';

import 'board-game.dart';

class Controller {
  final BoardGame game;

  double backgroundAspectRatio = 4;
  Rect backgroundRect;
  Sprite backgroundSprite;

  double knobAspectRatio = 2;
  Rect knobRect;
  Sprite knobSprite;

  bool dragging = false;
  Offset dragPosition;

  double maxVAngle = 0.5;

  Controller(this.game) {
    backgroundSprite = Sprite('joystick_background.png');
    knobSprite = Sprite('joystick_knob.png');

    initialize();
  }

  void initialize() async {
    // The circle radius calculation that will contain the background
    // image of the joystick
    var radius = (game.tileSize * backgroundAspectRatio) / 2;

    Offset osBackground = Offset(radius + (radius / 2) * 1.5,
        game.screenSize.height - 5*radius/4);
    backgroundRect = Rect.fromCircle(center: osBackground, radius: radius);

    // The circle radius calculation that will contain the knob
    // image of the joystick
    radius = (game.tileSize * knobAspectRatio) / 2;

    Offset osKnob = Offset(backgroundRect.center.dx, backgroundRect.center.dy);
    knobRect = Rect.fromCircle(center: osKnob, radius: 1.25 * radius);
    dragPosition = knobRect.center;
  }

  void render(Canvas canvas) {
    backgroundSprite.renderRect(canvas, backgroundRect);
    knobSprite.renderRect(canvas, knobRect);
  }

  String update(double t) {
    String result = "k0.000";
    if (dragging) {
      double _radAngle = atan2(dragPosition.dy - backgroundRect.center.dy,
          dragPosition.dx - backgroundRect.center.dx);
      double vAng = 0.0;

      // Update playerShip's player rad angle
      game.grace.lastMoveRadAngle = _radAngle;
      print(_radAngle);

      if (_radAngle < (-15 / 32) * pi && _radAngle > (-17 / 32) * pi) {
        result = "i";
        vAng = 0.0;
      } else if (_radAngle <= (-1 / 32) * pi && _radAngle >= (-15 / 32) * pi) {
        result = "o";
        vAng = (_radAngle + (15 / 32) * pi) * maxVAngle * 4 / pi;
      } else if (_radAngle < (1 / 32) * pi && _radAngle > (-1 / 32) * pi) {
        result = "l";
        vAng = 0.5;
      } else if (_radAngle <= (15 / 32) * pi && _radAngle >= (1 / 32) * pi) {
        result = ".";
        vAng = (_radAngle - (15 / 32) * pi) * maxVAngle * (-4) / pi;
      } else if (_radAngle < (17 / 32) * pi && _radAngle > (15 / 32) * pi) {
        result = ",";
        vAng = 0.0;
      } else if (_radAngle <= (31 / 32) * pi && _radAngle >= (17 / 32) * pi) {
        result = "m";
        vAng = (_radAngle - 17 / 32 * pi) * maxVAngle * 4 / pi;
      } else if ((_radAngle < pi && _radAngle > (31 / 32) * pi) ||
          (_radAngle < (-31 / 32) * pi && _radAngle > (-1) * pi)) {
        result = "j";
        vAng = 0.5;
      } else if (_radAngle <= (-17 / 32) * pi && _radAngle >= (-31 / 32) * pi) {
        result = "u";
        vAng = (_radAngle + 17 / 32 * pi) * maxVAngle * (-4) / pi;
      }

      //result += vAng.toStringAsFixed(15);
      //  -2/16*pi ---- maxVAngle
      //  radAngulo - 3/8 ------ vAng
      // vang = (radANgulo - 3/8*pi) * 0.5 * -4/pi
      //            -2/8          -1/8

      // Distance between the center of joystick background & drag position
      Point p = Point(backgroundRect.center.dx, backgroundRect.center.dy);
      double dist = p.distanceTo(Point(dragPosition.dx, dragPosition.dy));

      // The maximum distance for the knob position the edge of
      // the background + half of its own size. The knob can wander in the
      // background image, but not outside.
      dist = dist < (game.tileSize * backgroundAspectRatio / 2)
          ? dist
          : (game.tileSize * backgroundAspectRatio / 2);

      if (dist == 0) {
        result = 'k';
      }
      result += vAng.toStringAsFixed(3);
      print(result);
      // Calculation the knob position
      double nextX = dist * cos(_radAngle);
      double nextY = dist * sin(_radAngle);
      Offset nextPoint = Offset(nextX, nextY);

      Offset diff = Offset(backgroundRect.center.dx + nextPoint.dx,
              backgroundRect.center.dy + nextPoint.dy) -
          knobRect.center;
      knobRect = knobRect.shift(diff);
    } else {
      // The drag position is, at this moment, that of the center of the
      // background of the joystick. It calculates the difference between this
      // position and the current position of the knob to place the center of
      // the background.
      Offset diff = dragPosition - knobRect.center;
      knobRect = knobRect.shift(diff);
    }
    return result;
  }

  void onPanStart(DragStartDetails details) {
    if (knobRect.contains(details.globalPosition)) {
      dragging = true;
      game.grace.move = true;
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (dragging && knobRect.contains(details.globalPosition)) {
      dragPosition = details.globalPosition;
    }
  }

  void onPanEnd(DragEndDetails details) {
    dragging = false;
    // Reset drag position to the center of joystick background
    dragPosition = backgroundRect.center;
    // Stop move player ship
    game.grace.move = false;
  }
}
