// lib/screens/units_screen.dart
import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/unit.dart';
import 'package:octominia/models/faction.dart'; // Pour afficher le nom de la faction

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Unit> _units = [];
  Map<int, Faction> _factionsMap = {}; // Pour un accès rapide aux noms de faction

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final units = (await _dbHelper.getUnits()).map((map) => Unit.fromMap(map)).toList();
    final factions = (await _dbHelper.getFactions()).map((map) => Faction.fromMap(map.toMap())).toList();

    // Crée une map pour associer rapidement l'ID de faction au nom de faction
    _factionsMap = {for (var f in factions) f.id!: f};

    setState(() {
      _units = units;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unités du Jeu'),
        automaticallyImplyLeading: false, // Cache le bouton retour sur cet écran
      ),
      body: _units.isEmpty
          ? const Center(child: Text('Aucune unité trouvée. Insérez des données initiales.'))
          : ListView.builder(
              itemCount: _units.length,
              itemBuilder: (context, index) {
                final unit = _units[index];
                final factionName = _factionsMap[unit.factionId]?.name ?? 'Inconnue';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Faction: $factionName'),
                        Text('Coût en points: ${unit.pointsCost}'),
                        Text('M: ${unit.movement}, B: ${unit.wounds}, Sv: ${unit.save}, Ctrl: ${unit.control}'),
                        // Vous pouvez ajouter plus de détails ici si nécessaire
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUnits, // Permet de rafraîchir la liste
        child: const Icon(Icons.refresh),
      ),
    );
  }
}