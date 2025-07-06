// lib/models/weapon.dart
class Weapon {
  int? id;
  String name;
  String? range;
  String? attacks;
  String? toHit;
  String? toWound;
  String? rend;
  String? damage;
  String? weaponType;

  Weapon({
    this.id,
    required this.name,
    this.range,
    this.attacks,
    this.toHit,
    this.toWound,
    this.rend,
    this.damage,
    this.weaponType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'range': range,
      'attacks': attacks,
      'to_hit': toHit,
      'to_wound': toWound,
      'rend': rend,
      'damage': damage,
      'weapon_type': weaponType,
    };
  }

  factory Weapon.fromMap(Map<String, dynamic> map) {
    return Weapon(
      id: map['id'],
      name: map['name'],
      range: map['range'],
      attacks: map['attacks'],
      toHit: map['to_hit'],
      toWound: map['to_wound'],
      rend: map['rend'],
      damage: map['damage'],
      weaponType: map['weapon_type'],
    );
  }

  @override
  String toString() {
    return 'Weapon{id: $id, name: $name}';
  }
}