// lib/models/round.dart

import 'package:octominia/models/quest.dart'; // Importer la nouvelle classe Quest

class Round {
  int roundNumber;
  int myScore; // Score primaire (0-10) pour mon joueur
  int opponentScore; // Score primaire (0-10) pour l'adversaire
  String? priorityPlayerId; // 'me' or 'opponent'
  String? initiativePlayerId; // 'me' ou 'opponent' pour le jet d'initiative

  // Remplacer les booléens individuels par des listes de Quest
  List<Quest> myQuestsSuite1;
  List<Quest> myQuestsSuite2;
  List<Quest> opponentQuestsSuite1;
  List<Quest> opponentQuestsSuite2;

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
    // Initialisation des listes de quêtes
    List<Quest>? myQuestsSuite1,
    List<Quest>? myQuestsSuite2,
    List<Quest>? opponentQuestsSuite1,
    List<Quest>? opponentQuestsSuite2,
    // NOUVEAU : Initialisation des nouvelles propriétés
    this.underdogPlayerIdAtEndOfRound,
    this.myPlayerHadDoubleFreeTurn = false,
    this.opponentPlayerHadDoubleFreeTurn = false,
    this.myPlayerDidNonFreeDoubleTurn = false,
    this.opponentPlayerDidNonFreeDoubleTurn = false,
  }) : myQuestsSuite1 = myQuestsSuite1 ?? _createInitialQuests(isMyPlayer: true, suiteNumber: 1),
        myQuestsSuite2 = myQuestsSuite2 ?? _createInitialQuests(isMyPlayer: true, suiteNumber: 2),
        opponentQuestsSuite1 = opponentQuestsSuite1 ?? _createInitialQuests(isMyPlayer: false, suiteNumber: 1),
        opponentQuestsSuite2 = opponentQuestsSuite2 ?? _createInitialQuests(isMyPlayer: false, suiteNumber: 2);

  // Helper pour créer les quêtes initiales avec la première débloquée
  static List<Quest> _createInitialQuests({required bool isMyPlayer, required int suiteNumber}) {
    final List<String> questNames = ["Affray", "Strike", "Domination"];
    return List.generate(3, (index) {
      return Quest(
        id: (isMyPlayer ? 0 : 6) + (suiteNumber == 1 ? 0 : 3) + index + 1, // IDs uniques pour chaque quête
        name: questNames[index],
        status: index == 0 ? QuestStatus.unlocked : QuestStatus.locked, // La première quête de chaque suite est débloquée
      );
    });
  }

  Round copyWith({
    int? roundNumber,
    int? myScore,
    int? opponentScore,
    String? priorityPlayerId,
    String? initiativePlayerId,
    List<Quest>? myQuestsSuite1,
    List<Quest>? myQuestsSuite2,
    List<Quest>? opponentQuestsSuite1,
    List<Quest>? opponentQuestsSuite2,
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
      myQuestsSuite1: myQuestsSuite1 ?? this.myQuestsSuite1.map((q) => q.copyWith()).toList(),
      myQuestsSuite2: myQuestsSuite2 ?? this.myQuestsSuite2.map((q) => q.copyWith()).toList(),
      opponentQuestsSuite1: opponentQuestsSuite1 ?? this.opponentQuestsSuite1.map((q) => q.copyWith()).toList(),
      opponentQuestsSuite2: opponentQuestsSuite2 ?? this.opponentQuestsSuite2.map((q) => q.copyWith()).toList(),
      // Copie des nouvelles propriétés
      underdogPlayerIdAtEndOfRound: underdogPlayerIdAtEndOfRound ?? this.underdogPlayerIdAtEndOfRound,
      myPlayerHadDoubleFreeTurn: myPlayerHadDoubleFreeTurn ?? this.myPlayerHadDoubleFreeTurn,
      opponentPlayerHadDoubleFreeTurn: opponentPlayerHadDoubleFreeTurn ?? this.opponentPlayerHadDoubleFreeTurn,
      myPlayerDidNonFreeDoubleTurn: myPlayerDidNonFreeDoubleTurn ?? this.myPlayerDidNonFreeDoubleTurn,
      opponentPlayerDidNonFreeDoubleTurn: opponentPlayerDidNonFreeDoubleTurn ?? this.opponentPlayerDidNonFreeDoubleTurn,
    );
  }

  // Méthode pour compléter une quête et débloquer la suivante
  bool completeQuest(bool isMyPlayer, int suiteIndex, int questIndex) {
    List<Quest> targetSuite;
    if (isMyPlayer) {
      targetSuite = (suiteIndex == 1) ? myQuestsSuite1 : myQuestsSuite2;
    } else {
      targetSuite = (suiteIndex == 1) ? opponentQuestsSuite1 : opponentQuestsSuite2;
    }

    if (questIndex >= 0 && questIndex < targetSuite.length) {
      final quest = targetSuite[questIndex];
      if (quest.status == QuestStatus.unlocked) {
        quest.status = QuestStatus.completed;
        // Débloquer la quête suivante si elle existe et n'est pas déjà débloquée/complétée
        if (questIndex + 1 < targetSuite.length) {
          final nextQuest = targetSuite[questIndex + 1];
          if (nextQuest.status == QuestStatus.locked) {
            nextQuest.status = QuestStatus.unlocked;
          }
        }
        return true; // Quête complétée avec succès
      } else {
        // La quête n'est pas débloquée ou déjà complétée
        return false;
      }
    }
    return false; // Index de quête invalide
  }

  // Méthode pour décompléter une quête
  bool uncompleteQuest(bool isMyPlayer, int suiteIndex, int questIndex) {
    List<Quest> targetSuite;
    if (isMyPlayer) {
      targetSuite = (suiteIndex == 1) ? myQuestsSuite1 : myQuestsSuite2;
    } else {
      targetSuite = (suiteIndex == 1) ? opponentQuestsSuite1 : opponentQuestsSuite2;
    }

    if (questIndex >= 0 && questIndex < targetSuite.length) {
      final quest = targetSuite[questIndex];
      if (quest.status == QuestStatus.completed) {
        // Vérifier si la quête suivante est complétée, si oui, on ne peut pas décocher
        if (questIndex + 1 < targetSuite.length) {
          final nextQuest = targetSuite[questIndex + 1];
          if (nextQuest.status == QuestStatus.completed) {
            return false; // Cannot uncomplete if next quest is completed
          }
          // Si la quête suivante était débloquée mais pas complétée, la re-verrouiller
          if (nextQuest.status == QuestStatus.unlocked) {
            nextQuest.status = QuestStatus.locked;
          }
        }
        quest.status = QuestStatus.unlocked; // Revenir à l'état débloqué
        return true; // Quête décomplétée avec succès
      }
    }
    return false; // Index de quête invalide ou quête non complétée
  }

  // Calculate total score for a player (primary + secondary)
  int calculatePlayerTotalScore(bool isMyPlayer) {
    int total = isMyPlayer ? myScore : opponentScore;

    List<List<Quest>> allPlayerQuests = isMyPlayer
        ? [myQuestsSuite1, myQuestsSuite2]
        : [opponentQuestsSuite1, opponentQuestsSuite2];

    for (var suite in allPlayerQuests) {
      for (var quest in suite) {
        if (quest.status == QuestStatus.completed) {
          total += 5; // Chaque quête complétée rapporte 5 points
        }
      }
    }
    return total;
  }

  // Méthode pour déterminer l'underdog à la fin du round
  String? determineUnderdogAtEndOfRound() {
    int myTotalScore = calculatePlayerTotalScore(true);
    int opponentTotalScore = calculatePlayerTotalScore(false);

    if (myTotalScore < opponentTotalScore) {
      return 'me';
    } else if (opponentTotalScore < myTotalScore) {
      return 'opponent';
    }
    return null; // Pas d'underdog si les scores sont égaux
  }

  Map<String, dynamic> toJson() { // Renamed from toMap() to toJson()
    return {
      'roundNumber': roundNumber,
      'myScore': myScore,
      'opponentScore': opponentScore,
      'priorityPlayerId': priorityPlayerId,
      'initiativePlayerId': initiativePlayerId,
      'myQuestsSuite1': myQuestsSuite1.map((q) => q.toMap()).toList(), // Assuming Quest has toMap()
      'myQuestsSuite2': myQuestsSuite2.map((q) => q.toMap()).toList(), // Assuming Quest has toMap()
      'opponentQuestsSuite1': opponentQuestsSuite1.map((q) => q.toMap()).toList(), // Assuming Quest has toMap()
      'opponentQuestsSuite2': opponentQuestsSuite2.map((q) => q.toMap()).toList(), // Assuming Quest has toMap()
      // Sérialisation des nouvelles propriétés
      'underdogPlayerIdAtEndOfRound': underdogPlayerIdAtEndOfRound,
      'myPlayerHadDoubleFreeTurn': myPlayerHadDoubleFreeTurn,
      'opponentPlayerHadDoubleFreeTurn': opponentPlayerHadDoubleFreeTurn,
      'myPlayerDidNonFreeDoubleTurn': myPlayerDidNonFreeDoubleTurn,
      'opponentPlayerDidNonFreeDoubleTurn': opponentPlayerDidNonFreeDoubleTurn,
    };
  }

  factory Round.fromJson(Map<String, dynamic> map) {
    return Round(
      roundNumber: map['roundNumber'] as int,
      myScore: map['myScore'] as int? ?? 0,
      opponentScore: map['opponentScore'] as int? ?? 0,
      priorityPlayerId: map['priorityPlayerId'] as String?,
      initiativePlayerId: map['initiativePlayerId'] as String?,
      myQuestsSuite1: (map['myQuestsSuite1'] as List<dynamic>?)
              ?.map((e) => Quest.fromMap(e as Map<String, dynamic>)) // Assuming Quest has fromMap()
              .toList() ??
          _createInitialQuests(isMyPlayer: true, suiteNumber: 1),
      myQuestsSuite2: (map['myQuestsSuite2'] as List<dynamic>?)
              ?.map((e) => Quest.fromMap(e as Map<String, dynamic>)) // Assuming Quest has fromMap()
              .toList() ??
          _createInitialQuests(isMyPlayer: true, suiteNumber: 2),
      opponentQuestsSuite1: (map['opponentQuestsSuite1'] as List<dynamic>?)
              ?.map((e) => Quest.fromMap(e as Map<String, dynamic>)) // Assuming Quest has fromMap()
              .toList() ??
          _createInitialQuests(isMyPlayer: false, suiteNumber: 1),
      opponentQuestsSuite2: (map['opponentQuestsSuite2'] as List<dynamic>?)
              ?.map((e) => Quest.fromMap(e as Map<String, dynamic>)) // Assuming Quest has fromMap()
              .toList() ??
          _createInitialQuests(isMyPlayer: false, suiteNumber: 2),
      // Désérialisation des nouvelles propriétés
      underdogPlayerIdAtEndOfRound: map['underdogPlayerIdAtEndOfRound'] as String?,
      myPlayerHadDoubleFreeTurn: map['myPlayerHadDoubleFreeTurn'] as bool? ?? false,
      opponentPlayerHadDoubleFreeTurn: map['opponentPlayerHadDoubleFreeTurn'] as bool? ?? false,
      myPlayerDidNonFreeDoubleTurn: map['myPlayerDidNonFreeDoubleTurn'] as bool? ?? false,
      opponentPlayerDidNonFreeDoubleTurn: map['opponentPlayerDidNonFreeDoubleTurn'] as bool? ?? false,
    );
  }
}