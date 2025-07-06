// lib/models/my_collection_item.dart
class MyCollectionItem {
  int? id;
  int unitId;
  int onSprueQty;
  int assembledUnpaintedQty;
  int paintedQty;
  int desiredQty;
  String? notes;

  MyCollectionItem({
    this.id,
    required this.unitId,
    this.onSprueQty = 0,
    this.assembledUnpaintedQty = 0,
    this.paintedQty = 0,
    this.desiredQty = 0,
    this.notes,
  });

  int get totalOwnedQty => onSprueQty + assembledUnpaintedQty + paintedQty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit_id': unitId,
      'on_sprue_qty': onSprueQty,
      'assembled_unpainted_qty': assembledUnpaintedQty,
      'painted_qty': paintedQty,
      'desired_qty': desiredQty,
      'notes': notes,
    };
  }

  factory MyCollectionItem.fromMap(Map<String, dynamic> map) {
    return MyCollectionItem(
      id: map['id'],
      unitId: map['unit_id'],
      onSprueQty: map['on_sprue_qty'],
      assembledUnpaintedQty: map['assembled_unpainted_qty'],
      paintedQty: map['painted_qty'],
      desiredQty: map['desired_qty'],
      notes: map['notes'],
    );
  }

  @override
  String toString() {
    return 'MyCollectionItem{id: $id, unitId: $unitId, totalOwned: $totalOwnedQty, desired: $desiredQty}';
  }
}