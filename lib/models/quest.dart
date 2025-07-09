// lib/models/quest.dart

enum QuestStatus {
  locked,      // La quête n'est pas encore débloquée
  unlocked,    // La quête est débloquée et peut être complétée
  completed,   // La quête a été complétée
}

class Quest {
  final int id; // Un identifiant unique pour la quête (ex: 1, 2, 3)
  final String name; // Nom de la quête (ex: "Affray", "Strike", "Domination")
  QuestStatus status; // État actuel de la quête

  Quest({
    required this.id,
    required this.name,
    this.status = QuestStatus.locked, // Par défaut, une quête est verrouillée
  });

  // Méthode pour copier l'objet avec des modifications
  Quest copyWith({
    int? id,
    String? name,
    QuestStatus? status,
  }) {
    return Quest(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }

  // Conversion en Map pour la sérialisation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status.name, // Stocker le nom de l'enum
    };
  }

  // Création à partir d'une Map
  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'] as int,
      name: map['name'] as String,
      status: QuestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuestStatus.locked, // Valeur par défaut si non trouvé
      ),
    );
  }
}