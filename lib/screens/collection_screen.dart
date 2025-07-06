// lib/screens/collection_screen.dart
import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/models/my_collection_item.dart';
import 'package:octominia/models/unit.dart'; // Pour afficher le nom de l'unité

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<MyCollectionItem> _myCollectionItems = [];
  Map<int, Unit> _unitsMap = {}; // Pour un accès rapide aux noms d'unité

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    final collectionItems = (await _dbHelper.getMyCollectionItems()).map((map) => MyCollectionItem.fromMap(map)).toList();
    final units = (await _dbHelper.getUnits()).map((map) => Unit.fromMap(map)).toList();

    // Crée une map pour associer rapidement l'ID d'unité au nom d'unité
    _unitsMap = {for (var u in units) u.id!: u};

    setState(() {
      _myCollectionItems = collectionItems;
    });
  }

  // Fonction d'exemple pour ajouter/mettre à jour un item de collection
  // Dans une vraie app, cela viendrait d'un formulaire ou d'un bouton spécifique.
  Future<void> _addOrUpdateExampleCollectionItem() async {
    // Trouvez une unité existante (par exemple, "Space Marine Intercessor Squad")
    final intercessorUnit = _unitsMap.values.firstWhere(
      (unit) => unit.name == 'Space Marine Intercessor Squad',
      orElse: () => throw Exception('Intercessor Unit not found. Please insert initial units via UnitsScreen logic first.'),
    );

    // Vérifiez si l'unité est déjà dans la collection
    final existingItem = _myCollectionItems.firstWhereOrNull((item) => item.unitId == intercessorUnit.id);

    if (existingItem != null) {
      // Si elle existe, incrémentez le nombre de figurines montées/non peintes
      existingItem.assembledUnpaintedQty += 1;
      await _dbHelper.updateMyCollectionItem(existingItem.toMap());
      print('Updated Intercessor in collection: ${existingItem.totalOwnedQty}');
    } else {
      // Sinon, créez un nouvel élément de collection
      final newItem = MyCollectionItem(
        unitId: intercessorUnit.id!,
        assembledUnpaintedQty: 1, // On ajoute 1 figurine montée non peinte
        desiredQty: 5,           // On souhaite en avoir 5 au total
        notes: 'Mon premier intercessor monté!',
      );
      await _dbHelper.insertMyCollectionItem(newItem.toMap());
      print('Added Intercessor to collection: ${newItem.totalOwnedQty}');
    }
    await _loadCollection(); // Recharge les données pour mettre à jour l'affichage
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Collection'),
        automaticallyImplyLeading: false, // Cache le bouton retour
      ),
      body: _myCollectionItems.isEmpty
          ? const Center(child: Text('Votre collection est vide. Ajoutez des figurines!'))
          : ListView.builder(
              itemCount: _myCollectionItems.length,
              itemBuilder: (context, index) {
                final item = _myCollectionItems[index];
                final unit = _unitsMap[item.unitId]; // Obtenez l'unité correspondante
                final unitName = unit?.name ?? 'Unité Inconnue';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unitName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('Sur grappe: ${item.onSprueQty}'),
                        Text('Montées / Non peintes: ${item.assembledUnpaintedQty}'),
                        Text('Peintes: ${item.paintedQty}'),
                        Text('Total possédé: ${item.totalOwnedQty}'),
                        Text('Souhaité: ${item.desiredQty}'),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Text('Notes: ${item.notes}'),
                        // Exemple de boutons pour modifier (à développer)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                // Exemple: Ajouter 1 montée/non peinte
                                item.assembledUnpaintedQty += 1;
                                _dbHelper.updateMyCollectionItem(item.toMap()).then((_) => _loadCollection());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.colorize),
                              onPressed: () {
                                // Exemple: Déplacer de montée/non peinte à peinte
                                if (item.assembledUnpaintedQty > 0) {
                                  item.assembledUnpaintedQty -= 1;
                                  item.paintedQty += 1;
                                  _dbHelper.updateMyCollectionItem(item.toMap()).then((_) => _loadCollection());
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrUpdateExampleCollectionItem, // Pour ajouter/incrémenter l'Intercessor
        child: const Icon(Icons.add),
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