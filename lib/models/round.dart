// lib/models/round.dart

class Round {
  int roundNumber;
  int myScore; // Score primaire (0-10) pour mon joueur
  int opponentScore; // Score primaire (0-10) pour l'adversaire
  String? priorityPlayerId; // 'me' or 'opponent'

  // Mes quêtes (Suite 1)
  bool myQuest1_1Completed; // Ma quête 1 de la suite 1
  bool myQuest1_2Completed; // Ma quête 2 de la suite 1
  bool myQuest1_3Completed; // Ma quête 3 de la suite 1

  // Mes quêtes (Suite 2)
  bool myQuest2_1Completed; // Ma quête 1 de la suite 2
  bool myQuest2_2Completed; // Ma quête 2 de la suite 2
  bool myQuest2_3Completed; // Ma quête 3 de la suite 2

  // Quêtes de l'adversaire (Suite 1)
  bool opponentQuest1_1Completed; // Sa quête 1 de la suite 1
  bool opponentQuest1_2Completed; // Sa quête 2 de la suite 1
  bool opponentQuest1_3Completed; // Sa quête 3 de la suite 1

  // Quêtes de l'adversaire (Suite 2)
  bool opponentQuest2_1Completed; // Sa quête 1 de la suite 2
  bool opponentQuest2_2Completed; // Sa quête 2 de la suite 2
  bool opponentQuest2_3Completed; // Sa quête 3 de la suite 2


  Round({
    required this.roundNumber,
    required this.myScore,
    required this.opponentScore,
    this.priorityPlayerId,
    // Initialisation de toutes les quêtes à false par défaut
    this.myQuest1_1Completed = false,
    this.myQuest1_2Completed = false,
    this.myQuest1_3Completed = false,
    this.myQuest2_1Completed = false,
    this.myQuest2_2Completed = false,
    this.myQuest2_3Completed = false,
    this.opponentQuest1_1Completed = false,
    this.opponentQuest1_2Completed = false,
    this.opponentQuest1_3Completed = false,
    this.opponentQuest2_1Completed = false,
    this.opponentQuest2_2Completed = false,
    this.opponentQuest2_3Completed = false,
  });

  // Méthode pour calculer le score total d'un joueur pour ce round
  int calculatePlayerTotalScore(bool isMyPlayer) {
    int baseScore = isMyPlayer ? myScore : opponentScore;
    int questScore = 0;

    if (isMyPlayer) {
      if (myQuest1_1Completed) questScore += 5;
      if (myQuest1_2Completed) questScore += 5;
      if (myQuest1_3Completed) questScore += 5;
      if (myQuest2_1Completed) questScore += 5;
      if (myQuest2_2Completed) questScore += 5;
      if (myQuest2_3Completed) questScore += 5;
    } else {
      if (opponentQuest1_1Completed) questScore += 5;
      if (opponentQuest1_2Completed) questScore += 5;
      if (opponentQuest1_3Completed) questScore += 5;
      if (opponentQuest2_1Completed) questScore += 5;
      if (opponentQuest2_2Completed) questScore += 5;
      if (opponentQuest2_3Completed) questScore += 5;
    }
    return baseScore + questScore;
  }

