// lib/models/game.dart
import 'package:flutter/foundation.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/models/quest.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

enum GameState {
  setup, rollOffs, round1, round2, round3, round4, round5, summary, completed,
}

enum GameResult {
  victory, defeat, equality, inProgress;
  String get displayTitle {
    switch (this) {
      case GameResult.victory: return 'Victoire';
      case GameResult.defeat: return 'Défaite';
      case GameResult.equality: return 'Égalité';
      case GameResult.inProgress: return 'En cours';
    }
  }
}

class Game {
  final String id;
  final DateTime date;
  final String myPlayerName;
  final String myFactionName;
  final String? myFactionImageUrl;
  final int myDrops;
  final bool myAuxiliaryUnits;
  final String opponentPlayerName;
  final String opponentFactionName;
  final String? opponentFactionImageUrl;
  final int opponentDrops;
  final bool opponentAuxiliaryUnits;
  final String? attackerPlayerId;
  final String? priorityPlayerIdRound1;
  final List<Round> rounds;
  final int scoreOutOf20;
  final String? notes;
  final GameState gameState;
  final String? permanentUnderdogPlayerId;

  Game({
    String? id,
    required this.date,
    required this.myPlayerName,
    required this.myFactionName,
    this.myFactionImageUrl,
    required this.myDrops,
    required this.myAuxiliaryUnits,
    required this.opponentPlayerName,
    required this.opponentFactionName,
    this.opponentFactionImageUrl,
    required this.opponentDrops,
    required this.opponentAuxiliaryUnits,
    this.attackerPlayerId,
    this.priorityPlayerIdRound1,
    List<Round>? rounds,
    int? scoreOutOf20,
    this.notes,
    GameState? gameState,
    this.permanentUnderdogPlayerId,
  })  : this.id = id ?? const Uuid().v4(),
        this.rounds = rounds ?? _initializeRounds(),
        this.scoreOutOf20 = scoreOutOf20 ?? 0,
        this.gameState = gameState ?? GameState.setup;

  GameResult get result {
    if (gameState != GameState.completed) return GameResult.inProgress;
    if (totalMyScore > totalOpponentScore) return GameResult.victory;
    if (totalMyScore < totalOpponentScore) return GameResult.defeat;
    return GameResult.equality;
  }

  int get totalMyScore {
    final int primaryScoreSum = rounds.fold(0, (sum, round) => sum + round.myScore);
    if (rounds.isEmpty) return primaryScoreSum;
    final lastRound = rounds.last;
    final int questScore =
        (lastRound.myQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5) +
        (lastRound.myQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5);
    return primaryScoreSum + questScore;
  }

  int get totalOpponentScore {
    final int primaryScoreSum = rounds.fold(0, (sum, round) => sum + round.opponentScore);
    if (rounds.isEmpty) return primaryScoreSum;
    final lastRound = rounds.last;
    final int questScore =
        (lastRound.opponentQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5) +
        (lastRound.opponentQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5);
    return primaryScoreSum + questScore;
  }

  Game updatePlayerInfo({
    String? myPlayerName, String? myFactionName, String? myFactionImageUrl, int? myDrops, bool? myAuxiliaryUnits,
    String? opponentPlayerName, String? opponentFactionName, String? opponentFactionImageUrl, int? opponentDrops, bool? opponentAuxiliaryUnits,
    String? attackerPlayerId, String? priorityPlayerIdRound1,
  }) {
    Game newGame = copyWith(
      myPlayerName: myPlayerName, myFactionName: myFactionName, myFactionImageUrl: myFactionImageUrl, myDrops: myDrops, myAuxiliaryUnits: myAuxiliaryUnits,
      opponentPlayerName: opponentPlayerName, opponentFactionName: opponentFactionName, opponentFactionImageUrl: opponentFactionImageUrl, opponentDrops: opponentDrops, opponentAuxiliaryUnits: opponentAuxiliaryUnits,
      attackerPlayerId: attackerPlayerId, priorityPlayerIdRound1: priorityPlayerIdRound1,
    );
    if (newGame.rounds.isNotEmpty && priorityPlayerIdRound1 != null) {
      newGame.rounds[0] = newGame.rounds[0].copyWith(priorityPlayerId: priorityPlayerIdRound1);
    }
    return newGame.recalculateStateFromRound(1);
  }

