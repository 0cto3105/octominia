// lib/models/round.dart
import 'package:octominia/models/quest.dart';

class Round {
  final int roundNumber;
  final int myScore;
  final int opponentScore;
  final String priorityPlayerId;      // CORRECTION: Retiré '?' pour imposer une valeur
  final String initiativePlayerId;    // CORRECTION: Retiré '?' pour imposer une valeur

  final List<Quest> myQuestsSuite1;
  final List<Quest> myQuestsSuite2;
  final List<Quest> opponentQuestsSuite1;
  final List<Quest> opponentQuestsSuite2;

  final bool myQuestSuite1CompletedThisRound;
  final bool myQuestSuite2CompletedThisRound;
  final bool opponentQuestSuite1CompletedThisRound;
  final bool opponentQuestSuite2CompletedThisRound;
  
  final String? underdogPlayerIdForRound;
  final bool myPlayerIsEligibleForFreeDoubleTurn;
  final bool opponentPlayerIsEligibleForFreeDoubleTurn;
  final bool myPlayerTookDoubleTurn;
  final bool opponentPlayerTookDoubleTurn;
  final bool myPlayerTookPenalizedDoubleTurn;
  final bool opponentPlayerTookPenalizedDoubleTurn;

  // CORRECTION : Ajout de valeurs par défaut dans le constructeur
  Round({
    required this.roundNumber,
    this.myScore = 0,
    this.opponentScore = 0,
    String? priorityPlayerId,
    String? initiativePlayerId,
    required this.myQuestsSuite1,
    required this.myQuestsSuite2,
    required this.opponentQuestsSuite1,
    required this.opponentQuestsSuite2,
    this.myQuestSuite1CompletedThisRound = false,
    this.myQuestSuite2CompletedThisRound = false,
    this.opponentQuestSuite1CompletedThisRound = false,
    this.opponentQuestSuite2CompletedThisRound = false,
    this.underdogPlayerIdForRound,
    this.myPlayerIsEligibleForFreeDoubleTurn = false,
    this.opponentPlayerIsEligibleForFreeDoubleTurn = false,
    this.myPlayerTookDoubleTurn = false,
    this.opponentPlayerTookDoubleTurn = false,
    this.myPlayerTookPenalizedDoubleTurn = false,
    this.opponentPlayerTookPenalizedDoubleTurn = false,
  })  : this.priorityPlayerId = priorityPlayerId ?? 'me', // Valeur par défaut si null
        this.initiativePlayerId = initiativePlayerId ?? 'me'; // Valeur par défaut si null

