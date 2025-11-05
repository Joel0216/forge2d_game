// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';


import 'body_component_with_user_data.dart';

const enemySize = 5.0;

enum PigType {
  pig,
  kingpig;

  static PigType get random =>
      PigType.values[Random().nextInt(PigType.values.length)];

  String get fileName {
    switch (this) {
      case PigType.pig:
        return 'pig-Pig.png';
      case PigType.kingpig:
        return 'Kingpig-Pig.png';
    }
  }
}

class Enemy extends BodyComponentWithUserData with ContactCallbacks {
  Enemy(Vector2 position, this.pigType)
      : super(
          renderBody: false,
          bodyDef: BodyDef()
            ..position = position
            ..type = BodyType.dynamic,
          fixtureDefs: [
            FixtureDef(
              PolygonShape()..setAsBoxXY(enemySize / 2, enemySize / 2),
              friction: 0.3,
            ),
          ],
        );

  final PigType pigType;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final sprite = await game.loadSprite(pigType.fileName);


    add(SpriteComponent(
      anchor: Anchor.center,
      sprite: sprite,
      size: Vector2.all(enemySize),
      position: Vector2(0, 0),
    ));
  }

  @override
  void beginContact(Object other, Contact contact) {
    var interceptVelocity =
        (contact.bodyA.linearVelocity - contact.bodyB.linearVelocity).length
            .abs();
    if (interceptVelocity > 35) {
      removeFromParent();
    }

    super.beginContact(other, contact);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (position.x > camera.visibleWorldRect.right + 10 ||
        position.x < camera.visibleWorldRect.left - 10) {
      removeFromParent();
    }
  }
}

