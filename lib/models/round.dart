// lib/models/round.dart
import 'package:octominia/models/quest.dart';

class Round {
  int roundNumber;
  int myScore;
  int opponentScore;
  String? priorityPlayerId;
  String? initiativePlayerId;

  List<Quest> myQuestsSuite1;
  List<Quest> myQuestsSuite2;
  List<Quest> opponentQuestsSuite1;
  List<Quest> opponentQuestsSuite2;

  String? underdogPlayerIdAtEndOfRound;
  bool myPlayerHadDoubleFreeTurn;
  bool opponentPlayerHadDoubleFreeTurn;
  bool myPlayerDidNonFreeDoubleTurn;
  bool opponentPlayerDidNonFreeDoubleTurn;

  // NOUVEAU: Drapeaux pour suivre si une quête a été complétée dans CHAQUE suite durant CE round.
  bool myQuestSuite1CompletedThisRound;
  bool myQuestSuite2CompletedThisRound;
  bool opponentQuestSuite1CompletedThisRound;
  bool opponentQuestSuite2CompletedThisRound;

  Round({
    required this.roundNumber,
    required this.myScore,
    required this.opponentScore,
    this.priorityPlayerId,
    this.initiativePlayerId,
    required this.myQuestsSuite1,
    required this.myQuestsSuite2,
    required this.opponentQuestsSuite1,
    required this.opponentQuestsSuite2,
    this.underdogPlayerIdAtEndOfRound,
    this.myPlayerHadDoubleFreeTurn = false,
    this.opponentPlayerHadDoubleFreeTurn = false,
    this.myPlayerDidNonFreeDoubleTurn = false,
    this.opponentPlayerDidNonFreeDoubleTurn = false,
    this.myQuestSuite1CompletedThisRound = false,
    this.myQuestSuite2CompletedThisRound = false,
    this.opponentQuestSuite1CompletedThisRound = false,
    this.opponentQuestSuite2CompletedThisRound = false,
  });

  // MODIFIÉ : Constructeur de fabrique pour la désérialisation JSON
  factory Round.fromJson(Map<String, dynamic> map) {
    return Round(
      roundNumber: map['roundNumber'] as int,
      myScore: map['myScore'] as int,
      opponentScore: map['opponentScore'] as int,
      priorityPlayerId: map['priorityPlayerId'] as String?,
      initiativePlayerId: map['initiativePlayerId'] as String?,
      myQuestsSuite1: (map['myQuestsSuite1'] as List<dynamic>)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
      myQuestsSuite2: (map['myQuestsSuite2'] as List<dynamic>)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
      opponentQuestsSuite1: (map['opponentQuestsSuite1'] as List<dynamic>)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
      opponentQuestsSuite2: (map['opponentQuestsSuite2'] as List<dynamic>)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
      underdogPlayerIdAtEndOfRound: map['underdogPlayerIdAtEndOfRound'] as String?,
      myPlayerHadDoubleFreeTurn: map['myPlayerHadDoubleFreeTurn'] as bool? ?? false,
      opponentPlayerHadDoubleFreeTurn: map['opponentPlayerHadDoubleFreeTurn'] as bool? ?? false,
      myPlayerDidNonFreeDoubleTurn: map['myPlayerDidNonFreeDoubleTurn'] as bool? ?? false,
      opponentPlayerDidNonFreeDoubleTurn: map['opponentPlayerDidNonFreeDoubleTurn'] as bool? ?? false,
      myQuestSuite1CompletedThisRound: map['myQuestSuite1CompletedThisRound'] as bool? ?? false,
      myQuestSuite2CompletedThisRound: map['myQuestSuite2CompletedThisRound'] as bool? ?? false,
      opponentQuestSuite1CompletedThisRound: map['opponentQuestSuite1CompletedThisRound'] as bool? ?? false,
      opponentQuestSuite2CompletedThisRound: map['opponentQuestSuite2CompletedThisRound'] as bool? ?? false,
    );
  }

