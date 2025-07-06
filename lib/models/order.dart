// lib/models/order.dart
class Order {
  int? id;
  String name;
  String? description;
  String? imageUrl; // Nouvelle propriété

  Order({
    this.id,
    required this.name,
    this.description,
    this.imageUrl, // Incluez-le dans le constructeur
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl, // Ajout pour la conversion vers Map
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['image_url'], // Lecture depuis Map
    );
  }

  @override
  String toString() {
    return 'Order{id: $id, name: $name, imageUrl: $imageUrl}';
  }
}