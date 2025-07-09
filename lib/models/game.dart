// lib/models/game.dart
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
  final String attackerPlayerId;
  final String priorityPlayerIdRound1;
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
    String? attackerPlayerId,
    String? priorityPlayerIdRound1,
    List<Round>? rounds,
    int? scoreOutOf20,
    this.notes,
    GameState? gameState,
    this.permanentUnderdogPlayerId,
  })  : this.id = id ?? const Uuid().v4(),
        this.attackerPlayerId = attackerPlayerId ?? 'me',
        this.priorityPlayerIdRound1 = priorityPlayerIdRound1 ?? 'me',
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
    final primaryScore = rounds.fold(0, (sum, round) => sum + round.myScore);
    if (rounds.isEmpty) return primaryScore;
    final lastRound = rounds.last;
    final questScore =
        (lastRound.myQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5) +
        (lastRound.myQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5);
    return primaryScore + questScore;
  }

  int get totalOpponentScore {
    final primaryScore = rounds.fold(0, (sum, round) => sum + round.opponentScore);
    if (rounds.isEmpty) return primaryScore;
    final lastRound = rounds.last;
    final questScore =
        (lastRound.opponentQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5) +
        (lastRound.opponentQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5);
    return primaryScore + questScore;
  }

  Game updatePlayerInfo({
    String? myPlayerName, String? myFactionName, String? myFactionImageUrl, int? myDrops, bool? myAuxiliaryUnits,
    String? opponentPlayerName, String? opponentFactionName, String? opponentFactionImageUrl, int? opponentDrops, bool? opponentAuxiliaryUnits,
    String? attackerPlayerId, String? priorityPlayerIdRound1,
  }) {
    return copyWith(
      myPlayerName: myPlayerName, myFactionName: myFactionName, myFactionImageUrl: myFactionImageUrl, myDrops: myDrops, myAuxiliaryUnits: myAuxiliaryUnits,
      opponentPlayerName: opponentPlayerName, opponentFactionName: opponentFactionName, opponentFactionImageUrl: opponentFactionImageUrl, opponentDrops: opponentDrops, opponentAuxiliaryUnits: opponentAuxiliaryUnits,
      attackerPlayerId: attackerPlayerId, priorityPlayerIdRound1: priorityPlayerIdRound1,
    ).recalculateStateFromRound(1);
  }

  Game updateRound(int roundNumber, {int? myScore, int? opponentScore, String? priorityPlayerId, String? initiativePlayerId}) {
    if (roundNumber < 1 || roundNumber > rounds.length) return this;
    List<Round> newRounds = List.from(rounds);
    int roundIndex = roundNumber - 1;
    newRounds[roundIndex] = newRounds[roundIndex].copyWith(
      myScore: myScore, opponentScore: opponentScore, priorityPlayerId: priorityPlayerId, initiativePlayerId: initiativePlayerId,
    );
    return copyWith(rounds: newRounds).recalculateStateFromRound(roundNumber);
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
      bool alreadyCompletedThisRound = isMyPlayer
          ? (suiteIndex == 1 ? currentRound.myQuestSuite1CompletedThisRound : currentRound.myQuestSuite2CompletedThisRound)
          : (suiteIndex == 1 ? currentRound.opponentQuestSuite1CompletedThisRound : currentRound.opponentQuestSuite2CompletedThisRound);
      if (alreadyCompletedThisRound || quest.status != QuestStatus.unlocked) return this;
      
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
    String? currentPermanentUnderdogId = this.permanentUnderdogPlayerId;

    for (int i = 0; i < rounds.length; i++) {
      if (i < startRoundNumber - 1) continue;

      int roundNumber = i + 1;
      
      // CORRECTION : Ajout de la gestion de l'exception du Round 1
      if (roundNumber == 1) {
        newRounds[i] = newRounds[i].copyWith(
          underdogPlayerIdForRound: null, // Pas d'underdog au round 1
          myPlayerIsEligibleForFreeDoubleTurn: false,
          opponentPlayerIsEligibleForFreeDoubleTurn: false,
          myPlayerTookDoubleTurn: false,
          opponentPlayerTookDoubleTurn: false,
          myPlayerTookPenalizedDoubleTurn: false,
          opponentPlayerTookPenalizedDoubleTurn: false
        );
        continue; // Passe au round suivant
      }
      
      Round previousRound = newRounds[i - 1];
      Round currentRoundData = newRounds[i];

      List<Quest> myQuests1 = _propagateQuestStatus(previousRound.myQuestsSuite1, currentRoundData.myQuestsSuite1);
      List<Quest> myQuests2 = _propagateQuestStatus(previousRound.myQuestsSuite2, currentRoundData.myQuestsSuite2);
      List<Quest> oppQuests1 = _propagateQuestStatus(previousRound.opponentQuestsSuite1, currentRoundData.opponentQuestsSuite1);
      List<Quest> oppQuests2 = _propagateQuestStatus(previousRound.opponentQuestsSuite2, currentRoundData.opponentQuestsSuite2);

      Map<String, int> previousScores = _getAccumulatedScoresUpToRound(roundNumber);
      int myPreviousScore = previousScores['myScore']!;
      int opponentPreviousScore = previousScores['opponentScore']!;
      
      String? underdogIdForRound = currentPermanentUnderdogId;
      if (underdogIdForRound == null) {
        if (myPreviousScore < opponentPreviousScore) {
          underdogIdForRound = 'me';
        } else if (opponentPreviousScore < myPreviousScore) {
          underdogIdForRound = 'opponent';
        }
      }

      int scoreDiff = (myPreviousScore - opponentPreviousScore).abs();
      bool myIsEligible = (underdogIdForRound == 'me' && scoreDiff >= 11);
      bool oppIsEligible = (underdogIdForRound == 'opponent' && scoreDiff >= 11);

      final priorityLastRound = newRounds[i-1].priorityPlayerId;
      
      bool myTookDoubleTurn = currentRoundData.initiativePlayerId == 'me' && currentRoundData.priorityPlayerId == 'me' && priorityLastRound == 'opponent';
      bool oppTookDoubleTurn = currentRoundData.initiativePlayerId == 'opponent' && currentRoundData.priorityPlayerId == 'opponent' && priorityLastRound == 'me';
      
      bool myTookPenalizedDT = myTookDoubleTurn && !myIsEligible;
      bool oppTookPenalizedDT = oppTookDoubleTurn && !oppIsEligible;

      if (myTookPenalizedDT) currentPermanentUnderdogId = 'opponent';
      if (oppTookPenalizedDT) currentPermanentUnderdogId = 'me';

      newRounds[i] = newRounds[i].copyWith(
        myQuestsSuite1: myQuests1, myQuestsSuite2: myQuests2, opponentQuestsSuite1: oppQuests1, opponentQuestsSuite2: oppQuests2,
        underdogPlayerIdForRound: underdogIdForRound,
        myPlayerIsEligibleForFreeDoubleTurn: myIsEligible,
        opponentPlayerIsEligibleForFreeDoubleTurn: oppIsEligible,
        myPlayerTookDoubleTurn: myTookDoubleTurn,
        opponentPlayerTookDoubleTurn: oppTookDoubleTurn,
        myPlayerTookPenalizedDoubleTurn: myTookPenalizedDT,
        opponentPlayerTookPenalizedDoubleTurn: oppTookPenalizedDT,
      );
    }
    
    return copyWith(rounds: newRounds, permanentUnderdogPlayerId: currentPermanentUnderdogId);
  }
  
  Map<String, int> _getAccumulatedScoresUpToRound(int roundNumber) {
    if (roundNumber <= 1) return {'myScore': 0, 'opponentScore': 0};
    int myScore = 0;
    int oppScore = 0;
    
    for(int i = 0; i < roundNumber - 1; i++) {
        myScore += rounds[i].myScore;
        oppScore += rounds[i].opponentScore;
    }
    
    final previousRound = rounds[roundNumber - 2];
    myScore += previousRound.myQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5;
    myScore += previousRound.myQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5;
    oppScore += previousRound.opponentQuestsSuite1.where((q) => q.status == QuestStatus.completed).length * 5;
    oppScore += previousRound.opponentQuestsSuite2.where((q) => q.status == QuestStatus.completed).length * 5;

    return {'myScore': myScore, 'opponentScore': oppScore};
  }

  List<Quest> _propagateQuestStatus(List<Quest> previousQuests, List<Quest> currentQuestsData) {
    List<Quest> newQuests = _createInitialQuests();
    for (int i = 0; i < newQuests.length; i++) {
      if (previousQuests[i].status == QuestStatus.completed || currentQuestsData[i].status == QuestStatus.completed) {
        newQuests[i].status = QuestStatus.completed;
      }
    }
    for (int i = 0; i < newQuests.length; i++) {
      if (newQuests[i].status == QuestStatus.completed) {
        if (i + 1 < newQuests.length && newQuests[i + 1].status == QuestStatus.locked) {
          newQuests[i + 1].status = QuestStatus.unlocked;
        }
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
    String? permanentUnderdogPlayerId,
  }) {
    return Game(
      id: id ?? this.id, date: date ?? this.date, myPlayerName: myPlayerName ?? this.myPlayerName, myFactionName: myFactionName ?? this.myFactionName,
      myFactionImageUrl: myFactionImageUrl ?? this.myFactionImageUrl, myDrops: myDrops ?? this.myDrops, myAuxiliaryUnits: myAuxiliaryUnits ?? this.myAuxiliaryUnits,
      opponentPlayerName: opponentPlayerName ?? this.opponentPlayerName, opponentFactionName: opponentFactionName ?? this.opponentFactionName,
      opponentFactionImageUrl: opponentFactionImageUrl ?? this.opponentFactionImageUrl, opponentDrops: opponentDrops ?? this.opponentDrops,
      opponentAuxiliaryUnits: opponentAuxiliaryUnits ?? this.opponentAuxiliaryUnits, attackerPlayerId: attackerPlayerId ?? this.attackerPlayerId,
      priorityPlayerIdRound1: priorityPlayerIdRound1 ?? this.priorityPlayerIdRound1, rounds: rounds ?? this.rounds.map((r) => r.copyWith()).toList(),
      scoreOutOf20: scoreOutOf20 ?? this.scoreOutOf20, notes: notes ?? this.notes, gameState: gameState ?? this.gameState,
      permanentUnderdogPlayerId: permanentUnderdogPlayerId ?? this.permanentUnderdogPlayerId,
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
  
  static int calculateScoreOutOf20(Game game) {
    int myTotalScore = game.totalMyScore; int opponentTotalScore = game.totalOpponentScore;
    int scoreDiff = (myTotalScore - opponentTotalScore).abs();
    if (myTotalScore > opponentTotalScore) return getWinningScore(scoreDiff);
    if (opponentTotalScore > myTotalScore) return getLosingScore(scoreDiff);
    return 10;
  }

  static int getWinningScore(int diff) {
    if (diff >= 46) return 20; if (diff >= 41) return 19; if (diff >= 36) return 18; if (diff >= 31) return 17;
    if (diff >= 26) return 16; if (diff >= 21) return 15; if (diff >= 16) return 14; if (diff >= 11) return 13;
    if (diff >= 6) return 12; if (diff >= 1) return 11;
    return 10;
  }

  static int getLosingScore(int diff) {
    if (diff >= 46) return 0; if (diff >= 41) return 1; if (diff >= 36) return 2; if (diff >= 31) return 3;
    if (diff >= 26) return 4; if (diff >= 21) return 5; if (diff >= 16) return 6; if (diff >= 11) return 7;
    if (diff >= 6) return 8; if (diff >= 1) return 9;
    return 10;
  }
}