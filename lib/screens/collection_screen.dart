import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/order.dart';
import 'package:octominia/models/faction.dart';
import 'package:octominia/models/unit.dart';
import 'package:octominia/models/my_collection_item.dart';

import 'package:octominia/widgets/custom_expansion_panel.dart';
import 'package:octominia/screens/faction_units_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Order> _orders = [];
  Map<int, List<Faction>> _factionsByOrder = {};
  Map<int, List<Unit>> _unitsByFaction = {};
  Map<int, MyCollectionItem> _collectionItemsMap = {};

  Map<int, int> _factionToSellQty = {};
  Map<int, int> _factionToBuyQty = {};

  int? _expandedOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCollectionData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ignore: avoid_print
    print('AppLifecycleState changed: $state');
    if (state == AppLifecycleState.resumed) {
          // ignore: avoid_print
      print('App resumed: Reloading collection data. (via Lifecycle Observer)');
    }
  }

  Future<void> _loadCollectionData() async {
    final ordersData = await _dbHelper.getOrders();
    final factionsData = await _dbHelper.getFactions();
    final unitsData = await _dbHelper.getUnits();
    final allCollectionItems = await _dbHelper.getMyCollectionItems();

    final Map<int, List<Faction>> factionsByOrder = {};
    for (var factionMap in factionsData) {
      final faction = Faction.fromMap(factionMap.toMap());
      factionsByOrder.putIfAbsent(faction.orderId, () => []).add(faction);
    }

    final Map<int, List<Unit>> unitsByFaction = {};
    for (var unitMap in unitsData) {
      final unit = Unit.fromMap(unitMap);
        unitsByFaction.putIfAbsent(unit.factionId, () => []).add(unit);
    }

    final Map<int, MyCollectionItem> tempCollectionItemsMap = {
      for (var itemMap in allCollectionItems)
        MyCollectionItem.fromMap(itemMap).unitId: MyCollectionItem.fromMap(itemMap)
    };

    final Map<int, int> factionToSellQty = {};
    final Map<int, int> factionToBuyQty = {};

    for (var faction in factionsData.map((e) => Faction.fromMap(e.toMap()))) {
      int currentFactionToSell = 0;
      int currentFactionToBuy = 0;

      final unitsInFaction = unitsByFaction[faction.id] ?? [];
      for (var unit in unitsInFaction) {
        final collectionItem = tempCollectionItemsMap[unit.id];
        if (collectionItem != null) {
          final owned = collectionItem.totalOwnedQty;
          final desired = collectionItem.desiredQty;

          if (owned > desired) {
            currentFactionToSell += (owned - desired);
          } else if (desired > owned) {
            currentFactionToBuy += (desired - owned);
          }
        }
      }
      factionToSellQty[faction.id!] = currentFactionToSell;
      factionToBuyQty[faction.id!] = currentFactionToBuy;
    }

    setState(() {
      _orders = ordersData.map((map) => Order.fromMap(map)).toList();
      _factionsByOrder = factionsByOrder;
      _unitsByFaction = unitsByFaction;
      _collectionItemsMap = tempCollectionItemsMap;
      _factionToSellQty = factionToSellQty;
      _factionToBuyQty = factionToBuyQty;
    });
  }

  Future<void> _refreshData() async {
    await _loadCollectionData();
  }

  Widget _buildOrderHeader(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        order.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildFactionHeader(Faction faction) {
    final toSellQty = _factionToSellQty[faction.id] ?? 0;
    final toBuyQty = _factionToBuyQty[faction.id] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              faction.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Badge "À VENDRE"
          if (toSellQty > 0)
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sell, color: Colors.white, size: 16), // CHANGEMENT ICI : Icons.sell
                  const SizedBox(width: 4),
                  Text(
                    '$toSellQty',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          // Espacement entre les deux badges si les deux sont présents
          if (toSellQty > 0 && toBuyQty > 0)
            const SizedBox(width: 8.0),
          // Badge "À ACHETER"
          if (toBuyQty > 0)
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white, size: 16), // CHANGEMENT ICI : Icons.shopping_cart
                  const SizedBox(width: 4),
                  Text(
                    '$toBuyQty',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ma Collection - Gestion des Stocks',
          style: TextStyle(color: Colors.black),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.amberAccent[200],
        foregroundColor: Colors.black,
      ),
      body: _orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView.builder(
                key: const PageStorageKey<String>('collectionScreenList'),
                padding: const EdgeInsets.all(8.0),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final factionsInOrder = _factionsByOrder[order.id] ?? [];

                  if (factionsInOrder.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      CustomExpansionPanel(
                        header: _buildOrderHeader(order),
                        content: Column(
                          children: factionsInOrder.map((faction) {
                            return CustomExpansionPanel(
                              header: _buildFactionHeader(faction),
                              content: const SizedBox.shrink(),
                              initiallyExpanded: false,
                              headerHeight: 80,
                              imageUrl: faction.imageUrl,
                              isOrder: false,
                              margin: const EdgeInsets.only(bottom: 8.0),
                              borderRadius: BorderRadius.circular(12.0),
                              onHeaderTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FactionUnitsScreen(faction: faction),
                                  ),
                                );
                                await _loadCollectionData();
                                // ignore: avoid_print
                                print('Retour de FactionUnitsScreen: Données de collection rechargées.');
                              },
                            );
                          }).toList(),
                        ),
                        initiallyExpanded: order.id == _expandedOrderId,
                        headerHeight: 120,
                        imageUrl: order.imageUrl,
                        isOrder: true,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        borderRadius: BorderRadius.circular(12.0),
                        onExpansionChanged: (isExpanded) {
                          setState(() {
                            if (isExpanded) {
                              _expandedOrderId = order.id;
                            } else {
                              _expandedOrderId = null;
                            }
                          });
                        },
                      ),
                      if (factionsInOrder.isNotEmpty && order != _orders.last)
                        const SizedBox(height: 8.0),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

// Extension pour trouver le premier élément ou null dans une liste (si vous l'utilisez toujours)
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}