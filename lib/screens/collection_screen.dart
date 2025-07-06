import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/order.dart';
import 'package:octominia/models/faction.dart';
import 'package:octominia/models/unit.dart';
import 'package:octominia/models/my_collection_item.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Order> _orders = [];
  Map<int, List<Faction>> _factionsByOrder = {};
  Map<int, List<Unit>> _unitsByFaction = {};
  Map<int, MyCollectionItem> _myCollectionMap = {};

  @override
  void initState() {
    super.initState();
    _initializeDataAndLoad();
  }

  Future<void> _initializeDataAndLoad() async {
    await _insertInitialDataForOrdersAndFactions();
    await _loadAllStockData();
  }

  Future<void> _insertInitialDataForOrdersAndFactions() async {
    final existingOrders = await _dbHelper.getOrders();
    if (existingOrders.isEmpty) {
      print('Insertion des Ordres et Factions initiaux avec images...');
      
      // URLs d'images pour les Ordres (exemples)
      // J'ai choisi des images génériques et j'ai cherché des sources publiques/faciles d'accès.
      // Vous devrez trouver vos propres images de haute qualité et les héberger ou les inclure en assets.
      final orderId = await _dbHelper.insertOrder(Order(name: 'Order', description: 'Forces de l\'Ordre', imageUrl: 'assets/images/grand_alliances/grand_alliance_order').toMap());
      final chaosId = await _dbHelper.insertOrder(Order(name: 'Chaos', description: 'Disciples des Dieux Sombres', imageUrl: 'assets/images/grand_alliances/grand_alliance_chaos').toMap());
      final deathId = await _dbHelper.insertOrder(Order(name: 'Death', description: 'Armées des Morts-Vivants', imageUrl: 'assets/images/grand_alliances/grand_alliance_death').toMap());
      final destructionId = await _dbHelper.insertOrder(Order(name: 'Destruction', description: 'Hordes brutales et belliqueuses', imageUrl: 'assets/images/grand_alliances/grand_alliance_destruction').toMap());

      // URLs d'images pour les Factions (exemples)
      await _dbHelper.insertFaction(Faction(name: 'Seraphon', orderId: orderId, description: 'Guerriers reptiliens des Hommes-Lézards', imageUrl: 'https://www.warhammer-community.com/wp-content/uploads/2023/04/kMngLwI0q354eR3B.jpg').toMap());
      await _dbHelper.insertFaction(Faction(name: 'Stormcast Eternals', orderId: orderId, description: 'Guerriers d\'élite de Sigmar', imageUrl: 'https://images.hobbyconsolas.com/extra/warhammer-age-sigmar/stormcast-eternals.jpg').toMap());
      await _dbHelper.insertFaction(Faction(name: 'Cities of Sigmar', orderId: orderId, description: 'Établissements humains et aelven', imageUrl: 'https://www.warhammer-community.com/wp-content/uploads/2023/08/Q399yVq0lV1vF06S.jpg').toMap());
      await _dbHelper.insertFaction(Faction(name: 'Skaven', orderId: chaosId, description: 'Hommes-rats de l\'Under-empire', imageUrl: 'https://www.warhammer-community.com/wp-content/uploads/2024/03/E652T65F9wD56gO7.jpg').toMap());
      await _dbHelper.insertFaction(Faction(name: 'Nighthaunt', orderId: deathId, description: 'Légions spectrales de Nagash', imageUrl: 'https://images.hobbyconsolas.com/extra/warhammer-age-sigmar/nighthaunt.jpg').toMap());
      await _dbHelper.insertFaction(Faction(name: 'Orruk Warclans', orderId: destructionId, description: 'Orruks et Grots brutaux', imageUrl: 'https://www.warhammer-community.com/wp-content/uploads/2024/05/D08316R9H208L34X.jpg').toMap());

      final existingUnits = await _dbHelper.getUnits();
      if (existingUnits.isEmpty) {
        final seraphon = (await _dbHelper.getFactions()).firstWhere((f) => Faction.fromMap(f).name == 'Seraphon');
        final stormcast = (await _dbHelper.getFactions()).firstWhere((f) => Faction.fromMap(f).name == 'Stormcast Eternals');
        final skaven = (await _dbHelper.getFactions()).firstWhere((f) => Faction.fromMap(f).name == 'Skaven');

        await _dbHelper.insertUnit(Unit(
          name: 'Lord Kroak',
          factionId: Faction.fromMap(seraphon).id!,
          pointsCost: 400, movement: 4, wounds: 8, save: 3, control: 10,
          flavourText: 'Ancien Mage-Prêtre Slann',
          imageUrl: 'https://wahapedia.ru/aos4/factions/seraphon/Lord-Kroak.webp'
        ).toMap());

        await _dbHelper.insertUnit(Unit(
          name: 'Saurus Warrior Squad',
          factionId: Faction.fromMap(seraphon).id!,
          pointsCost: 100, movement: 5, wounds: 1, save: 4, control: 7,
          flavourText: 'Infanterie de première ligne durable', imageUrl: ''
        ).toMap());

        await _dbHelper.insertUnit(Unit(
          name: 'Liberators',
          factionId: Faction.fromMap(stormcast).id!,
          pointsCost: 120, movement: 5, wounds: 2, save: 3, control: 8,
          flavourText: 'Infanterie Stormcast de base', imageUrl: ''
        ).toMap());

        await _dbHelper.insertUnit(Unit(
          name: 'Clanrats',
          factionId: Faction.fromMap(skaven).id!,
          pointsCost: 80, movement: 6, wounds: 1, save: 5, control: 6,
          flavourText: 'Hordes innombrables de Skaven', imageUrl: ''
        ).toMap());
        print('Unités initiales insérées.');
      }
      print('Ordres et Factions initiaux insérés.');
    } else {
      print('La base de données contient déjà des Ordres et Factions, insertion initiale ignorée.');
    }
  }

  Future<void> _loadAllStockData() async {
    final allOrders = (await _dbHelper.getOrders()).map((map) => Order.fromMap(map)).toList();
    allOrders.sort((a, b) => a.name.compareTo(b.name));
    _orders = allOrders;

    final allFactions = (await _dbHelper.getFactions()).map((map) => Faction.fromMap(map)).toList();
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

    final allCollectionItems = (await _dbHelper.getMyCollectionItems()).map((map) => MyCollectionItem.fromMap(map)).toList();
    _myCollectionMap = {for (var item in allCollectionItems) item.unitId: item};

    setState(() {});
  }

  Future<void> _updateQuantity({
    required int unitId,
    required String quantityType,
    required int change,
  }) async {
    MyCollectionItem? existingItem = _myCollectionMap[unitId];
    
    if (existingItem == null) {
      existingItem = MyCollectionItem(unitId: unitId);
    }

    switch (quantityType) {
      case 'onSprue':
        existingItem.onSprueQty = (existingItem.onSprueQty + change).clamp(0, 999);
        break;
      case 'assembled':
        existingItem.assembledUnpaintedQty = (existingItem.assembledUnpaintedQty + change).clamp(0, 999);
        break;
      case 'painted':
        existingItem.paintedQty = (existingItem.paintedQty + change).clamp(0, 999);
        break;
      case 'desired':
        existingItem.desiredQty = (existingItem.desiredQty + change).clamp(0, 999);
        break;
    }

    if (existingItem.id == null) {
      final newId = await _dbHelper.insertMyCollectionItem(existingItem.toMap());
      existingItem.id = newId;
    } else {
      await _dbHelper.updateMyCollectionItem(existingItem.toMap());
    }
    
    _myCollectionMap[unitId] = existingItem;
    setState(() {});
  }

  Future<void> _showEditQuantitiesDialog(MyCollectionItem? existingItem, Unit unit) async {
    int onSprue = existingItem?.onSprueQty ?? 0;
    int assembled = existingItem?.assembledUnpaintedQty ?? 0;
    int painted = existingItem?.paintedQty ?? 0;
    int desired = existingItem?.desiredQty ?? 0;
    String notes = existingItem?.notes ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier le stock de ${unit.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: onSprue.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sur grappe'),
                  onChanged: (value) => onSprue = int.tryParse(value) ?? onSprue,
                ),
                TextFormField(
                  initialValue: assembled.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Montées / Non peintes'),
                  onChanged: (value) => assembled = int.tryParse(value) ?? assembled,
                ),
                TextFormField(
                  initialValue: painted.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Peintes'),
                  onChanged: (value) => painted = int.tryParse(value) ?? painted,
                ),
                TextFormField(
                  initialValue: desired.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Souhaité'),
                  onChanged: (value) => desired = int.tryParse(value) ?? desired,
                ),
                TextFormField(
                  initialValue: notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final itemToSave = existingItem ?? MyCollectionItem(unitId: unit.id!);
                itemToSave.onSprueQty = onSprue;
                itemToSave.assembledUnpaintedQty = assembled;
                itemToSave.paintedQty = painted;
                itemToSave.desiredQty = desired;
                itemToSave.notes = notes;

                if (itemToSave.id == null) {
                  await _dbHelper.insertMyCollectionItem(itemToSave.toMap());
                } else {
                  await _dbHelper.updateMyCollectionItem(itemToSave.toMap());
                }
                _loadAllStockData();
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuantityControl({
    required String label,
    required int value,
    required Function(int change) onChange,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onChange(-1),
                  child: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    value.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
                  ),
                ),
                GestureDetector(
                  onTap: () => onChange(1),
                  child: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nouveau widget pour l'en-tête de l'ExpansionTile avec image de fond
  Widget _buildExpansionTileHeader({
    required String title,
    String? imageUrl,
    required Widget child,
    bool isOrder = false, // Pour différencier le style des Ordres/Factions
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // Pour que le contenu soit rogné avec le border radius
      child: Container(
        decoration: imageUrl != null && imageUrl.isNotEmpty
            ? BoxDecoration(
                image: DecorationImage(
             image: AssetImage(imageUrl), // <-- C'est ça !
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(isOrder ? 0.4 : 0.5), // Opacité différente pour les ordres/factions
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
              color: Colors.white, // Texte en blanc pour contraster avec le fond sombre
              shadows: const [
                Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
              ],
            ),
          ),
          children: [
            Container( // Conteneur pour le contenu des enfants, potentiellement avec un fond semi-transparent
              color: Colors.black.withOpacity(0.3), // Fond sombre pour la lisibilité du texte enfant
              padding: isOrder ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0), // Padding pour les factions
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
        title: const Text('Ma Collection - Gestion des Stocks'),
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
                  child: Column( // Utilisez une Column pour les enfants de l'ExpansionTile
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
                        child: Column( // Utilisez une Column pour les enfants de l'ExpansionTile des factions
                          children: unitsInFaction.map((unit) {
                            final collectionItem = _myCollectionMap[unit.id] ?? MyCollectionItem(unitId: unit.id!);
                            final owned = collectionItem.totalOwnedQty;
                            final desired = collectionItem.desiredQty;
                            final difference = desired - owned;

                            String differenceText;
                            Color differenceColor;
                            if (difference > 0) {
                              differenceText = 'À acheter: $difference';
                              differenceColor = Colors.orange.shade700;
                            } else if (difference < 0) {
                              differenceText = 'À vendre: ${difference.abs()}';
                              differenceColor = Colors.red.shade700;
                            } else {
                              differenceText = 'Complété !';
                              differenceColor = Colors.green.shade700;
                            }

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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            unit.name,
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_note, size: 24, color: Colors.blueGrey),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showEditQuantitiesDialog(collectionItem, unit),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildQuantityControl(
                                      label: 'Sur grappe:',
                                      value: collectionItem.onSprueQty,
                                      onChange: (change) => _updateQuantity(
                                        unitId: unit.id!,
                                        quantityType: 'onSprue',
                                        change: change,
                                      ),
                                    ),
                                    _buildQuantityControl(
                                      label: 'Montées/Non peintes:',
                                      value: collectionItem.assembledUnpaintedQty,
                                      onChange: (change) => _updateQuantity(
                                        unitId: unit.id!,
                                        quantityType: 'assembled',
                                        change: change,
                                      ),
                                    ),
                                    _buildQuantityControl(
                                      label: 'Peintes:',
                                      value: collectionItem.paintedQty,
                                      onChange: (change) => _updateQuantity(
                                        unitId: unit.id!,
                                        quantityType: 'painted',
                                        change: change,
                                      ),
                                    ),
                                    _buildQuantityControl(
                                      label: 'Souhaité:',
                                      value: collectionItem.desiredQty,
                                      onChange: (change) => _updateQuantity(
                                        unitId: unit.id!,
                                        quantityType: 'desired',
                                        change: change,
                                      ),
                                    ),
                                    const Divider(height: 24, thickness: 1),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        differenceText,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: differenceColor),
                                      ),
                                    ),
                                    if (collectionItem.notes != null && collectionItem.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Notes: ${collectionItem.notes}',
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
        onPressed: _loadAllStockData,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

// Extension pour la méthode firstWhereOrNull qui facilite la recherche
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