  factory Round.fromJson(Map<String, dynamic> map) {
    return Round(
      roundNumber: map['roundNumber'] as int,
      myScore: map['myScore'] as int,
      opponentScore: map['opponentScore'] as int,
      priorityPlayerId: map['priorityPlayerId'] as String?, // Garder '?' pour la rétrocompatibilité des sauvegardes
      initiativePlayerId: map['initiativePlayerId'] as String?, // Garder '?' pour la rétrocompatibilité
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
      myQuestSuite1CompletedThisRound: map['myQuestSuite1CompletedThisRound'] as bool? ?? false,
      myQuestSuite2CompletedThisRound: map['myQuestSuite2CompletedThisRound'] as bool? ?? false,
      opponentQuestSuite1CompletedThisRound: map['opponentQuestSuite1CompletedThisRound'] as bool? ?? false,
      opponentQuestSuite2CompletedThisRound: map['opponentQuestSuite2CompletedThisRound'] as bool? ?? false,
      underdogPlayerIdForRound: map['underdogPlayerIdForRound'] as String?,
      myPlayerIsEligibleForFreeDoubleTurn: map['myPlayerIsEligibleForFreeDoubleTurn'] as bool? ?? false,
      opponentPlayerIsEligibleForFreeDoubleTurn: map['opponentPlayerIsEligibleForFreeDoubleTurn'] as bool? ?? false,
      myPlayerTookDoubleTurn: map['myPlayerTookDoubleTurn'] as bool? ?? false,
      opponentPlayerTookDoubleTurn: map['opponentPlayerTookDoubleTurn'] as bool? ?? false,
      myPlayerTookPenalizedDoubleTurn: map['myPlayerTookPenalizedDoubleTurn'] as bool? ?? false,
      opponentPlayerTookPenalizedDoubleTurn: map['opponentPlayerTookPenalizedDoubleTurn'] as bool? ?? false,
    );
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
      'myQuestSuite1CompletedThisRound': myQuestSuite1CompletedThisRound,
      'myQuestSuite2CompletedThisRound': myQuestSuite2CompletedThisRound,
      'opponentQuestSuite1CompletedThisRound': opponentQuestSuite1CompletedThisRound,
      'opponentQuestSuite2CompletedThisRound': opponentQuestSuite2CompletedThisRound,
      'underdogPlayerIdForRound': underdogPlayerIdForRound,
      'myPlayerIsEligibleForFreeDoubleTurn': myPlayerIsEligibleForFreeDoubleTurn,
      'opponentPlayerIsEligibleForFreeDoubleTurn': opponentPlayerIsEligibleForFreeDoubleTurn,
      'myPlayerTookDoubleTurn': myPlayerTookDoubleTurn,
      'opponentPlayerTookDoubleTurn': opponentPlayerTookDoubleTurn,
      'myPlayerTookPenalizedDoubleTurn': myPlayerTookPenalizedDoubleTurn,
      'opponentPlayerTookPenalizedDoubleTurn': opponentPlayerTookPenalizedDoubleTurn,
    };
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
    bool? myQuestSuite1CompletedThisRound,
    bool? myQuestSuite2CompletedThisRound,
    bool? opponentQuestSuite1CompletedThisRound,
    bool? opponentQuestSuite2CompletedThisRound,
    String? underdogPlayerIdForRound,
    bool? myPlayerIsEligibleForFreeDoubleTurn,
    bool? opponentPlayerIsEligibleForFreeDoubleTurn,
    bool? myPlayerTookDoubleTurn,
    bool? opponentPlayerTookDoubleTurn,
    bool? myPlayerTookPenalizedDoubleTurn,
    bool? opponentPlayerTookPenalizedDoubleTurn,
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
      myQuestSuite1CompletedThisRound: myQuestSuite1CompletedThisRound ?? this.myQuestSuite1CompletedThisRound,
      myQuestSuite2CompletedThisRound: myQuestSuite2CompletedThisRound ?? this.myQuestSuite2CompletedThisRound,
      opponentQuestSuite1CompletedThisRound: opponentQuestSuite1CompletedThisRound ?? this.opponentQuestSuite1CompletedThisRound,
      opponentQuestSuite2CompletedThisRound: opponentQuestSuite2CompletedThisRound ?? this.opponentQuestSuite2CompletedThisRound,
      underdogPlayerIdForRound: underdogPlayerIdForRound ?? this.underdogPlayerIdForRound,
      myPlayerIsEligibleForFreeDoubleTurn: myPlayerIsEligibleForFreeDoubleTurn ?? this.myPlayerIsEligibleForFreeDoubleTurn,
      opponentPlayerIsEligibleForFreeDoubleTurn: opponentPlayerIsEligibleForFreeDoubleTurn ?? this.opponentPlayerIsEligibleForFreeDoubleTurn,
      myPlayerTookDoubleTurn: myPlayerTookDoubleTurn ?? this.myPlayerTookDoubleTurn,
      opponentPlayerTookDoubleTurn: opponentPlayerTookDoubleTurn ?? this.opponentPlayerTookDoubleTurn,
      myPlayerTookPenalizedDoubleTurn: myPlayerTookPenalizedDoubleTurn ?? this.myPlayerTookPenalizedDoubleTurn,
      opponentPlayerTookPenalizedDoubleTurn: opponentPlayerTookPenalizedDoubleTurn ?? this.opponentPlayerTookPenalizedDoubleTurn,
    );
  }
}