  Game updateRoundAndRecalculate(int roundNumber, {String? priorityPlayerId, String? initiativePlayerId}) {
    if (roundNumber < 1 || roundNumber > rounds.length) return this;
    List<Round> newRounds = List.from(rounds);
    int roundIndex = roundNumber - 1;

    newRounds[roundIndex] = newRounds[roundIndex].copyWith(
      priorityPlayerId: priorityPlayerId,
      initiativePlayerId: initiativePlayerId,
    );
    
    String? newPriorityT1 = (roundNumber == 1) ? priorityPlayerId : this.priorityPlayerIdRound1;

    return copyWith(rounds: newRounds, priorityPlayerIdRound1: newPriorityT1).recalculateStateFromRound(roundNumber);
  }

  Game setPrimaryScore({required int roundNumber, required int score, required bool isMyPlayer}) {
    if (roundNumber < 1 || roundNumber > rounds.length) return this;
    List<Round> newRounds = List.from(rounds);
    int roundIndex = roundNumber - 1;

    newRounds[roundIndex] = newRounds[roundIndex].copyWith(
      myScore: isMyPlayer ? score : null,
      opponentScore: !isMyPlayer ? score : null,
    );

    return copyWith(rounds: newRounds);
  }

  Game toggleQuest(int roundNumber, int suiteIndex, int questIndex, bool isMyPlayer) {
    if (roundNumber < 1 || roundNumber > rounds.length) return this;
    int roundIdx = roundNumber - 1;
    Round currentRound = rounds[roundIdx];
    List<Quest> targetSuite = isMyPlayer
        ? (suiteIndex == 1 ? currentRound.myQuestsSuite1 : currentRound.myQuestsSuite2)
        : (suiteIndex == 1 ? currentRound.opponentQuestsSuite1 : currentRound.opponentQuestsSuite2);

    if (questIndex < 0 || questIndex >= targetSuite.length) return this;
    final quest = targetSuite[questIndex];
    final bool isCompleting = quest.status != QuestStatus.completed;
    Round newRound;

    if (isCompleting) {
      final bool suite1Completed = isMyPlayer ? currentRound.myQuestSuite1CompletedThisRound : currentRound.opponentQuestSuite1CompletedThisRound;
      final bool suite2Completed = isMyPlayer ? currentRound.myQuestSuite2CompletedThisRound : currentRound.opponentQuestSuite2CompletedThisRound;

      if ((suiteIndex == 1 && suite1Completed) || (suiteIndex == 2 && suite2Completed) || quest.status != QuestStatus.unlocked) {
        return this;
      }
      
      targetSuite[questIndex] = quest.copyWith(status: QuestStatus.completed);
      newRound = currentRound.copyWith(
        myQuestsSuite1: isMyPlayer && suiteIndex == 1 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        myQuestsSuite2: isMyPlayer && suiteIndex == 2 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        opponentQuestsSuite1: !isMyPlayer && suiteIndex == 1 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        opponentQuestsSuite2: !isMyPlayer && suiteIndex == 2 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        myQuestSuite1CompletedThisRound: isMyPlayer && suiteIndex == 1 ? true : null,
        myQuestSuite2CompletedThisRound: isMyPlayer && suiteIndex == 2 ? true : null,
        opponentQuestSuite1CompletedThisRound: !isMyPlayer && suiteIndex == 1 ? true : null,
        opponentQuestSuite2CompletedThisRound: !isMyPlayer && suiteIndex == 2 ? true : null,
      );
    } else {
      bool nextQuestIsCompleted = (questIndex + 1 < targetSuite.length) && targetSuite[questIndex + 1].status == QuestStatus.completed;
      if (nextQuestIsCompleted) return this;

      targetSuite[questIndex] = quest.copyWith(status: QuestStatus.unlocked);
      newRound = currentRound.copyWith(
        myQuestsSuite1: isMyPlayer && suiteIndex == 1 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        myQuestsSuite2: isMyPlayer && suiteIndex == 2 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        opponentQuestsSuite1: !isMyPlayer && suiteIndex == 1 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        opponentQuestsSuite2: !isMyPlayer && suiteIndex == 2 ? targetSuite.map((q) => q.copyWith()).toList() : null,
        myQuestSuite1CompletedThisRound: isMyPlayer && suiteIndex == 1 ? false : null,
        myQuestSuite2CompletedThisRound: isMyPlayer && suiteIndex == 2 ? false : null,
        opponentQuestSuite1CompletedThisRound: !isMyPlayer && suiteIndex == 1 ? false : null,
        opponentQuestSuite2CompletedThisRound: !isMyPlayer && suiteIndex == 2 ? false : null,
      );
    }
    List<Round> newRounds = List.from(rounds);
    newRounds[roundIdx] = newRound;
    return copyWith(rounds: newRounds).recalculateStateFromRound(roundNumber);
  }

