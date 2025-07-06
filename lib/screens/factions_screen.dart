// lib/screens/factions_screen.dart
import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/faction.dart';

class FactionsScreen extends StatefulWidget {
  const FactionsScreen({super.key});

  @override
  State<FactionsScreen> createState() => _FactionsScreenState();
}

class _FactionsScreenState extends State<FactionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Faction> _factions = [];

  @override
  void initState() {
    super.initState();
    _loadFactions();
  }

  Future<void> _loadFactions() async {
    final factions = (await _dbHelper.getFactions()).map((map) => Faction.fromMap(map)).toList();
    setState(() {
      _factions = factions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factions du Jeu'),
        automaticallyImplyLeading: false, // Cache le bouton retour
      ),
      body: _factions.isEmpty
          ? const Center(child: Text('Aucune faction trouvée. Insérez des données initiales.'))
          : ListView.builder(
              itemCount: _factions.length,
              itemBuilder: (context, index) {
                final faction = _factions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faction.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (faction.description != null && faction.description!.isNotEmpty)
                          Text(faction.description!),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFactions,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}