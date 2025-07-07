class Unit {
  int? id; // SQLite DB ID, can be null if not yet inserted
  final String uuid; // Unique and stable ID for JSON/DB synchronization
  String name;
  final String factionUuid; // UUID of the parent Faction, read from JSON
  int factionId; // SQLite ID of the parent Faction, populated during sync
  int pointsCost;
  String? movement; // MODIFIÉ : était int?, est maintenant String?
  int? wounds;
  int? save;
  int? control;
  String? flavourText; // NOM DU PARAMÈTRE : flavourText (camelCase)
  String? imageUrl;

  Unit({
    this.id,
    required this.uuid,
    required this.name,
    required this.factionUuid,
    required this.factionId,
    required this.pointsCost,
    this.movement,
    this.wounds,
    this.save,
    this.control,
    this.flavourText, // C'est ici que le paramètre est défini comme 'flavourText'
    this.imageUrl,
  });

  // Converts a Unit object to a Map for insertion/update in SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'faction_id': factionId,
      'points_cost': pointsCost,
      'movement': movement,
      'wounds': wounds,
      'save': save,
      'control': control,
      'flavour_text': flavourText, // La clé de la map est 'flavour_text'
      'image_url': imageUrl,
    };
  }

  // Creates a Unit object from a Map (coming from SQLite)
  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      uuid: map['uuid'],
      name: map['name'],
      factionUuid: '',
      factionId: map['faction_id'],
      pointsCost: map['points_cost'],
      movement: map['movement'] as String?,
      wounds: map['wounds'],
      save: map['save'],
      control: map['control'],
      flavourText: map['flavour_text'] as String?, // 'flavourText' est le paramètre du constructeur, 'flavour_text' est la clé de la map
      imageUrl: map['image_url'] as String?,
    );
  }

  // Creates a Unit object from a JSON Map (coming from your assets files)
  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      factionUuid: json['faction_uuid'] as String,
      factionId: 0,
      pointsCost: json['points_cost'] as int,
      movement: json['movement'] as String?,
      wounds: json['wounds'] as int?,
      save: json['save'] as int?,
      control: json['control'] as int?,
      flavourText: json['flavour_text'] as String?, // 'flavourText' est le paramètre du constructeur, 'flavour_text' est la clé JSON
      imageUrl: json['image_url'] as String?,
    );
  }

  @override
  String toString() {
    return 'Unit{id: $id, uuid: $uuid, name: $name, factionUuid: $factionUuid, factionId: $factionId}';
  }
}