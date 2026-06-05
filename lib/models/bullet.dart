import 'package:flutter/material.dart';
import 'package:shooter_game/models/power_ups.dart';

class Bullet {
  final Rect rect;
  final int damage;
  final double speed;

  Bullet({required this.rect, this.damage = 1, this.speed = 100});

  Bullet copyWith({Rect? rect, int? damage, double? speed}) {
    return Bullet(
      rect: rect ?? this.rect,
      damage: damage ?? this.damage,
      speed: speed ?? this.speed,
    );
  }
}

class BulletUpgrades {
  final int damage;
  final int attackSpeeds;
  final int multishots;

  BulletUpgrades({
    required this.damage,
    required this.attackSpeeds,
    required this.multishots,
  });

  BulletUpgrades copyWith({int? damage, int? attackSpeeds, int? multishots}) {
    return BulletUpgrades(
      damage: damage ?? this.damage,
      attackSpeeds: attackSpeeds ?? this.attackSpeeds,
      multishots: multishots ?? this.multishots,
    );
  }

  BulletUpgrades applyUpgrade(Upgrade upgrade) {
    switch (upgrade.powerUp) {
      case PowerUps.damage:
        return copyWith(damage: damage + 1);
      case PowerUps.shootSpeed:
        return copyWith(attackSpeeds: attackSpeeds + 1);
      case PowerUps.multiShot:
        return copyWith(multishots: multishots + 1);
    }
  }
}