  Game recalculateStateFromRound(int startRoundNumber) {
    List<Round> newRounds = List.from(rounds);
    
    if (kDebugMode) {
      print("\n[DEBUG] === Lancement de recalculateStateFromRound (démarre au tour $startRoundNumber) ===");
      print("[DEBUG] Statut Underdog Permanent initial (depuis l'objet Game): ${this.permanentUnderdogPlayerId}");
    }

    String? gameWidePermanentUnderdogId;
    for (int i = 1; i < newRounds.length; i++) {
        Round previousRound = newRounds[i - 1];
        Round currentRoundData = newRounds[i];
        
        Map<String, int> tempScores = _getAccumulatedScoresUpToRound(i);
        int myTempScore = tempScores['myScore']!;
        int oppTempScore = tempScores['opponentScore']!;
        int tempScoreDiff = (myTempScore - oppTempScore).abs();

        String? tempUnderdogFromScore;
        if (myTempScore < oppTempScore) tempUnderdogFromScore = 'me';
        else if (oppTempScore < myTempScore) tempUnderdogFromScore = 'opponent';

        bool myIsEligible = (tempUnderdogFromScore == 'me' && tempScoreDiff >= 11);
        bool oppIsEligible = (tempUnderdogFromScore == 'opponent' && tempScoreDiff >= 11);
        
        final tempPriorityLastRound = previousRound.priorityPlayerId;
        bool myTookDT = (currentRoundData.initiativePlayerId == 'me' && currentRoundData.priorityPlayerId == 'me' && tempPriorityLastRound == 'opponent');
        bool oppTookDT = (currentRoundData.initiativePlayerId == 'opponent' && currentRoundData.priorityPlayerId == 'opponent' && tempPriorityLastRound == 'me');

        if (myTookDT && !myIsEligible) gameWidePermanentUnderdogId = 'opponent';
        if (oppTookDT && !oppIsEligible) gameWidePermanentUnderdogId = 'me';
    }
    
    if (kDebugMode) {
      print("[DEBUG] Statut Underdog Permanent déterminé pour toute la partie (après scan): $gameWidePermanentUnderdogId");
    }

    for (int i = 0; i < newRounds.length; i++) {
      int roundNumber = i + 1;
      
      if (roundNumber == 1) {
        final round1 = newRounds[i];
        final priority = round1.priorityPlayerId ?? this.priorityPlayerIdRound1;
        if (round1.priorityPlayerId != priority || round1.initiativePlayerId != priority) {
          newRounds[i] = round1.copyWith(priorityPlayerId: priority, initiativePlayerId: priority);
        }
        continue;
      }
      
      if (kDebugMode) {
        print("\n[DEBUG] --- Calcul pour le Tour $roundNumber ---");
      }
      
      Round previousRound = newRounds[i - 1];
      Round currentRoundData = newRounds[i];

      List<Quest> myQuests1 = _propagateQuestStatus(previousRound.myQuestsSuite1, currentRoundData.myQuestsSuite1);
      List<Quest> myQuests2 = _propagateQuestStatus(previousRound.myQuestsSuite2, currentRoundData.myQuestsSuite2);
      List<Quest> oppQuests1 = _propagateQuestStatus(previousRound.opponentQuestsSuite1, currentRoundData.opponentQuestsSuite1);
      List<Quest> oppQuests2 = _propagateQuestStatus(previousRound.opponentQuestsSuite2, currentRoundData.opponentQuestsSuite2);

      Map<String, int> previousScores = _getAccumulatedScoresUpToRound(i);
      int myPreviousScore = previousScores['myScore']!;
      int opponentPreviousScore = previousScores['opponentScore']!;
      int scoreDiff = (myPreviousScore - opponentPreviousScore).abs();

      if (kDebugMode) {
        print("[DEBUG] Scores cumulés du tour précédent (fin T.${i}): Moi=$myPreviousScore, Adv=$opponentPreviousScore");
      }
      
      String? underdogFromScore;
      if (myPreviousScore < opponentPreviousScore) {
        underdogFromScore = 'me';
      } else if (opponentPreviousScore < myPreviousScore) {
        underdogFromScore = 'opponent';
      } else {
        underdogFromScore = null;
      }
      
      String? finalUnderdogThisRound = gameWidePermanentUnderdogId ?? underdogFromScore;
      
      if (kDebugMode) {
        print("[DEBUG] Underdog basé sur score: $underdogFromScore. Underdog final appliqué: $finalUnderdogThisRound");
      }
      
      final priorityLastRound = previousRound.priorityPlayerId;
      bool myIsEligibleForFreeDT = (finalUnderdogThisRound == 'me' && scoreDiff >= 11 && priorityLastRound == 'opponent');
      bool oppIsEligibleForFreeDT = (finalUnderdogThisRound == 'opponent' && scoreDiff >= 11 && priorityLastRound == 'me');
      
      if (kDebugMode) {
        print("[DEBUG] Éligibilité DT Gratuit: Moi=$myIsEligibleForFreeDT, Adv=$oppIsEligibleForFreeDT");
      }
      
      bool myTookDoubleTurn = (currentRoundData.initiativePlayerId == 'me' && currentRoundData.priorityPlayerId == 'me' && priorityLastRound == 'opponent');
      bool oppTookDoubleTurn = (currentRoundData.initiativePlayerId == 'opponent' && currentRoundData.priorityPlayerId == 'opponent' && priorityLastRound == 'me');
      
      bool myTookPenalizedDT = myTookDoubleTurn && !myIsEligibleForFreeDT;
      bool oppTookPenalizedDT = oppTookDoubleTurn && !oppIsEligibleForFreeDT;
      
      newRounds[i] = currentRoundData.copyWith(
        myQuestsSuite1: myQuests1, myQuestsSuite2: myQuests2, opponentQuestsSuite1: oppQuests1, opponentQuestsSuite2: oppQuests2,
        underdogPlayerIdForRound: finalUnderdogThisRound,
        myPlayerIsEligibleForFreeDoubleTurn: myIsEligibleForFreeDT,
        opponentPlayerIsEligibleForFreeDoubleTurn: oppIsEligibleForFreeDT,
        myPlayerTookDoubleTurn: myTookDoubleTurn,
        opponentPlayerTookDoubleTurn: oppTookDoubleTurn,
        myPlayerTookPenalizedDoubleTurn: myTookPenalizedDT,
        opponentPlayerTookPenalizedDoubleTurn: oppTookPenalizedDT,
      );
    }
    
    final String? finalPriorityT1 = newRounds.isNotEmpty ? newRounds[0].priorityPlayerId : this.priorityPlayerIdRound1;
    
    if (kDebugMode) {
      print("[DEBUG] === Fin de recalculateStateFromRound ===");
    }

    return copyWith(
      rounds: newRounds,
      permanentUnderdogPlayerId: gameWidePermanentUnderdogId,
      priorityPlayerIdRound1: finalPriorityT1,
    );
  }
  
