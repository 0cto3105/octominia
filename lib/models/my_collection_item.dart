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

  // Convertit l'objet MyCollectionItem en Map pour la base de données (utilise snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit_id': unitId, // Correction: Utilise snake_case
      'on_sprue_qty': onSprueQty, // Correction: Utilise snake_case
      'assembled_unpainted_qty': assembledUnpaintedQty, // Correction: Utilise snake_case
      'painted_qty': paintedQty, // Correction: Utilise snake_case
      'desired_qty': desiredQty, // Correction: Utilise snake_case
      'notes': notes,
    };
  }

  // Crée un objet MyCollectionItem à partir d'un Map (lit snake_case)
  factory MyCollectionItem.fromMap(Map<String, dynamic> map) {
    return MyCollectionItem(
      id: map['id'],
      unitId: map['unit_id'] as int, // Correction: Lit snake_case
      onSprueQty: map['on_sprue_qty'] as int? ?? 0, // Correction: Lit snake_case
      assembledUnpaintedQty: map['assembled_unpainted_qty'] as int? ?? 0, // Correction: Lit snake_case
      paintedQty: map['painted_qty'] as int? ?? 0, // Correction: Lit snake_case
      desiredQty: map['desired_qty'] as int? ?? 0, // Correction: Lit snake_case
      notes: map['notes'] as String?,
    );
  }

  // Getters pour les quantités totales
  int get totalOwnedQty => onSprueQty + assembledUnpaintedQty + paintedQty;
  int get totalMissingQty => (desiredQty - totalOwnedQty).clamp(0, desiredQty);
  int get totalExcessQty => (totalOwnedQty - desiredQty).clamp(0, totalOwnedQty);

  // Pour la comparaison dans didUpdateWidget
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyCollectionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          unitId == other.unitId &&
          onSprueQty == other.onSprueQty &&
          assembledUnpaintedQty == other.assembledUnpaintedQty &&
          paintedQty == other.paintedQty &&
          desiredQty == other.desiredQty &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      unitId.hashCode ^
      onSprueQty.hashCode ^
      assembledUnpaintedQty.hashCode ^
      paintedQty.hashCode ^
      desiredQty.hashCode ^
      notes.hashCode;
}