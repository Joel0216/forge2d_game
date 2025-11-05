// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/game.dart';
import 'components/start_screen.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _showGame = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _showGame
          ? GameWidget.controlled(gameFactory: MyPhysicsGame.new)
          : StartScreen(
              onStartPressed: () {
                setState(() {
                  _showGame = true;
                });
              },
            ),
    );
  }
}