  Map<String, int> _getAccumulatedScoresUpToRound(int roundIndex) {
    if (roundIndex == 0) return {'myScore': 0, 'opponentScore': 0};

    int myPrimaryScoreSum = 0;
    int oppPrimaryScoreSum = 0;
    for (int i = 0; i < roundIndex; i++) {
      myPrimaryScoreSum += rounds[i].myScore;
      oppPrimaryScoreSum += rounds[i].opponentScore;
    }

    final lastRoundInRange = rounds[roundIndex - 1];
    final int myQuestScore =
        (lastRoundInRange.myQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5) +
        (lastRoundInRange.myQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5);
    final int oppQuestScore =
        (lastRoundInRange.opponentQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5) +
        (lastRoundInRange.opponentQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5);

    return {
      'myScore': myPrimaryScoreSum + myQuestScore,
      'opponentScore': oppPrimaryScoreSum + oppQuestScore,
    };
  }

  List<Quest> _propagateQuestStatus(List<Quest> previousQuests, List<Quest> currentQuestsData) {
    List<Quest> newQuests = _createInitialQuests();

    for (int i = 0; i < newQuests.length; i++) {
      if (previousQuests[i].status == QuestStatus.completed || currentQuestsData[i].status == QuestStatus.completed) {
        newQuests[i].status = QuestStatus.completed;
      }
    }

    for (int i = 0; i < newQuests.length - 1; i++) {
      if (newQuests[i].status == QuestStatus.completed && newQuests[i + 1].status == QuestStatus.locked) {
        newQuests[i + 1].status = QuestStatus.unlocked;
      }
    }
    return newQuests;
  }
  