  // Ajout de la méthode copyWith ici
  Round copyWith({
    int? roundNumber,
    int? myScore,
    int? opponentScore,
    String? priorityPlayerId,
    bool? myQuest1_1Completed,
    bool? myQuest1_2Completed,
    bool? myQuest1_3Completed,
    bool? myQuest2_1Completed,
    bool? myQuest2_2Completed,
    bool? myQuest2_3Completed,
    bool? opponentQuest1_1Completed,
    bool? opponentQuest1_2Completed,
    bool? opponentQuest1_3Completed,
    bool? opponentQuest2_1Completed,
    bool? opponentQuest2_2Completed,
    bool? opponentQuest2_3Completed,
  }) {
    return Round(
      roundNumber: roundNumber ?? this.roundNumber,
      myScore: myScore ?? this.myScore,
      opponentScore: opponentScore ?? this.opponentScore,
      priorityPlayerId: priorityPlayerId ?? this.priorityPlayerId,
      myQuest1_1Completed: myQuest1_1Completed ?? this.myQuest1_1Completed,
      myQuest1_2Completed: myQuest1_2Completed ?? this.myQuest1_2Completed,
      myQuest1_3Completed: myQuest1_3Completed ?? this.myQuest1_3Completed,
      myQuest2_1Completed: myQuest2_1Completed ?? this.myQuest2_1Completed,
      myQuest2_2Completed: myQuest2_2Completed ?? this.myQuest2_2Completed,
      myQuest2_3Completed: myQuest2_3Completed ?? this.myQuest2_3Completed,
      opponentQuest1_1Completed: opponentQuest1_1Completed ?? this.opponentQuest1_1Completed,
      opponentQuest1_2Completed: opponentQuest1_2Completed ?? this.opponentQuest1_2Completed,
      opponentQuest1_3Completed: opponentQuest1_3Completed ?? this.opponentQuest1_3Completed,
      opponentQuest2_1Completed: opponentQuest2_1Completed ?? this.opponentQuest2_1Completed,
      opponentQuest2_2Completed: opponentQuest2_2Completed ?? this.opponentQuest2_2Completed,
      opponentQuest2_3Completed: opponentQuest2_3Completed ?? this.opponentQuest2_3Completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roundNumber': roundNumber,
      'myScore': myScore,
      'opponentScore': opponentScore,
      'priorityPlayerId': priorityPlayerId,
      'myQuest1_1Completed': myQuest1_1Completed,
      'myQuest1_2Completed': myQuest1_2Completed,
      'myQuest1_3Completed': myQuest1_3Completed,
      'myQuest2_1Completed': myQuest2_1Completed,
      'myQuest2_2Completed': myQuest2_2Completed,
      'myQuest2_3Completed': myQuest2_3Completed,
      'opponentQuest1_1Completed': opponentQuest1_1Completed,
      'opponentQuest1_2Completed': opponentQuest1_2Completed,
      'opponentQuest1_3Completed': opponentQuest1_3Completed,
      'opponentQuest2_1Completed': opponentQuest2_1Completed,
      'opponentQuest2_2Completed': opponentQuest2_2Completed,
      'opponentQuest2_3Completed': opponentQuest2_3Completed,
    };
  }

  factory Round.fromMap(Map<String, dynamic> map) {
    return Round(
      roundNumber: map['roundNumber'] as int,
      myScore: map['myScore'] as int? ?? 0,
      opponentScore: map['opponentScore'] as int? ?? 0,
      priorityPlayerId: map['priorityPlayerId'] as String?,
      // Lecture des valeurs avec des valeurs par défaut robustes
      myQuest1_1Completed: map['myQuest1_1Completed'] as bool? ?? false,
      myQuest1_2Completed: map['myQuest1_2Completed'] as bool? ?? false,
      myQuest1_3Completed: map['myQuest1_3Completed'] as bool? ?? false,
      myQuest2_1Completed: map['myQuest2_1Completed'] as bool? ?? false,
      myQuest2_2Completed: map['myQuest2_2Completed'] as bool? ?? false,
      myQuest2_3Completed: map['myQuest2_3Completed'] as bool? ?? false,
      opponentQuest1_1Completed: map['opponentQuest1_1Completed'] as bool? ?? false,
      opponentQuest1_2Completed: map['opponentQuest1_2Completed'] as bool? ?? false,
      opponentQuest1_3Completed: map['opponentQuest1_3Completed'] as bool? ?? false,
      opponentQuest2_1Completed: map['opponentQuest2_1Completed'] as bool? ?? false,
      opponentQuest2_2Completed: map['opponentQuest2_2Completed'] as bool? ?? false,
      opponentQuest2_3Completed: map['opponentQuest2_3Completed'] as bool? ?? false,
    );
  }
}