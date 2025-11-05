
// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flutter/material.dart';

import 'background.dart';
import 'brick.dart';
import 'enemy.dart';
import 'ground.dart';
import 'player.dart';

// Constante necesaria para el Ground
const double groundSize = 2.0;

class MyPhysicsGame extends Forge2DGame
    with HasCollisionDetection, ContactCallbacks { // <-- Añadido HasCollisionDetection
  MyPhysicsGame()
      : super(
          gravity: Vector2(0, 10),
          camera: CameraComponent.withFixedResolution(width: 800, height: 600),
        );

  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  final List<BirdType> _birdQueue = [];
  NextBirdIndicator? _nextBirdIndicator;

  @override
  FutureOr<void> onLoad() async {
    // 1. Precargar todos los efectos de sonido (ahora completo y consistente).
    await FlameAudio.audioCache.loadAll([
      'Audio-lanzandoce-bird/Blue-lanzandoce-Bird.mp3',
      'Audio-lanzandoce-bird/Boom-lanzandoce-Bird.mp3',
      'Audio-lanzandoce-bird/Chuck-lanzandoce-Bird.mp3',
      'Audio-lanzandoce-bird/Matilda-lanzandoce-Bird.mp3',
      'Audio-lanzandoce-bird/Red-lanzandoce-Bird.mp3',
      'Audio-muerte-pig/pig-Muerte-pig.mp3',
      'Audios-preparandoce-bird/Blue-preparandoce-Bird.mp3',
      'Audios-preparandoce-bird/Boom-preparandoce-Bird.mp3',
      'Audios-preparandoce-bird/Chuck-preparandoce-Bird.mp3',
      'Audios-preparandoce-bird/Red-preparandoce-Bird.mp3',
      'Audios-preparandoce-bird/Matilda-preparandoce-Bird.mp3', // <-- ¡Faltaba este en tu lista!
    ]);

    final backgroundImage = await images.load('colored_grass.png');
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);

    elements = spriteSheets[0];
    tiles = spriteSheets[1];

    _birdQueue.addAll(List.generate(5, (_) => BirdType.random));

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();
    unawaited(addBricks().then((_) => addEnemies()));
    await addPlayer();
    await _addNextBirdIndicator();

    return super.onLoad();
  }

  // --- Lógica de Colisión (Implementación crucial para el audio de muerte) ---

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Enemy) {
      playPigDeathSound();
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    // Lógica para el final del contacto (opcional)
  }

  // --- Métodos de Reproducción de Audio (Corregidos y Completos) ---

  // Llama a esto cuando el jugador empieza a estirar el pájaro.
  void playBirdStretchSound(BirdType birdType) {
    switch (birdType) {
      case BirdType.blue:
        FlameAudio.play('Audios-preparandoce-bird/Blue-preparandoce-Bird.mp3');
        break;
      case BirdType.red:
        FlameAudio.play('Audios-preparandoce-bird/Red-preparandoce-Bird.mp3');
        break;
      case BirdType.chuck:
        FlameAudio.play('Audios-preparandoce-bird/Chuck-preparandoce-Bird.mp3');
        break;
      case BirdType.boom:
        FlameAudio.play('Audios-preparandoce-bird/Boom-preparandoce-Bird.mp3');
        break;
      case BirdType.matilda: // <-- Agregado el caso que faltaba
        FlameAudio.play(
            'Audios-preparandoce-bird/Matilda-preparandoce-Bird.mp3');
        break;
    }
  }

  // Llama a esto cuando el jugador suelte el pájaro.
  void playBirdLaunchSound(BirdType birdType) {
    switch (birdType) {
      case BirdType.blue:
        FlameAudio.play('Audio-lanzandoce-bird/Blue-lanzandoce-Bird.mp3');
        break;
      case BirdType.red:
        FlameAudio.play('Audio-lanzandoce-bird/Red-lanzandoce-Bird.mp3');
        break;
      case BirdType.chuck:
        FlameAudio.play('Audio-lanzandoce-bird/Chuck-lanzandoce-Bird.mp3');
        break;
      case BirdType.boom:
        FlameAudio.play('Audio-lanzandoce-bird/Boom-lanzandoce-Bird.mp3');
        break;
      case BirdType.matilda:
        FlameAudio.play('Audio-lanzandoce-bird/Matilda-lanzandoce-Bird.mp3');
        break;
    }
  }

  // Llama a esto en la lógica de colisión cuando un cerdo es derrotado (en beginContact).
  void playPigDeathSound() {
    FlameAudio.play('Audio-muerte-pig/pig-Muerte-pig.mp3');
  }

  // --- Código Restante de tu Clase ---

  Future<void> addGround() {
    return world.addAll([
      for (var x = camera.visibleWorldRect.left;
          x < camera.visibleWorldRect.right + groundSize;
          x += groundSize)
        Ground(
          Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
          tiles.getSprite('grass.png'),
        ),
    ]);
  }

  final _random = Random();

  Future<void> addBricks() async {
    for (var i = 0; i < 5; i++) {
      final type = BrickType.randomType;
      final size = BrickSize.randomSize;
      await world.add(
        Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 5 - 2.5),
            0,
          ),
          sprites: brickFileNames(
            type,
            size,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> addPlayer() async {
    if (_birdQueue.isEmpty) return;
    final birdType = _birdQueue.removeAt(0);
    await world.add(
      Player(
        Vector2(camera.visibleWorldRect.left * 2 / 3, 0),
        birdType,
      ),
    );
    _updateNextBirdIndicator();
  }

  Future<void> _addNextBirdIndicator() async {
    if (_birdQueue.isEmpty) return;
    _nextBirdIndicator = NextBirdIndicator(game: this, position: Vector2(camera.visibleWorldRect.left + 5, camera.visibleWorldRect.top + 5));
    await add(_nextBirdIndicator!);
    _updateNextBirdIndicator();
  }

  void _updateNextBirdIndicator() {
    if (_birdQueue.isNotEmpty) {
      _nextBirdIndicator?.setBird(_birdQueue.first);
    } else {
      _nextBirdIndicator?.setBird(null);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isMounted &&
        world.children.whereType<Player>().isEmpty &&
        world.children.whereType<Enemy>().isNotEmpty) {
      addPlayer();
    }
    if (isMounted &&
        enemiesFullyAdded &&
        world.children.whereType<Enemy>().isEmpty &&
        world.children.whereType<TextComponent>().isEmpty) {
      world.addAll(
        [
          (position: Vector2(0.5, 0.5), color: Colors.white),
          (position: Vector2.zero(), color: Colors.orangeAccent),
        ].map(
          (e) => TextComponent(
            text: 'You win!',
            anchor: Anchor.center,
            position: e.position,
            textRenderer: TextPaint(
              style: TextStyle(color: e.color, fontSize: 16),
            ),
          ),
        ),
      );
    }
  }

  var enemiesFullyAdded = false;

  Future<void> addEnemies() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    for (var i = 0; i < 3; i++) {
      await world.add(
        Enemy(
          Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 7 - 3.5),
            (_random.nextDouble() * 3),
          ),
          PigType.random,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    enemiesFullyAdded = true;
  }
}

class NextBirdIndicator extends PositionComponent {
  NextBirdIndicator({required this.game, required Vector2 position})
      : super(position: position);

  final MyPhysicsGame game;
  BirdType? _birdType;
  SpriteComponent? _spriteComponent;

  void setBird(BirdType? birdType) {
    _birdType = birdType;
    _updateSprite();
  }

  void _updateSprite() async {
    if (_spriteComponent != null) {
      remove(_spriteComponent!);
    }

    if (_birdType != null) {
      final sprite = await game.loadSprite(_birdType!.asset);
      _spriteComponent = SpriteComponent(sprite: sprite, size: Vector2.all(50));
      add(_spriteComponent!);
    }
  }
}

