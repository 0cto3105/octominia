// lib/utils/app_initializer.dart
import 'package:flutter/services.dart';
import 'package:octominia/database/database_helper.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppInitializer {
  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await DatabaseHelper().database;
    await DatabaseHelper().synchronizeGameData();
  }
}