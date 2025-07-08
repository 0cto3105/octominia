import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/faction.dart';
import 'package:octominia/models/order.dart';
import 'package:octominia/models/unit.dart';

class FactionsScreen extends StatefulWidget {
  const FactionsScreen({super.key});

  @override
  State<FactionsScreen> createState() => _FactionsScreenState();
}

class _FactionsScreenState extends State<FactionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Order> _orders = [];
  Map<int, List<Faction>> _factionsByOrder = {};
  Map<int, List<Unit>> _unitsByFaction = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final allOrders = (await _dbHelper.getOrders()).map((map) => Order.fromMap(map)).toList();
    allOrders.sort((a, b) => a.name.compareTo(b.name));
    _orders = allOrders;

    final allFactions = (await _dbHelper.getFactions()).map((map) => Faction.fromMap(map.toMap())).toList();
    allFactions.sort((a, b) => a.name.compareTo(b.name));

    Map<int, List<Faction>> groupedFactions = {};
    for (var order in allOrders) {
      groupedFactions[order.id!] = allFactions.where((faction) => faction.orderId == order.id).toList();
    }
    _factionsByOrder = groupedFactions;

    final allUnits = (await _dbHelper.getUnits()).map((map) => Unit.fromMap(map)).toList();
    allUnits.sort((a, b) => a.name.compareTo(b.name));

    Map<int, List<Unit>> groupedUnits = {};
    for (var faction in allFactions) {
      groupedUnits[faction.id!] = allUnits.where((unit) => unit.factionId == faction.id).toList();
    }
    _unitsByFaction = groupedUnits;

    setState(() {});
  }

  // Widget réutilisé pour l'en-tête de l'ExpansionTile avec image de fond
  // C'est le même que dans collection_screen.dart pour la cohérence
  Widget _buildExpansionTileHeader({
    required String title,
    String? imageUrl,
    required Widget child,
    bool isOrder = false,
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: imageUrl != null && imageUrl.isNotEmpty
            ? BoxDecoration(
                image: DecorationImage(
                 image: AssetImage(imageUrl), // <-- C'est ça !
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(isOrder ? 0.4 : 0.5),
                    BlendMode.darken,
                  ),
                ),
              )
            : null,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text(
            title,
            style: TextStyle(
              fontSize: isOrder ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
              ],
            ),
          ),
          children: [
            Container(
              color: Colors.black.withOpacity(0.3),
              padding: isOrder ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factions et Unités'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _orders.isEmpty
          ? const Center(child: Text('Chargement des données ou aucune donnée disponible.'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, orderIndex) {
                final order = _orders[orderIndex];
                final factionsInOrder = _factionsByOrder[order.id!] ?? [];

                if (factionsInOrder.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _buildExpansionTileHeader(
                  title: order.name,
                  imageUrl: order.imageUrl,
                  isOrder: true,
                  initiallyExpanded: true,
                  child: Column(
                    children: factionsInOrder.map((faction) {
                      final unitsInFaction = _unitsByFaction[faction.id!] ?? [];

                      if (unitsInFaction.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _buildExpansionTileHeader(
                        title: faction.name,
                        imageUrl: faction.imageUrl,
                        isOrder: false,
                        initiallyExpanded: false,
                        child: Column(
                          children: unitsInFaction.map((unit) {
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (unit.imageUrl != null && unit.imageUrl!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 12.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8.0),
                                              child: Image.network(
                                                unit.imageUrl!,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60),
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            unit.name,
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Coût en points: ${unit.pointsCost}', style: const TextStyle(fontSize: 14)),
                                    Text('Mouvement: ${unit.movement}"', style: const TextStyle(fontSize: 14)),
                                    Text('Blessures: ${unit.wounds}', style: const TextStyle(fontSize: 14)),
                                    Text('Sauvegarde: ${unit.save}+', style: const TextStyle(fontSize: 14)),
                                    Text('Contrôle: ${unit.control}', style: const TextStyle(fontSize: 14)),
                                    if (unit.flavourText != null && unit.flavourText!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          unit.flavourText!,
                                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllData,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}