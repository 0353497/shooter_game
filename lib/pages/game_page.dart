import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';
import 'package:shooter_game/models/bug.dart';
import 'package:shooter_game/models/bullet.dart';
import 'package:shooter_game/models/player.dart';
import 'package:shooter_game/models/power_ups.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late Ticker ticker;

  Duration _lastTick = Duration.zero;

  int _direction = 0;
  int killedBugs = 0;

  Duration lastBugSpawn = Duration.zero;
  Duration lastUpgradeSpawn = Duration.zero;
  Duration lastShot = Duration.zero;
  BoxConstraints gameSize = BoxConstraints();

  Duration bugSpawnDelay = Duration(seconds: 3);
  Duration upgradeDelay = Duration(seconds: 8);

  bool showUpgrade = true;
  bool _isShooting = false;
  bool isGameover = false;
  bool isShootHelperActive = false;
  int currentFase = 1;
  int waveIndex = 0;
  int waveCount = 0;

  List<Bullet> bullets = [];
  Duration get shootDelay => Duration(
    milliseconds: (300 * (1 - (.1 * bulletUpgrades.attackSpeeds))).toInt(),
  );
  List<Bug> bugs = [Bug(rect: Rect.fromLTWH(0, 50, 50, 50), lives: 3)];

  Upgrade upgrade = Upgrade(
    rect: Rect.fromLTWH(20, 20, 40, 40),
    powerUp: PowerUps.multiShot,
  );

  BulletUpgrades bulletUpgrades = BulletUpgrades(
    damage: 1,
    attackSpeeds: 1,
    multishots: 1,
  );

  Bug bugClone = Bug(rect: Rect.zero, lives: 3, fallSpeed: 30);

  Player player = Player(
    rect: Rect.fromLTWH(Get.width * .5, Get.height - 200, 50, 50),
  );

  @override
  void initState() {
    super.initState();
    init();
    ticker = Ticker((dur) => _ontTick(dur));
    ticker.start();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    ticker.stop();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      gameSize = constraints;
                      return Stack(
                        children: [
                          for (Bug bug in bugs)
                            Positioned.fromRect(
                              rect: bug.rect,
                              child: Icon(
                                Icons.bug_report,
                                color: bug.color,
                                size: bug.rect.width,
                              ),
                            ),
                          Positioned.fromRect(
                            rect: player.rect,
                            child: Center(
                              child: Icon(
                                Icons.rocket,
                                color: Colors.blue,
                                size: player.rect.width,
                              ),
                            ),
                          ),

                          for (Bullet bullet in bullets)
                            Positioned.fromRect(
                              rect: bullet.rect,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          if (showUpgrade)
                            Positioned.fromRect(
                              rect: upgrade.rect,
                              child: PowerUpWidget(upgrade: upgrade),
                            ),
                          Align(
                            alignment: Alignment(-.9, -.9),
                            child: Text(
                              "Killed bugs: $killedBugs",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment: Alignment(.9, -.9),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0; i < player.hp; i++)
                                  Icon(Icons.favorite, color: Colors.red),
                              ],
                            ),
                          ),
                          if (isGameover)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 24,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "GAME OVER",
                                        style: TextStyle(
                                          fontSize: 32,
                                          color: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => restartGame(),
                                        child: Text("Restart"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                Container(
                  height: 100,
                  color: Colors.grey,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 48,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => _direction = -1,
                        onTapUp: (_) => _direction = 0,
                        onTapCancel: () => _direction = 0,
                        child: Icon(Icons.arrow_back_ios),
                      ),

                      GestureDetector(
                        onTapDown: (_) => _isShooting = true,
                        onTapUp: (_) => _isShooting = false,
                        onTapCancel: () => _isShooting = false,
                        child: Icon(Icons.radio_button_checked, size: 50),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _direction = 1,
                        onTapUp: (_) => _direction = 0,
                        onTapCancel: () => _direction = 0,
                        child: Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _onKey(KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _direction = isDown
          ? -1
          : isUp
          ? 0
          : _direction;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _direction = isDown
          ? 1
          : isUp
          ? 0
          : _direction;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      if (isDown) _isShooting = true;
      if (isUp) _isShooting = false;
    }

    return false;
  }

  void _ontTick(Duration dur) {
    final double delta = (dur - _lastTick).inMilliseconds / 1000.0;
    _lastTick = dur;
    if (player.hp <= 0) {
      gameOver();
    }

    movePlayer(delta);
    if (_isShooting) shoot(dur);
    moveBugs(delta);
    moveBullets(delta);

    if (currentFase < 2) {
      spawnBugs(dur, null);
    }

    if (dur.inSeconds > 20 && currentFase < 2) {
      final double baseFallspeed = (Random().nextInt(30) + 1) * 3;
      final double fallSpeed = baseFallspeed * (dur.inSeconds * .5);
      currentFase = 2;
      bugSpawnDelay = const Duration(milliseconds: 2500); // V/zigzag wave pace
      bugClone = Bug(
        rect: Rect.zero,
        lives: Random().nextInt(3) + 3,
        fallSpeed: fallSpeed,
      );
    }

    phase2(dur);

    handleHitDetection();
    moveUpgrade(delta);
    respawnUpgrade(dur);
    setState(() {});
  }

  void phase2(Duration dur) {
    if (currentFase < 2) return;

    if (dur.inMilliseconds - lastBugSpawn.inMilliseconds <
        bugSpawnDelay.inMilliseconds) {
      return;
    }

    lastBugSpawn = dur;

    if (waveIndex < 3) {
      // --- V-formation (3 waves) ---
      _spawnVFormation();
      waveCount++;
      if (waveCount >= 3) {
        waveIndex = 4;
        waveCount = 0;
      }
    } else if (waveIndex == 4) {
      // --- Zigzag (2 waves) ---
      _spawnZigzag();
      waveCount++;
      if (waveCount >= 2) {
        waveIndex = 5;
        waveCount = 0;
      }
    } else {
      // --- Phase 1 but harder (loops) ---
      _spawnHarderPhase1();
    }
  }

  void _spawnVFormation() {
    final double cx = gameSize.maxWidth * .5;
    const int count = 5;
    for (int i = 0; i < count; i++) {
      final double offset = (i - count ~/ 2) * 60.0;
      final double y = -20 + (offset.abs() * 0.8);
      bugs.add(
        bugClone.copyWith(
          rect: Rect.fromLTWH(cx + offset, y, 50, 50),
          fallSpeed: 100,
        ),
      );
    }
  }

  void _spawnZigzag() {
    final double cx = gameSize.maxWidth * .5;

    const int count = 6;
    for (int i = 0; i < count; i++) {
      final double x = cx + (i % 2 == 0 ? -80.0 : 80.0) + (i * 30.0);
      final double y = -20 - (i * 15.0); // staggered depth
      bugs.add(bugClone.copyWith(rect: Rect.fromLTWH(x, y, 50, 50)));
    }
  }

  void _spawnHarderPhase1() {
    final Random random = Random();
    // Same as phase 1 but: more lives, faster fall, tighter spawn delay
    bugSpawnDelay = const Duration(milliseconds: 600);
    final spawnRect = Rect.fromLTWH(
      (random.nextDouble() * Get.width * .80) + 50,
      20,
      50,
      50,
    );
    final hardBug = Bug(
      rect: spawnRect,
      lives: Random().nextInt(3) + 4, // 4–6 lives (harder)
      fallSpeed: (Random().nextInt(30) + 40).toDouble(), // faster
    );
    bugs.add(hardBug);
  }

  void respawnUpgrade(Duration dur) {
    if (dur.inMilliseconds - lastUpgradeSpawn.inMilliseconds >
        upgradeDelay.inMilliseconds) {
      lastUpgradeSpawn = dur;
      resetUpgrade(upgrade.rect);
    }
  }

  void moveUpgrade(double delta) {
    upgrade = upgrade.copyWith(
      rect: upgrade.rect.shift(Offset(0, 120 * delta)),
    );
    final rect = upgrade.rect;
    if (rect.bottom > Get.height - 120) {
      showUpgrade = false;
    }
  }

  void resetUpgrade(Rect rect) {
    final Random random = Random();
    final randomUpgrade = random.nextInt(3);

    PowerUps powerUp = PowerUps.damage;
    if (randomUpgrade == 0) {
      powerUp = PowerUps.multiShot;
    }
    if (randomUpgrade == 1) {
      powerUp = PowerUps.shootSpeed;
    }

    upgrade = upgrade.copyWith(
      rect: Rect.fromLTWH(
        (random.nextDouble() * Get.width * .80) + 50,
        20,
        rect.width,
        rect.height,
      ),
      powerUp: powerUp,
    );
    showUpgrade = true;
  }

  void handleHitDetection() {
    for (int i = 0; i < bugs.length; i++) {
      int bulletIndex = bullets.indexWhere(
        (bullet) => bugs[i].rect.overlaps(bullet.rect),
      );
      if (bulletIndex != -1) {
        bugs[i] = bugs[i].copyWith(
          lives: bugs[i].lives - bullets[bulletIndex].damage,
        );
        if (bugs[i].lives <= 0) {
          bugs.removeAt(i);
          killedBugs++;
        }
        bullets.removeAt(bulletIndex);
      }
    }

    if (player.rect.overlaps(upgrade.rect) && showUpgrade) {
      showUpgrade = false;
      bulletUpgrades = bulletUpgrades.applyUpgrade(upgrade);
    }
  }

  void moveBullets(double delta) {
    for (var i = 0; i < bullets.length; i++) {
      bullets[i] = bullets[i].copyWith(
        rect: bullets[i].rect.shift(Offset(0, -bullets[i].speed * delta)),
      );
      if (bullets[i].rect.bottom < -40) bullets.removeAt(i);
    }
  }

  void spawnBugs(Duration dur, Rect? rect) {
    if (dur.inMilliseconds - lastBugSpawn.inMilliseconds >
        bugSpawnDelay.inMilliseconds) {
      lastBugSpawn = dur;
      Rect spawnRect = rect ?? Rect.zero;
      if (rect == null) {
        final Random random = Random();
        spawnRect = Rect.fromLTWH(
          (random.nextDouble() * Get.width * .80) + 50,
          20,
          50,
          50,
        );
      }
      bugs.add(bugClone.copyWith(rect: spawnRect));
    }
  }

  void moveBugs(double delta) {
    for (var i = 0; i < bugs.length; i++) {
      bugs[i] = bugs[i].copyWith(
        rect: bugs[i].rect.shift(Offset(0, bugClone.fallSpeed * delta)),
      );
      if (bugs[i].rect.bottom > Get.height - 120) {
        //TODO
        player = player.copyWith(hp: player.hp - 1);
        bugs.removeAt(i);
      }
    }
  }

  void movePlayer(double delta) {
    final newX =
        player.rect.left + (_direction * 150 * delta); // 300 = pixels/sec
    if (newX > 10 && newX < Get.width - 60) {
      player = player.copyWith(
        rect: player.rect.shift(Offset(newX - player.rect.left, 0)),
      );
    }
  }

  void init() {}

  void shoot(Duration dur) {
    if (dur.inMilliseconds - lastShot.inMilliseconds <
        shootDelay.inMilliseconds) {
      return;
    }
    lastShot = dur;
    calcBulletUpgrades();
  }

  void calcBulletUpgrades() {
    const baseSpeed = 100;
    List<Bullet> bulletsToAdd = [];
    for (var i = 0; i < bulletUpgrades.multishots; i++) {
      double middlePlayer = player.rect.center.dx - 5;
      const double spacing = 20;
      double left =
          (middlePlayer - (spacing * i)) +
          ((bulletUpgrades.multishots - 1) * spacing) * .5;
      bulletsToAdd.add(
        Bullet(
          rect: Rect.fromLTWH(left, player.rect.top, 10, 20),
          damage: bulletUpgrades.damage,
          speed: baseSpeed * (1 + (.1 * bulletUpgrades.attackSpeeds)),
        ),
      );
    }
    bullets.addAll(bulletsToAdd);
  }

  void gameOver() {
    ticker.stop();
    setState(() {
      isGameover = true;
    });
  }

  void restartGame() {
    _lastTick = Duration.zero;
    isGameover = false;

    _direction = 0;
    killedBugs = 0;

    lastBugSpawn = Duration.zero;
    lastUpgradeSpawn = Duration.zero;
    lastShot = Duration.zero;
    gameSize = BoxConstraints();

    bugSpawnDelay = Duration(seconds: 3);
    upgradeDelay = Duration(seconds: 5);

    showUpgrade = true;
    _isShooting = false;
    isGameover = false;
    isShootHelperActive = false;
    currentFase = 1;
    waveIndex = 0;
    waveCount = 0;

    bullets = [];
    bugs = [Bug(rect: Rect.fromLTWH(0, 50, 50, 50), lives: 3)];

    upgrade = Upgrade(
      rect: Rect.fromLTWH(20, 20, 40, 40),
      powerUp: PowerUps.multiShot,
    );

    bulletUpgrades = BulletUpgrades(damage: 1, attackSpeeds: 1, multishots: 1);

    bugClone = Bug(rect: Rect.zero, lives: 3, fallSpeed: 30);

    player = Player(
      rect: Rect.fromLTWH(Get.width * .5, Get.height - 200, 50, 50),
    );
    ticker.start();
    setState(() {});
  }
}

class PowerUpWidget extends StatelessWidget {
  const PowerUpWidget({super.key, required this.upgrade});
  final Upgrade upgrade;
  IconData upgadeIcon() {
    if (upgrade.powerUp == PowerUps.shootSpeed) return Icons.speed;
    if (upgrade.powerUp == PowerUps.damage) return Icons.add;
    return Icons.more_horiz;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: RadialGradient(colors: [Colors.red, Colors.pink]),
      ),
      child: Icon(upgadeIcon(), color: Colors.white),
    );
  }
}
