// lib/models/ability.dart
class Ability {
  int? id;
  String name;
  String description;
  String? abilityType;
  int? castValue;
  String? range;

  Ability({
    this.id,
    required this.name,
    required this.description,
    this.abilityType,
    this.castValue,
    this.range,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ability_type': abilityType,
      'cast_value': castValue,
      'range': range,
    };
  }

  factory Ability.fromMap(Map<String, dynamic> map) {
    return Ability(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      abilityType: map['ability_type'],
      castValue: map['cast_value'],
      range: map['range'],
    );
  }

  @override
  String toString() {
    return 'Ability{id: $id, name: $name}';
  }
}