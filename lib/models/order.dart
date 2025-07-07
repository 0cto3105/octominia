class Order {
  int? id; // ID de la DB SQLite, peut être null si non encore inséré
  final String uuid; // ID unique et stable pour la synchronisation JSON/DB
  String name;
  String? description;
  String? imageUrl;

  Order({
    this.id,
    required this.uuid, // uuid est maintenant requis
    required this.name,
    this.description,
    this.imageUrl,
  });

  // Convertit un objet Order en Map pour l'insertion/mise à jour dans SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id, // id peut être null pour l'insertion (auto-incrément)
      'uuid': uuid,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    };
  }

  // Crée un objet Order à partir d'une Map (provenant de SQLite)
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      uuid: map['uuid'], // Lecture du uuid depuis la Map
      name: map['name'],
      description: map['description'],
      imageUrl: map['image_url'],
    );
  }

  // Crée un objet Order à partir d'un Map JSON (provenant de vos fichiers assets)
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      uuid: json['uuid'] as String, // Assurez-vous que votre JSON contient 'uuid'
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  @override
  String toString() {
    return 'Order{id: $id, uuid: $uuid, name: $name, imageUrl: $imageUrl}';
  }
}