// lib/models/unit.dart
class Unit {
  int? id;
  String name;
  int factionId;
  int pointsCost;
  int? movement;
  int? wounds;
  int? save;
  int? control;
  String? flavourText;
  String? imageUrl;

  Unit({
    this.id,
    required this.name,
    required this.factionId,
    required this.pointsCost,
    this.movement,
    this.wounds,
    this.save,
    this.control,
    this.flavourText,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'faction_id': factionId,
      'points_cost': pointsCost,
      'movement': movement,
      'wounds': wounds,
      'save': save,
      'control': control,
      'flavour_text': flavourText,
      'image_url': imageUrl,
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      factionId: map['faction_id'],
      pointsCost: map['points_cost'],
      movement: map['movement'],
      wounds: map['wounds'],
      save: map['save'],
      control: map['control'],
      flavourText: map['flavour_text'],
      imageUrl: map['image_url'],
    );
  }

  @override
  String toString() {
    return 'Unit{id: $id, name: $name, factionId: $factionId}';
  }
}