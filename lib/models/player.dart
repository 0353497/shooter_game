import 'package:flutter/material.dart';

class Player {
  final Rect rect;
  final int hp;

  Player({required this.rect, this.hp = 3, this.direction = 0});
  final int direction;
  Player copyWith({Rect? rect, int? hp, int? direction}) {
    return Player(
      rect: rect ?? this.rect,
      direction: direction ?? this.direction,
      hp: hp ?? this.hp,
    );
  }
}
