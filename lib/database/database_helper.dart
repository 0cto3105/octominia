import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:octominia/models/order.dart';
import 'package:octominia/models/faction.dart';
import 'package:octominia/models/unit.dart';
import 'package:octominia/models/keyword.dart';
import 'package:octominia/models/ability.dart';
import 'package:octominia/models/weapon.dart';
import 'package:octominia/models/my_collection_item.dart';

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
      // *** IMPORTANT : Incrémenter la version de la BDD ***
      version: 3, // Passe à la version 3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Création de la table Orders (MODIFIÉE : ajout de image_url)
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        image_url TEXT -- Nouvelle colonne
      )
    ''');

    // Création de la table Factions (MODIFIÉE : ajout de order_id ET image_url)
    await db.execute('''
      CREATE TABLE factions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        order_id INTEGER NOT NULL,
        description TEXT,
        image_url TEXT, -- Nouvelle colonne
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    // (Le reste des créations de tables est inchangé)
    await db.execute('''
      CREATE TABLE units(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        faction_id INTEGER NOT NULL,
        points_cost INTEGER NOT NULL,
        movement INTEGER,
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

  // Fonction de migration
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
      final orderIdOrder = await db.insert('orders', {'name': 'Order', 'description': 'Forces of good and civilization'});
      final orderIdChaos = await db.insert('orders', {'name': 'Chaos', 'description': 'Followers of the Dark Gods'});
      final orderIdDeath = await db.insert('orders', {'name': 'Death', 'description': 'Armies of the Undead and Necromancers'});
      final orderIdDestruction = await db.insert('orders', {'name': 'Destruction', 'description': 'Brutal and warlike hordes'});

      await db.execute('''
        INSERT INTO factions (id, name, order_id, description)
        SELECT id, name, ?, description FROM factions_old
      ''', [orderIdOrder]);
      await db.execute('DROP TABLE factions_old');
    }
    
    // *** NOUVELLE LOGIQUE DE MIGRATION POUR LA VERSION 3 ***
    if (oldVersion < 3) {
      print('Migrating DB from version $oldVersion to 3 (adding image_url)');
      // Ajouter la colonne 'image_url' à la table 'orders'
      await db.execute('ALTER TABLE orders ADD COLUMN image_url TEXT');
      // Ajouter la colonne 'image_url' à la table 'factions'
      await db.execute('ALTER TABLE factions ADD COLUMN image_url TEXT');
      print('Added image_url column to orders and factions tables.');
    }
    // Ajoutez d'autres blocs 'if (oldVersion < X)' pour les futures migrations
  }

  // --- NOUVELLE MÉTHODE : Orders ---
  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('orders', order, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.query('orders', orderBy: 'name');
  }

  // --- Factions (méthodes inchangées, mais gèrent maintenant 'order_id' et 'image_url') ---
  Future<int> insertFaction(Map<String, dynamic> faction) async {
    final db = await database;
    return await db.insert('factions', faction, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getFactions() async {
    final db = await database;
    return await db.query('factions');
  }

  // --- Units (méthodes inchangées) ---
  Future<int> insertUnit(Map<String, dynamic> unit) async {
    final db = await database;
    return await db.insert('units', unit, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnits() async {
    final db = await database;
    return await db.query('units');
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

  // --- Keywords ---
  Future<int> insertKeyword(Map<String, dynamic> keyword) async {
    final db = await database;
    return await db.insert('keywords', keyword, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Unit_Keywords (liaison)
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

  // --- Abilities ---
  Future<int> insertAbility(Map<String, dynamic> ability) async {
    final db = await database;
    return await db.insert('abilities', ability, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Unit_Abilities (liaison)
  Future<int> insertUnitAbility(int unitId, int abilityId) async {
    final db = await database;
    return await db.insert('unit_abilities', {'unit_id': unitId, 'ability_id': abilityId});
  }

  // --- Weapons ---
  Future<int> insertWeapon(Map<String, dynamic> weapon) async {
    final db = await database;
    return await db.insert('weapons', weapon, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Unit_Weapons (liaison)
  Future<int> insertUnitWeapon(int unitId, int weaponId) async {
    final db = await database;
    return await db.insert('unit_weapons', {'unit_id': unitId, 'weapon_id': weaponId});
  }

  // --- MyCollection ---
  Future<int> insertMyCollectionItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('my_collection', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMyCollectionItems() async {
    final db = await database;
    return await db.query('my_collection');
  }

  Future<int> updateMyCollectionItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.update(
      'my_collection',
      item,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
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