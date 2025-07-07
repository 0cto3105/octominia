// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/my_collection_item.dart';
import 'package:octominia/models/unit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // Changez _DashboardScreenState en DashboardScreenState
  State<DashboardScreen> createState() => DashboardScreenState();
}

// Retirez le underscore devant DashboardScreenState pour la rendre publique
class DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _itemsToBuy = [];
  List<Map<String, dynamic>> _itemsToSell = [];
  bool _isLoading = true; // Gère l'état de chargement

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Rendez cette méthode publique pour qu'elle puisse être appelée depuis MainScreen
  Future<void> refreshData() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_isLoading && _itemsToBuy.isNotEmpty && _itemsToSell.isNotEmpty) {
      // Si déjà en chargement et des données existent déjà (pas un chargement initial),
      // nous n'affichons pas l'indicateur de chargement pour éviter le clignotement.
    } else {
      setState(() {
        _isLoading = true; // Indique que le chargement a commencé
      });
    }

    final allCollectionItems = (await _dbHelper.getMyCollectionItems())
        .map((map) => MyCollectionItem.fromMap(map))
        .toList();
    final allUnits = (await _dbHelper.getUnits())
        .map((map) => Unit.fromMap(map))
        .toList();
    final Map<int, Unit> unitsMap = {for (var unit in allUnits) unit.id!: unit};

    List<Map<String, dynamic>> toBuy = [];
    List<Map<String, dynamic>> toSell = [];

    for (var item in allCollectionItems) {
      final unit = unitsMap[item.unitId];
      if (unit == null) continue;

      final difference = item.desiredQty - item.totalOwnedQty;

      if (difference > 0) {
        toBuy.add({
          'unitName': unit.name,
          'quantity': difference,
        });
      } else if (difference < 0) {
        toSell.add({
          'unitName': unit.name,
          'quantity': -difference,
        });
      }
    }

    toBuy.sort((a, b) => a['unitName'].compareTo(b['unitName']));
    toSell.sort((a, b) => a['unitName'].compareTo(b['unitName']));

    setState(() {
      _itemsToBuy = toBuy;
      _itemsToSell = toSell;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Collection'),
        backgroundColor: Colors.amberAccent[200],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
                onRefresh: refreshData,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSectionTitle(context, 'Figurines à acheter'),
                    if (_itemsToBuy.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Aucune figurine à acheter pour le moment.'),
                      )
                    else
                      ..._itemsToBuy.map((item) => _buildRecapItem(
                            item['unitName'],
                            item['quantity'],
                            Colors.orange.shade700,
                          )),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Figurines à vendre'),
                    if (_itemsToSell.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Aucune figurine en surplus à vendre.'),
                      )
                    else
                      ..._itemsToSell.map((item) => _buildRecapItem(
                            item['unitName'],
                            item['quantity'],
                            Colors.red.shade700,
                          )),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.headlineSmall?.color,
        ),
      ),
    );
  }

  Widget _buildRecapItem(String name, int quantity, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: color, width: 1.0),
              ),
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}