  static List<Round> _initializeRounds() {
    return List.generate(5, (i) => Round(
        roundNumber: i + 1,
        myQuestsSuite1: _createInitialQuests(), myQuestsSuite2: _createInitialQuests(),
        opponentQuestsSuite1: _createInitialQuests(), opponentQuestsSuite2: _createInitialQuests(),
    ));
  }

  static List<Quest> _createInitialQuests() {
    final List<String> questNames = ["Affray", "Strike", "Domination"];
    return List.generate(3, (index) => Quest(
        id: index + 1, name: questNames[index],
        status: index == 0 ? QuestStatus.unlocked : QuestStatus.locked,
    ));
  }

  Game copyWith({
    String? id, DateTime? date, String? myPlayerName, String? myFactionName, String? myFactionImageUrl, int? myDrops, bool? myAuxiliaryUnits,
    String? opponentPlayerName, String? opponentFactionName, String? opponentFactionImageUrl, int? opponentDrops, bool? opponentAuxiliaryUnits,
    String? attackerPlayerId, String? priorityPlayerIdRound1, List<Round>? rounds, int? scoreOutOf20, String? notes, GameState? gameState,
    dynamic permanentUnderdogPlayerId = const Object(),
  }) {
    return Game(
      id: id ?? this.id, date: date ?? this.date, myPlayerName: myPlayerName ?? this.myPlayerName, myFactionName: myFactionName ?? this.myFactionName,
      myFactionImageUrl: myFactionImageUrl ?? this.myFactionImageUrl, myDrops: myDrops ?? this.myDrops, myAuxiliaryUnits: myAuxiliaryUnits ?? this.myAuxiliaryUnits,
      opponentPlayerName: opponentPlayerName ?? this.opponentPlayerName, opponentFactionName: opponentFactionName ?? this.opponentFactionName,
      opponentFactionImageUrl: opponentFactionImageUrl ?? this.opponentFactionImageUrl, opponentDrops: opponentDrops ?? this.opponentDrops,
      opponentAuxiliaryUnits: opponentAuxiliaryUnits ?? this.opponentAuxiliaryUnits, attackerPlayerId: attackerPlayerId ?? this.attackerPlayerId,
      priorityPlayerIdRound1: priorityPlayerIdRound1 ?? this.priorityPlayerIdRound1, rounds: rounds ?? this.rounds.map((r) => r.copyWith()).toList(),
      scoreOutOf20: scoreOutOf20 ?? this.scoreOutOf20, notes: notes ?? this.notes, gameState: gameState ?? this.gameState,
      permanentUnderdogPlayerId: permanentUnderdogPlayerId is String? ? permanentUnderdogPlayerId : this.permanentUnderdogPlayerId,
    );
  }

