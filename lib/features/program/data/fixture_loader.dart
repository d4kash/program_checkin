import 'dart:convert';

import 'package:flutter/services.dart';

abstract class FixtureLoader {
  Future<Map<String, dynamic>> load();
}

class AssetFixtureLoader implements FixtureLoader {
  const AssetFixtureLoader(this.assetPath);

  final String assetPath;

  @override
  Future<Map<String, dynamic>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

class MemoryFixtureLoader implements FixtureLoader {
  const MemoryFixtureLoader(this.fixture);

  final Map<String, dynamic> fixture;

  @override
  Future<Map<String, dynamic>> load() async => fixture;
}
