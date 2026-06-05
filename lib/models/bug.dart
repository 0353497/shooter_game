import 'package:flutter/material.dart';

class Bug {
  final Rect rect;
  final int lives;
  final double fallSpeed;

  Bug({required this.rect, required this.lives, this.fallSpeed = 30});

  Color get color {
    if (lives > 10) return Colors.white;
    if (lives >= 5) return Colors.purpleAccent;
    if (lives >= 3) return Colors.red;
    if (lives == 2) return Colors.orange;
    if (lives == 1) return Colors.yellow;
    return Colors.yellow;
  }

  Bug copyWith({Rect? rect, int? lives, double? fallSpeed}) {
    return Bug(
      rect: rect ?? this.rect,
      lives: lives ?? this.lives,
      fallSpeed: fallSpeed ?? this.fallSpeed,
    );
  }
}