  // Helper pour créer les quêtes initiales avec la première débloquée (utilisé pour Round 1)
  static List<Quest> createInitialQuests({required bool isMyPlayer, required int suiteNumber}) {
    final List<String> questNames = ["Affray", "Strike", "Domination"];
    return List.generate(3, (index) {
      return Quest(
        id: (isMyPlayer ? 0 : 6) + (suiteNumber == 1 ? 0 : 3) + index + 1,
        name: questNames[index],
        status: index == 0 ? QuestStatus.unlocked : QuestStatus.locked,
      );
    });
  }

  // NOUVEAU: Méthode pour initialiser les quêtes d'un nouveau round en fonction du round précédent
  static List<Quest> initializeQuestsFromPreviousRound(List<Quest> previousRoundQuests) {
    List<Quest> newRoundQuests = previousRoundQuests.map((q) => q.copyWith()).toList();

    for (int i = 0; i < newRoundQuests.length; i++) {
      if (newRoundQuests[i].status == QuestStatus.completed) {
        if (i + 1 < newRoundQuests.length && newRoundQuests[i + 1].status == QuestStatus.locked) {
          newRoundQuests[i + 1].status = QuestStatus.unlocked;
        }
      } else if (newRoundQuests[i].status == QuestStatus.locked && i > 0 && newRoundQuests[i - 1].status == QuestStatus.completed) {
        newRoundQuests[i].status = QuestStatus.unlocked;
      }
    }
    return newRoundQuests;
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
    bool? myQuestSuite1CompletedThisRound,
    bool? myQuestSuite2CompletedThisRound,
    bool? opponentQuestSuite1CompletedThisRound,
    bool? opponentQuestSuite2CompletedThisRound,
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
      underdogPlayerIdAtEndOfRound: underdogPlayerIdAtEndOfRound ?? this.underdogPlayerIdAtEndOfRound,
      myPlayerHadDoubleFreeTurn: myPlayerHadDoubleFreeTurn ?? this.myPlayerHadDoubleFreeTurn,
      opponentPlayerHadDoubleFreeTurn: opponentPlayerHadDoubleFreeTurn ?? this.opponentPlayerHadDoubleFreeTurn,
      myPlayerDidNonFreeDoubleTurn: myPlayerDidNonFreeDoubleTurn ?? this.myPlayerDidNonFreeDoubleTurn,
      opponentPlayerDidNonFreeDoubleTurn: opponentPlayerDidNonFreeDoubleTurn ?? this.opponentPlayerDidNonFreeDoubleTurn,
      myQuestSuite1CompletedThisRound: myQuestSuite1CompletedThisRound ?? this.myQuestSuite1CompletedThisRound,
      myQuestSuite2CompletedThisRound: myQuestSuite2CompletedThisRound ?? this.myQuestSuite2CompletedThisRound,
      opponentQuestSuite1CompletedThisRound: opponentQuestSuite1CompletedThisRound ?? this.opponentQuestSuite1CompletedThisRound,
      opponentQuestSuite2CompletedThisRound: opponentQuestSuite2CompletedThisRound ?? this.opponentQuestSuite2CompletedThisRound,
    );
  }

  // MODIFIÉ : Méthode pour compléter une quête et débloquer la suivante, en respectant la nouvelle règle
  bool completeQuest(bool isMyPlayer, int suiteIndex, int questIndex) {
    List<Quest> targetSuite;
    bool currentQuestCompletedThisRoundFlag;

    if (isMyPlayer) {
      targetSuite = (suiteIndex == 1) ? myQuestsSuite1 : myQuestsSuite2;
      currentQuestCompletedThisRoundFlag = (suiteIndex == 1) ? myQuestSuite1CompletedThisRound : myQuestSuite2CompletedThisRound;
    } else {
      targetSuite = (suiteIndex == 1) ? opponentQuestsSuite1 : opponentQuestsSuite2;
      currentQuestCompletedThisRoundFlag = (suiteIndex == 1) ? opponentQuestSuite1CompletedThisRound : opponentQuestSuite2CompletedThisRound;
    }

    if (questIndex >= 0 && questIndex < targetSuite.length) {
      final quest = targetSuite[questIndex];

      // Règle: Ne peut valider qu'une quête par liste par round
      if (currentQuestCompletedThisRoundFlag) {
        print("DEBUG: Une quête a déjà été complétée dans cette suite ce round.");
        return false;
      }

      // Règle: Ne peut valider une quête que si la quête précédente dans la liste est validée (sauf pour la première)
      if (questIndex > 0 && targetSuite[questIndex - 1].status != QuestStatus.completed) {
        print("DEBUG: La quête précédente n'est pas complétée.");
        return false;
      }

      if (quest.status == QuestStatus.unlocked) {
        quest.status = QuestStatus.completed;

        if (isMyPlayer) {
          if (suiteIndex == 1) myQuestSuite1CompletedThisRound = true;
          if (suiteIndex == 2) myQuestSuite2CompletedThisRound = true;
        } else {
          if (suiteIndex == 1) opponentQuestSuite1CompletedThisRound = true;
          if (suiteIndex == 2) opponentQuestSuite2CompletedThisRound = true;
        }

        if (questIndex + 1 < targetSuite.length) {
          final nextQuest = targetSuite[questIndex + 1];
          if (nextQuest.status == QuestStatus.locked) {
            nextQuest.status = QuestStatus.unlocked;
          }
        }
        return true;
      } else {
        print("DEBUG: La quête n'est pas débloquée ou est déjà complétée.");
        return false;
      }
    }
    print("DEBUG: Index de quête invalide.");
    return false;
  }

  // MODIFIÉ : Méthode pour décompléter une quête
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
        quest.status = QuestStatus.unlocked;

        if (questIndex + 1 < targetSuite.length) {
          final nextQuest = targetSuite[questIndex + 1];
          if (nextQuest.status == QuestStatus.unlocked) {
            nextQuest.status = QuestStatus.locked;
          }
        }

        if (isMyPlayer) {
          if (suiteIndex == 1) myQuestSuite1CompletedThisRound = false;
          if (suiteIndex == 2) myQuestSuite2CompletedThisRound = false;
        } else {
          if (suiteIndex == 1) opponentQuestSuite1CompletedThisRound = false;
          if (suiteIndex == 2) opponentQuestSuite2CompletedThisRound = false;
        }

        return true;
      }
    }
    return false;
  }

  int calculatePlayerTotalScore(bool isMyPlayer) {
    int score = isMyPlayer ? myScore : opponentScore;
    List<Quest> suite1 = isMyPlayer ? myQuestsSuite1 : opponentQuestsSuite1;
    List<Quest> suite2 = isMyPlayer ? myQuestsSuite2 : opponentQuestsSuite2;

    score += suite1.where((q) => q.status == QuestStatus.completed).length * 5;
    score += suite2.where((q) => q.status == QuestStatus.completed).length * 5;

    return score;
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'myScore': myScore,
      'opponentScore': opponentScore,
      'priorityPlayerId': priorityPlayerId,
      'initiativePlayerId': initiativePlayerId,
      'myQuestsSuite1': myQuestsSuite1.map((q) => q.toJson()).toList(),
      'myQuestsSuite2': myQuestsSuite2.map((q) => q.toJson()).toList(),
      'opponentQuestsSuite1': opponentQuestsSuite1.map((q) => q.toJson()).toList(),
      'opponentQuestsSuite2': opponentQuestsSuite2.map((q) => q.toJson()).toList(),
      'underdogPlayerIdAtEndOfRound': underdogPlayerIdAtEndOfRound,
      'myPlayerHadDoubleFreeTurn': myPlayerHadDoubleFreeTurn,
      'opponentPlayerHadDoubleFreeTurn': opponentPlayerHadDoubleFreeTurn,
      'myPlayerDidNonFreeDoubleTurn': myPlayerDidNonFreeDoubleTurn,
      'opponentPlayerDidNonFreeDoubleTurn': opponentPlayerDidNonFreeDoubleTurn,
      'myQuestSuite1CompletedThisRound': myQuestSuite1CompletedThisRound,
      'myQuestSuite2CompletedThisRound': myQuestSuite2CompletedThisRound,
      'opponentQuestSuite1CompletedThisRound': opponentQuestSuite1CompletedThisRound,
      'opponentQuestSuite2CompletedThisRound': opponentQuestSuite2CompletedThisRound,
    };
  }

  static QuestStatus _parseQuestStatus(String status) {
    return QuestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => QuestStatus.locked,
    );
  }
}