import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:octominia/models/order.dart';
import 'package:octominia/models/faction.dart';
import 'package:octominia/models/unit.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'octominia.db');

    return await openDatabase(
      path,
      version: 4, // <-- Revertir la version à 4 si la table 'games' était la seule raison de la version 5
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE factions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        order_id INTEGER NOT NULL,
        description TEXT,
        image_url TEXT,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE units(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        faction_id INTEGER NOT NULL,
        points_cost INTEGER NOT NULL,
        movement TEXT,
        wounds INTEGER,
        save INTEGER,
        control INTEGER,
        flavour_text TEXT,
        image_url TEXT,
        FOREIGN KEY (faction_id) REFERENCES factions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE keywords(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword_text TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE unit_keywords(
        unit_id INTEGER NOT NULL,
        keyword_id INTEGER NOT NULL,
        PRIMARY KEY (unit_id, keyword_id),
        FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE,
        FOREIGN KEY (keyword_id) REFERENCES keywords(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE abilities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        ability_type TEXT,
        cast_value INTEGER,
        range TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE unit_abilities(
        unit_id INTEGER NOT NULL,
        ability_id INTEGER NOT NULL,
        PRIMARY KEY (unit_id, ability_id),
        FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE,
        FOREIGN KEY (ability_id) REFERENCES abilities(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE weapons(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        range TEXT,
        attacks TEXT,
        to_hit TEXT,
        to_wound TEXT,
        rend TEXT,
        damage TEXT,
        weapon_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE unit_weapons(
        unit_id INTEGER NOT NULL,
        weapon_id INTEGER NOT NULL,
        PRIMARY KEY (unit_id, weapon_id),
        FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE,
        FOREIGN KEY (weapon_id) REFERENCES weapons(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE my_collection(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_id INTEGER NOT NULL UNIQUE,
        on_sprue_qty INTEGER NOT NULL DEFAULT 0,
        assembled_unpainted_qty INTEGER NOT NULL DEFAULT 0,
        painted_qty INTEGER NOT NULL DEFAULT 0,
        desired_qty INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE
      )
    ''');

  }

  @override
  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  @override
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      print('Migrating DB from version $oldVersion to 2');
      await db.execute('ALTER TABLE factions RENAME TO factions_old');
      await db.execute('''
        CREATE TABLE factions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          order_id INTEGER NOT NULL,
          description TEXT,
          FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('DROP TABLE IF EXISTS factions_old');
    }

    if (oldVersion < 3) {
      print('Migrating DB from version $oldVersion to 3 (adding image_url)');
      await db.execute('ALTER TABLE orders ADD COLUMN image_url TEXT');
      await db.execute('ALTER TABLE factions ADD COLUMN image_url TEXT');
      print('Added image_url column to orders and factions tables.');
    }

    if (oldVersion < 4) {
      print('Migrating DB from version $oldVersion to 4 (adding UUIDs and recreating tables)');
      await db.execute('DROP TABLE IF EXISTS my_collection');
      await db.execute('DROP TABLE IF EXISTS unit_weapons');
      await db.execute('DROP TABLE IF EXISTS weapons');
      await db.execute('DROP TABLE IF EXISTS unit_abilities');
      await db.execute('DROP TABLE IF EXISTS abilities');
      await db.execute('DROP TABLE IF EXISTS unit_keywords');
      await db.execute('DROP TABLE IF EXISTS keywords');
      await db.execute('DROP TABLE IF EXISTS units');
      await db.execute('DROP TABLE IF EXISTS factions');
      await db.execute('DROP TABLE IF EXISTS orders');

      await _createAllTables(db); // Appelle la méthode qui contient le nouveau schéma
      print('Tables recréées avec le schéma de la version 4.');
    }

  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('orders');
    await db.delete('factions');
    await db.delete('units');
    await db.delete('keywords');
    await db.delete('unit_keywords');
    await db.delete('abilities');
    await db.delete('unit_abilities');
    await db.delete('weapons');
    await db.delete('unit_weapons');
    await db.delete('my_collection');
    // await db.delete('games'); // <-- Supprimez la suppression des données de la table games
    print("Toutes les données ont été supprimées des tables (sauf games).");
  }

  Future<void> synchronizeGameData() async {
    final db = await database;

    final Map<String, int> orderUuidToId = {};
    final Map<String, int> factionUuidToId = {};

    // 1. Synchronisation des Ordres
    print('Synchronisation des ordres...');
    final String ordersJsonString = await rootBundle.loadString('assets/data/orders.json');
    final List<dynamic> ordersJson = json.decode(ordersJsonString);
    for (var orderData in ordersJson) {
      final Order newOrder = Order.fromJson(orderData);
      final existingOrder = await db.query('orders', where: 'uuid = ?', whereArgs: [newOrder.uuid]);

      if (existingOrder.isNotEmpty) {
        final Map<String, dynamic> updateMap = newOrder.toMap();
        updateMap.remove('id');

        await db.update(
          'orders',
          updateMap,
          where: 'uuid = ?',
          whereArgs: [newOrder.uuid],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        orderUuidToId[newOrder.uuid] = existingOrder.first['id'] as int;
      } else {
        final int id = await db.insert('orders', newOrder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        orderUuidToId[newOrder.uuid] = id;
      }
    }
    print('Ordres synchronisés. Mappage UUID->ID: $orderUuidToId');

    // 2. Synchronisation des Factions
    print('Synchronisation des factions...');
    final String factionsJsonString = await rootBundle.loadString('assets/data/factions.json');
    final List<dynamic> factionsJson = json.decode(factionsJsonString);
    for (var factionData in factionsJson) {
      final Faction newFaction = Faction.fromJson(factionData);

      final int? orderId = orderUuidToId[newFaction.orderUuid];
      if (orderId == null) {
        print('AVERTISSEMENT: Ordre avec UUID ${newFaction.orderUuid} non trouvé pour la faction ${newFaction.name}. Cette faction sera ignorée.');
        continue;
      }

      final Faction factionForDb = Faction(
        uuid: newFaction.uuid,
        name: newFaction.name,
        orderUuid: newFaction.orderUuid,
        orderId: orderId,
        description: newFaction.description,
        imageUrl: newFaction.imageUrl,
      );

      final existingFaction = await db.query('factions', where: 'uuid = ?', whereArgs: [newFaction.uuid]);

      if (existingFaction.isNotEmpty) {
        final Map<String, dynamic> updateMap = factionForDb.toMap();
        updateMap.remove('id');

        await db.update(
          'factions',
          updateMap,
          where: 'uuid = ?',
          whereArgs: [newFaction.uuid],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        factionUuidToId[newFaction.uuid] = existingFaction.first['id'] as int;
      } else {
        final int id = await db.insert('factions', factionForDb.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        factionUuidToId[newFaction.uuid] = id;
      }
    }
    print('Factions synchronisées. Mappage UUID->ID: $factionUuidToId');

    print('Synchronisation des unités...');
    final String unitsJsonString = await rootBundle.loadString('assets/data/units.json');
    final List<dynamic> unitsJson = json.decode(unitsJsonString);
    for (var unitData in unitsJson) {
      final Unit newUnit = Unit.fromJson(unitData);

      final int? factionId = factionUuidToId[newUnit.factionUuid];
      if (factionId == null) {
        print('AVERTISSEMENT: Faction avec UUID ${newUnit.factionUuid} non trouvée pour l\'unité ${newUnit.name}. Cette unité sera ignorée.');
        continue;
      }

      final Unit unitForDb = Unit(
        uuid: newUnit.uuid,
        name: newUnit.name,
        factionUuid: newUnit.factionUuid,
        factionId: factionId,
        pointsCost: newUnit.pointsCost,
        movement: newUnit.movement,
        wounds: newUnit.wounds,
        save: newUnit.save,
        control: newUnit.control,
        flavourText: newUnit.flavourText,
        imageUrl: newUnit.imageUrl,
      );

      final existingUnit = await db.query('units', where: 'uuid = ?', whereArgs: [newUnit.uuid]);

      if (existingUnit.isNotEmpty) {
        final Map<String, dynamic> updateMap = unitForDb.toMap();
        updateMap.remove('id');

        await db.update(
          'units',
          updateMap,
          where: 'uuid = ?',
          whereArgs: [newUnit.uuid],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await db.insert('units', unitForDb.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    print('Unités synchronisées.');
  }

  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('orders', order, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.query('orders');
  }

  Future<int> insertFaction(Map<String, dynamic> faction) async {
    final db = await database;
    return await db.insert('factions', faction, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Faction>> getFactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('factions');
    return List.generate(maps.length, (i) {
      return Faction.fromMap(maps[i]);
    });
  }

  Future<int> insertUnit(Map<String, dynamic> unit) async {
    final db = await database;
    return await db.insert('units', unit, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnits() async {
    final db = await database;
    return await db.query('units');
  }

  Future<List<Map<String, dynamic>>> getUnitsByFactionId(int factionId) async {
    final db = await database;
    return await db.query(
      'units',
      where: 'faction_id = ?',
      whereArgs: [factionId],
      orderBy: 'name ASC',
    );
  }

  Future<Unit?> getUnitById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'units',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Unit.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertKeyword(Map<String, dynamic> keyword) async {
    final db = await database;
    return await db.insert('keywords', keyword, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertUnitKeyword(int unitId, int keywordId) async {
    final db = await database;
    return await db.insert('unit_keywords', {'unit_id': unitId, 'keyword_id': keywordId});
  }

  Future<List<Map<String, dynamic>>> getUnitKeywords(int unitId) async {
    final db = await database;
    return await db.query(
      'unit_keywords',
      where: 'unit_id = ?',
      whereArgs: [unitId],
    );
  }

  Future<int> insertAbility(Map<String, dynamic> ability) async {
    final db = await database;
    return await db.insert('abilities', ability, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertUnitAbility(int unitId, int abilityId) async {
    final db = await database;
    return await db.insert('unit_abilities', {'unit_id': unitId, 'ability_id': abilityId});
  }

  Future<int> insertWeapon(Map<String, dynamic> weapon) async {
    final db = await database;
    return await db.insert('weapons', weapon, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertUnitWeapon(int unitId, int weaponId) async {
    final db = await database;
    return await db.insert('unit_weapons', {'unit_id': unitId, 'weapon_id': weaponId});
  }

  Future<int> insertMyCollectionItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('my_collection', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMyCollectionItem(Map<String, dynamic> itemMap) async {
    final db = await database;
    return await db.update(
      'my_collection',
      itemMap,
      where: 'unit_id = ?',
      whereArgs: [itemMap['unit_id']],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMyCollectionItems() async {
    final db = await database;
    return await db.query('my_collection');
  }

  Future<int> deleteMyCollectionItem(int id) async {
    final db = await database;
    return await db.delete(
      'my_collection',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}