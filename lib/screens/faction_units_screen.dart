// lib/screens/faction_units_screen.dart
import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/faction.dart';
import 'package:octominia/models/unit.dart';
import 'package:octominia/models/my_collection_item.dart';
import 'package:octominia/widgets/unit_item.dart'; // Assurez-vous que ce chemin est correct

class FactionUnitsScreen extends StatefulWidget {
  final Faction faction;

  const FactionUnitsScreen({super.key, required this.faction});

  @override
  State<FactionUnitsScreen> createState() => _FactionUnitsScreenState();
}

class _FactionUnitsScreenState extends State<FactionUnitsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Unit> _units = [];
  Map<int, MyCollectionItem> _myCollectionItemsMap = {};

  @override
  void initState() {
    super.initState();
    _loadUnitsAndCollectionItems();
  }

  Future<void> _loadUnitsAndCollectionItems() async {
    // Correction: Appelle la méthode getUnitsByFactionId de DatabaseHelper
    final unitsMaps = await _dbHelper.getUnitsByFactionId(widget.faction.id!);
    final allCollectionItemsMaps = await _dbHelper.getMyCollectionItems();

    // Correction: Convertit List<Map<String, dynamic>> en List<Unit>
    final List<Unit> units = unitsMaps.map((map) => Unit.fromMap(map)).toList();

    final Map<int, MyCollectionItem> tempMap = {};
    for (var itemMap in allCollectionItemsMaps) {
      // Correction: Convertit chaque Map en MyCollectionItem avant de l'ajouter à la map
      final item = MyCollectionItem.fromMap(itemMap);
      tempMap[item.unitId!] = item;
    }

    setState(() {
      _units = units;
      _myCollectionItemsMap = tempMap;
    });
  }

  // Gère la mise à jour d'un item de collection
  Future<void> _handleUnitCollectionItemUpdate(MyCollectionItem updatedItem) async {
    if (updatedItem.id == null) {
      // Pour l'insertion, on passe le Map<String, dynamic>
      final newId = await _dbHelper.insertMyCollectionItem(updatedItem.toMap());
      updatedItem.id = newId;
    } else {
      // Pour la mise à jour, on passe également le Map<String, dynamic>
      // La méthode updateMyCollectionItem de DatabaseHelper a été ajustée pour l'accepter
      await _dbHelper.updateMyCollectionItem(updatedItem.toMap());
    }
    // Met à jour la map locale.
    _myCollectionItemsMap[updatedItem.unitId!] = updatedItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.faction.name),
        backgroundColor: Colors.amberAccent[200],
        foregroundColor: Colors.black,
      ),
      body: _units.isEmpty
          ? const Center(child: Text('Aucune unité trouvée pour cette faction.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _units.length,
              itemBuilder: (context, index) {
                final unit = _units[index];
                // Récupère l'item existant ou crée un nouvel item par défaut
                final collectionItem =
                    _myCollectionItemsMap[unit.id] ?? MyCollectionItem(unitId: unit.id!);
                return UnitItem(
                  unit: unit,
                  initialCollectionItem: collectionItem,
                  onUpdateCollectionItem: _handleUnitCollectionItemUpdate,
                );
              },
            ),
    );
  }
}