  factory Game.fromJson(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String?, date: DateTime.parse(map['date'] as String), myPlayerName: map['myPlayerName'] as String, myFactionName: map['myFactionName'] as String,
      myFactionImageUrl: map['myFactionImageUrl'] as String?, myDrops: map['myDrops'] as int, myAuxiliaryUnits: (map['myAuxiliaryUnits'] as bool? ?? false),
      opponentPlayerName: map['opponentPlayerName'] as String, opponentFactionName: map['opponentFactionName'] as String,
      opponentFactionImageUrl: map['opponentFactionImageUrl'] as String?, opponentDrops: map['opponentDrops'] as int,
      opponentAuxiliaryUnits: (map['opponentAuxiliaryUnits'] as bool? ?? false), attackerPlayerId: map['attackerPlayerId'] as String?,
      priorityPlayerIdRound1: map['priorityPlayerIdRound1'] as String?,
      rounds: (map['rounds'] as List<dynamic>).map((e) => Round.fromJson(e as Map<String, dynamic>)).toList(),
      scoreOutOf20: map['scoreOutOf20'] as int? ?? 0, notes: map['notes'] as String?,
      gameState: GameState.values.firstWhere((e) => e.name == map['gameState'], orElse: () => GameState.setup),
      permanentUnderdogPlayerId: map['permanentUnderdogPlayerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'date': date.toIso8601String(), 'myPlayerName': myPlayerName, 'myFactionName': myFactionName, 'myFactionImageUrl': myFactionImageUrl,
      'myDrops': myDrops, 'myAuxiliaryUnits': myAuxiliaryUnits, 'opponentPlayerName': opponentPlayerName, 'opponentFactionName': opponentFactionName,
      'opponentFactionImageUrl': opponentFactionImageUrl, 'opponentDrops': opponentDrops, 'opponentAuxiliaryUnits': opponentAuxiliaryUnits,
      'attackerPlayerId': attackerPlayerId, 'priorityPlayerIdRound1': priorityPlayerIdRound1, 'rounds': rounds.map((r) => r.toJson()).toList(),
      'scoreOutOf20': scoreOutOf20, 'notes': notes, 'gameState': gameState.name, 'permanentUnderdogPlayerId': permanentUnderdogPlayerId,
    };
  }
  
  Map<String, int> getFinalScoresOutOf20() {
    int myTotalScore = this.totalMyScore;
    int opponentTotalScore = this.totalOpponentScore;
    int scoreDiff = (myTotalScore - opponentTotalScore).abs();

    if (myTotalScore > totalOpponentScore) {
      int myFinalScore = Game.getWinningScore(scoreDiff);
      return {'myFinalScore': myFinalScore, 'opponentFinalScore': 20 - myFinalScore};
    } else if (opponentTotalScore > myTotalScore) {
      int opponentFinalScore = Game.getWinningScore(scoreDiff);
      return {'myFinalScore': 20 - opponentFinalScore, 'opponentFinalScore': opponentFinalScore};
    } else {
      return {'myFinalScore': 10, 'opponentFinalScore': 10};
    }
  }

  static int getWinningScore(int diff) {
    if (diff >= 46) return 20; if (diff >= 41) return 19; if (diff >= 36) return 18; if (diff >= 31) return 17;
    if (diff >= 26) return 16; if (diff >= 21) return 15; if (diff >= 16) return 14; if (diff >= 11) return 13;
    if (diff >= 6) return 12; if (diff >= 1) return 11;
    return 10;
  }
}