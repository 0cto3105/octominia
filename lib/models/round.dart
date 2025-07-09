// lib/models/round.dart

class Round {
  int roundNumber;
  int myScore; // Score primaire (0-10) pour mon joueur
  int opponentScore; // Score primaire (0-10) pour l'adversaire
  String? priorityPlayerId; // 'me' or 'opponent'
  String? initiativePlayerId; // 'me' ou 'opponent' pour le jet d'initiative

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
  bool opponentQuest2_1Completed;
  bool opponentQuest2_2Completed;
  bool opponentQuest2_3Completed;

  // NOUVEAU : États liés au double tour et à l'underdog, persistés par round
  String? underdogPlayerIdAtEndOfRound; // 'me' ou 'opponent' si un underdog a été désigné à la fin de CE round
  bool myPlayerHadDoubleFreeTurn; // True si mon joueur a eu le DGT ce round
  bool opponentPlayerHadDoubleFreeTurn; // True si l'adversaire a eu le DGT ce round
  bool myPlayerDidNonFreeDoubleTurn; // True si mon joueur a fait un double tour non gratuit ce round
  bool opponentPlayerDidNonFreeDoubleTurn; // True si l'adversaire a fait un double tour non gratuit ce round

  Round({
    required this.roundNumber,
    required this.myScore,
    required this.opponentScore,
    this.priorityPlayerId,
    this.initiativePlayerId,
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
    // NOUVEAU : Initialisation des nouvelles propriétés
    this.underdogPlayerIdAtEndOfRound,
    this.myPlayerHadDoubleFreeTurn = false,
    this.opponentPlayerHadDoubleFreeTurn = false,
    this.myPlayerDidNonFreeDoubleTurn = false,
    this.opponentPlayerDidNonFreeDoubleTurn = false,
  });

  Round copyWith({
    int? roundNumber,
    int? myScore,
    int? opponentScore,
    String? priorityPlayerId,
    String? initiativePlayerId,
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
    String? underdogPlayerIdAtEndOfRound,
    bool? myPlayerHadDoubleFreeTurn,
    bool? opponentPlayerHadDoubleFreeTurn,
    bool? myPlayerDidNonFreeDoubleTurn,
    bool? opponentPlayerDidNonFreeDoubleTurn,
  }) {
    return Round(
      roundNumber: roundNumber ?? this.roundNumber,
      myScore: myScore ?? this.myScore,
      opponentScore: opponentScore ?? this.opponentScore,
      priorityPlayerId: priorityPlayerId ?? this.priorityPlayerId,
      initiativePlayerId: initiativePlayerId ?? this.initiativePlayerId,
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
      // NOUVEAU : Copie des nouvelles propriétés
      underdogPlayerIdAtEndOfRound: underdogPlayerIdAtEndOfRound ?? this.underdogPlayerIdAtEndOfRound,
      myPlayerHadDoubleFreeTurn: myPlayerHadDoubleFreeTurn ?? this.myPlayerHadDoubleFreeTurn,
      opponentPlayerHadDoubleFreeTurn: opponentPlayerHadDoubleFreeTurn ?? this.opponentPlayerHadDoubleFreeTurn,
      myPlayerDidNonFreeDoubleTurn: myPlayerDidNonFreeDoubleTurn ?? this.myPlayerDidNonFreeDoubleTurn,
      opponentPlayerDidNonFreeDoubleTurn: opponentPlayerDidNonFreeDoubleTurn ?? this.opponentPlayerDidNonFreeDoubleTurn,
    );
  }

  // Calculate total score for a player (primary + secondary)
  int calculatePlayerTotalScore(bool isMyPlayer) {
    int total = isMyPlayer ? myScore : opponentScore;

    if (isMyPlayer) {
      if (myQuest1_1Completed) total += 5; // Corrigé à 5 points
      if (myQuest1_2Completed) total += 5; // Corrigé à 5 points
      if (myQuest1_3Completed) total += 5; // Corrigé à 5 points
      if (myQuest2_1Completed) total += 5; // Corrigé à 5 points
      if (myQuest2_2Completed) total += 5; // Corrigé à 5 points
      if (myQuest2_3Completed) total += 5; // Corrigé à 5 points
    } else {
      if (opponentQuest1_1Completed) total += 5; // Corrigé à 5 points
      if (opponentQuest1_2Completed) total += 5; // Corrigé à 5 points
      if (opponentQuest1_3Completed) total += 5; // Corrigé à 5 points
      if (opponentQuest2_1Completed) total += 5; // Corrigé à 5 points
      if (opponentQuest2_2Completed) total += 5; // Corrigé à 5 points
      if (opponentQuest2_3Completed) total += 5; // Corrigé à 5 points
    }
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'roundNumber': roundNumber,
      'myScore': myScore,
      'opponentScore': opponentScore,
      'priorityPlayerId': priorityPlayerId,
      'initiativePlayerId': initiativePlayerId,
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
      // NOUVEAU : Sérialisation des nouvelles propriétés
      'underdogPlayerIdAtEndOfRound': underdogPlayerIdAtEndOfRound,
      'myPlayerHadDoubleFreeTurn': myPlayerHadDoubleFreeTurn,
      'opponentPlayerHadDoubleFreeTurn': opponentPlayerHadDoubleFreeTurn,
      'myPlayerDidNonFreeDoubleTurn': myPlayerDidNonFreeDoubleTurn,
      'opponentPlayerDidNonFreeDoubleTurn': opponentPlayerDidNonFreeDoubleTurn,
    };
  }

  factory Round.fromMap(Map<String, dynamic> map) {
    return Round(
      roundNumber: map['roundNumber'] as int,
      myScore: map['myScore'] as int? ?? 0,
      opponentScore: map['opponentScore'] as int? ?? 0,
      priorityPlayerId: map['priorityPlayerId'] as String?,
      initiativePlayerId: map['initiativePlayerId'] as String?,
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
      opponentQuest2_2Completed: map['opponent2_2Completed'] as bool? ?? false, // Corrigé
      opponentQuest2_3Completed: map['opponentQuest2_3Completed'] as bool? ?? false, // Corrigé
      // NOUVEAU : Désérialisation des nouvelles propriétés
      underdogPlayerIdAtEndOfRound: map['underdogPlayerIdAtEndOfRound'] as String?,
      myPlayerHadDoubleFreeTurn: map['myPlayerHadDoubleFreeTurn'] as bool? ?? false,
      opponentPlayerHadDoubleFreeTurn: map['opponentPlayerHadDoubleFreeTurn'] as bool? ?? false,
      myPlayerDidNonFreeDoubleTurn: map['myPlayerDidNonFreeDoubleTurn'] as bool? ?? false,
      opponentPlayerDidNonFreeDoubleTurn: map['opponentDidNonFreeDoubleTurn'] as bool? ?? false, // Il semble qu'il y ait eu une faute de frappe ici dans le fichier fourni par l'utilisateur
    );
  }
}