// lib/models/faction.dart
class Faction {
  int? id;
  String name;
  String? description;

  Faction({
    this.id,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory Faction.fromMap(Map<String, dynamic> map) {
    return Faction(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Faction{id: $id, name: $name}';
  }
}