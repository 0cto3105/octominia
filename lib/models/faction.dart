class Faction {
  int? id; // ID de la DB SQLite, peut être null si non encore inséré
  final String uuid; // ID unique et stable pour la synchronisation JSON/DB
  String name;
  
  // NOUVEAU : UUID de l'ordre parent, lu depuis le JSON.
  final String orderUuid; 
  
  int orderId; // ID SQLite de l'ordre parent, sera peuplé durant la synchronisation
  String? description;
  String? imageUrl;

  Faction({
    this.id,
    required this.uuid, // uuid est requis
    required this.name,
    required this.orderUuid, // orderUuid est maintenant requis (pour le JSON)
    required this.orderId,   // orderId est toujours requis (pour la DB)
    this.description,
    this.imageUrl,
  });

  // Convertit un objet Faction en Map pour l'insertion/mise à jour dans SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'order_id': orderId, // Stocké comme INTEGER ID dans SQLite
      'description': description,
      'image_url': imageUrl,
    };
  }

  // Crée un objet Faction à partir d'une Map (provenant de SQLite)
  factory Faction.fromMap(Map<String, dynamic> map) {
    return Faction(
      id: map['id'],
      uuid: map['uuid'],
      name: map['name'],
      // Quand on lit de la DB, on a seulement order_id. orderUuid n'est pas stocké directement.
      // On fournit un placeholder ici. Il sera cherché si nécessaire plus tard.
      orderUuid: '', // Placeholder, car non stocké dans la DB sous ce nom
      orderId: map['order_id'],
      description: map['description'],
      imageUrl: map['image_url'],
    );
  }

  // Crée un objet Faction à partir d'un Map JSON (provenant de vos fichiers assets)
  factory Faction.fromJson(Map<String, dynamic> json) {
    return Faction(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      orderUuid: json['order_uuid'] as String, // LECTURE DIRECTE DU JSON
      orderId: 0, // Placeholder, sera défini par DatabaseHelper durant la synchronisation
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  @override
  String toString() {
    return 'Faction{id: $id, uuid: $uuid, name: $name, orderUuid: $orderUuid, orderId: $orderId, imageUrl: $imageUrl}';
  }
}