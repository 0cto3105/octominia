// lib/widgets/unit_item.dart
import 'package:flutter/material.dart';
import 'package:octominia/models/unit.dart';
import 'package:octominia/models/my_collection_item.dart';

// Nouveau StatefulWidget pour chaque unité, basé sur le design précédent
class UnitItem extends StatefulWidget {
  final Unit unit;
  final MyCollectionItem initialCollectionItem;
  final Function(MyCollectionItem item) onUpdateCollectionItem; // Callback pour sauvegarder

  const UnitItem({
    super.key,
    required this.unit,
    required this.initialCollectionItem,
    required this.onUpdateCollectionItem,
  });

  @override
  State<UnitItem> createState() => _UnitItemState();
}

class _UnitItemState extends State<UnitItem> {
  late MyCollectionItem _collectionItem; // État interne de l'unité

  @override
  void initState() {
    super.initState();
    _collectionItem = widget.initialCollectionItem; // Initialise avec la donnée passée
  }

  // Permet de mettre à jour l'item de collection si les données initiales changent
  @override
  void didUpdateWidget(covariant UnitItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCollectionItem != oldWidget.initialCollectionItem) {
      _collectionItem = widget.initialCollectionItem;
    }
  }


  Future<void> _updateQuantity({
    required String quantityType,
    required int change,
  }) async {
    // Crée une copie pour modifier et mettre à jour l'état
    MyCollectionItem updatedItem = MyCollectionItem.fromMap(_collectionItem.toMap());

    switch (quantityType) {
      case 'onSprue':
        updatedItem.onSprueQty = (updatedItem.onSprueQty + change).clamp(0, 999);
        break;
      case 'assembled':
        updatedItem.assembledUnpaintedQty = (updatedItem.assembledUnpaintedQty + change).clamp(0, 999);
        break;
      case 'painted':
        updatedItem.paintedQty = (updatedItem.paintedQty + change).clamp(0, 999);
        break;
      case 'desired':
        updatedItem.desiredQty = (updatedItem.desiredQty + change).clamp(0, 999);
        break;
    }

    setState(() {
      _collectionItem = updatedItem; // Met à jour l'état local
    });

    // Notifie le parent pour la sauvegarde dans la base de données
    widget.onUpdateCollectionItem(_collectionItem);
  }

  Widget _buildCompactQuantityControl({
    required String label,
    required int value,
    required Function(int change) onChange,
    required IconData icon, // NOUVEAU PARAMÈTRE POUR L'ICÔNE
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.black87), // AJOUT DE L'ICÔNE
        const SizedBox(height: 2), // ESPACEMENT ENTRE L'ICÔNE ET LE LABEL
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => onChange(-1),
              child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
            ),
            SizedBox(
              width: 28,
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onChange(1),
              child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final owned = _collectionItem.totalOwnedQty;
    final desired = _collectionItem.desiredQty;
    final difference = desired - owned;

    Color differenceColor;
    IconData differenceIcon; // NOUVEAU : Icône pour la différence

    if (difference > 0) {
      differenceColor = Colors.orange.shade700;
      differenceIcon = Icons.add_shopping_cart; // Icône pour "à acheter"
    } else if (difference < 0) {
      differenceColor = Colors.red.shade700;
      differenceIcon = Icons.sell; // Icône pour "à vendre"
    } else {
      differenceColor = Colors.green.shade700;
      differenceIcon = Icons.check_circle_outline; // Icône pour "OK"
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x339E9E9E), // Colors.grey avec 0.2 opacité
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image de l'unité
                if (widget.unit.imageUrl != null && widget.unit.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.asset(
                      widget.unit.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                const SizedBox(width: 12),
                // Nom de l'unité et chiffre de différence
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.unit.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: differenceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(color: differenceColor, width: 1.0),
                        ),
                        child: Row( // AJOUT D'UN ROW POUR L'ICÔNE ET LE TEXTE DE DIFFÉRENCE
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(differenceIcon, size: 18, color: differenceColor), // AJOUT DE L'ICÔNE
                            const SizedBox(width: 4), // ESPACEMENT
                            Text(
                              (difference > 0 ? '+' : '') + difference.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: differenceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildCompactQuantityControl(
                  label: 'Sur grappe',
                  value: _collectionItem.onSprueQty,
                  onChange: (change) => _updateQuantity(
                    quantityType: 'onSprue',
                    change: change,
                  ),
                  icon: Icons.widgets_outlined,
                ),
                _buildCompactQuantityControl(
                  label: 'Montées',
                  value: _collectionItem.assembledUnpaintedQty,
                  onChange: (change) => _updateQuantity(
                    quantityType: 'assembled',
                    change: change,
                  ),
                  icon: Icons.build_outlined,
                ),
                _buildCompactQuantityControl(
                  label: 'Peintes',
                  value: _collectionItem.paintedQty,
                  onChange: (change) => _updateQuantity(
                    quantityType: 'painted',
                    change: change,
                  ),
                  icon: Icons.brush_outlined,
                ),
                _buildCompactQuantityControl(
                  label: 'Souhaité',
                  value: _collectionItem.desiredQty,
                  onChange: (change) => _updateQuantity(
                    quantityType: 'desired',
                    change: change,
                  ),
                  icon: Icons.stars_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}