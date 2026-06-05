import 'package:flutter/material.dart';

enum PowerUps { multiShot, shootSpeed, damage }

class Upgrade {
  final Rect rect;
  final PowerUps powerUp;

  Upgrade({required this.rect, required this.powerUp});

  Upgrade copyWith({Rect? rect, PowerUps? powerUp}) {
    return Upgrade(rect: rect ?? this.rect, powerUp: powerUp ?? this.powerUp);
  }
}
