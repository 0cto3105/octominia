// lib/models/game.dart
import 'package:octominia/models/round.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

enum GameState {
  setup,
  rollOffs,
  round1,
  round2,
  round3,
  round4,
  round5,
  summary,
  completed,
}

enum GameResult {
  victory,
  defeat,
  equality,
  inProgress;

  String get displayTitle {
    switch (this) {
      case GameResult.victory:
        return 'Victoire';
      case GameResult.defeat:
        return 'Défaite';
      case GameResult.equality:
        return 'Égalité';
      case GameResult.inProgress:
        return 'En cours';
    }
  }
}

class Game {
  String id;
  DateTime date;
  String myPlayerName;
  String myFactionName;
  String? myFactionImageUrl;
  int myScore; // This will now represent overall score.
  int myDrops;
  bool myAuxiliaryUnits;
  String opponentPlayerName;
  String opponentFactionName;
  String? opponentFactionImageUrl;
  int opponentScore; // This will now represent overall score.
  int opponentDrops;
  bool opponentAuxiliaryUnits;
  String? attackerPlayerId;
  String? priorityPlayerIdRound1;
  List<Round> rounds;
  int scoreOutOf20;
  String? notes;
  GameState gameState;
  String? underdogPlayerIdForGame;

  // Constructor
  Game({
    String? id,
    required this.date,
    required this.myPlayerName,
    required this.myFactionName,
    this.myFactionImageUrl,
    required this.myScore,
    required this.myDrops,
    required this.myAuxiliaryUnits,
    required this.opponentPlayerName,
    required this.opponentFactionName,
    this.opponentFactionImageUrl,
    required this.opponentScore,
    required this.opponentDrops,
    required this.opponentAuxiliaryUnits,
    this.attackerPlayerId,
    this.priorityPlayerIdRound1,
    List<Round>? rounds,
    int? scoreOutOf20,
    this.notes,
    GameState? gameState,
    this.underdogPlayerIdForGame,
  })  : id = id ?? const Uuid().v4(),
        rounds = rounds ?? _initializeRounds(5),
        scoreOutOf20 = scoreOutOf20 ?? 0,
        gameState = gameState ?? GameState.setup;

  GameResult get result {
    if (gameState != GameState.completed) {
      return GameResult.inProgress;
    } else {
      if (totalMyScore > totalOpponentScore) {
        return GameResult.victory;
      } else if (totalMyScore < totalOpponentScore) {
        return GameResult.defeat;
      } else {
        return GameResult.equality;
      }
    }
  }

  int get totalMyScore {
    return rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(true));
  }

  int get totalOpponentScore {
    return rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(false));
  }

  // NOUVEAU : Méthode statique pour initialiser la liste des rounds avec héritage des quêtes
  static List<Round> _initializeRounds(int numberOfRounds) {
    List<Round> generatedRounds = [];
    for (int i = 0; i < numberOfRounds; i++) {
      if (i == 0) {
        generatedRounds.add(Round(
          roundNumber: i + 1,
          myScore: 0,
          opponentScore: 0,
          priorityPlayerId: null,
          myQuestsSuite1: Round.createInitialQuests(isMyPlayer: true, suiteNumber: 1),
          myQuestsSuite2: Round.createInitialQuests(isMyPlayer: true, suiteNumber: 2),
          opponentQuestsSuite1: Round.createInitialQuests(isMyPlayer: false, suiteNumber: 1),
          opponentQuestsSuite2: Round.createInitialQuests(isMyPlayer: false, suiteNumber: 2),
        ));
      } else {
        final previousRound = generatedRounds[i - 1];
        generatedRounds.add(Round(
          roundNumber: i + 1,
          myScore: 0,
          opponentScore: 0,
          priorityPlayerId: null,
          myQuestsSuite1: Round.initializeQuestsFromPreviousRound(previousRound.myQuestsSuite1),
          myQuestsSuite2: Round.initializeQuestsFromPreviousRound(previousRound.myQuestsSuite2),
          opponentQuestsSuite1: Round.initializeQuestsFromPreviousRound(previousRound.opponentQuestsSuite1),
          opponentQuestsSuite2: Round.initializeQuestsFromPreviousRound(previousRound.opponentQuestsSuite2),
          myQuestSuite1CompletedThisRound: false,
          myQuestSuite2CompletedThisRound: false,
          opponentQuestSuite1CompletedThisRound: false,
          opponentQuestSuite2CompletedThisRound: false,
        ));
      }
    }
    return generatedRounds;
  }

  Game copyWith({
    String? id,
    DateTime? date,
    String? myPlayerName,
    String? myFactionName,
    String? myFactionImageUrl,
    int? myScore,
    int? myDrops,
    bool? myAuxiliaryUnits,
    String? opponentPlayerName,
    String? opponentFactionName,
    String? opponentFactionImageUrl,
    int? opponentScore,
    int? opponentDrops,
    bool? opponentAuxiliaryUnits,
    String? attackerPlayerId,
    String? priorityPlayerIdRound1,
    List<Round>? rounds,
    int? scoreOutOf20,
    String? notes,
    GameState? gameState,
    String? underdogPlayerIdForGame,
  }) {
    return Game(
      id: id ?? this.id,
      date: date ?? this.date,
      myPlayerName: myPlayerName ?? this.myPlayerName,
      myFactionName: myFactionName ?? this.myFactionName,
      myFactionImageUrl: myFactionImageUrl ?? this.myFactionImageUrl,
      myScore: myScore ?? this.myScore,
      myDrops: myDrops ?? this.myDrops,
      myAuxiliaryUnits: myAuxiliaryUnits ?? this.myAuxiliaryUnits,
      opponentPlayerName: opponentPlayerName ?? this.opponentPlayerName,
      opponentFactionName: opponentFactionName ?? this.opponentFactionName,
      opponentFactionImageUrl: opponentFactionImageUrl ?? this.opponentFactionImageUrl,
      opponentScore: opponentScore ?? this.opponentScore,
      opponentDrops: opponentDrops ?? this.opponentDrops,
      opponentAuxiliaryUnits: opponentAuxiliaryUnits ?? this.opponentAuxiliaryUnits,
      attackerPlayerId: attackerPlayerId ?? this.attackerPlayerId,
      priorityPlayerIdRound1: priorityPlayerIdRound1 ?? this.priorityPlayerIdRound1,
      rounds: rounds ?? this.rounds.map((r) => r.copyWith()).toList(),
      scoreOutOf20: scoreOutOf20 ?? this.scoreOutOf20,
      notes: notes ?? this.notes,
      gameState: gameState ?? this.gameState,
      underdogPlayerIdForGame: underdogPlayerIdForGame ?? this.underdogPlayerIdForGame,
    );
  }

  factory Game.fromJson(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String?,
      date: DateTime.parse(map['date'] as String),
      myPlayerName: map['myPlayerName'] as String,
      myFactionName: map['myFactionName'] as String,
      myFactionImageUrl: map['myFactionImageUrl'] as String?,
      myScore: map['myScore'] as int,
      myDrops: map['myDrops'] as int,
      myAuxiliaryUnits: (map['myAuxiliaryUnits'] as int) == 1,
      opponentPlayerName: map['opponentPlayerName'] as String,
      opponentFactionName: map['opponentFactionName'] as String,
      opponentFactionImageUrl: map['opponentFactionImageUrl'] as String?,
      opponentScore: map['opponentScore'] as int,
      opponentDrops: map['opponentDrops'] as int,
      opponentAuxiliaryUnits: (map['opponentAuxiliaryUnits'] as int) == 1,
      attackerPlayerId: map['attackerPlayerId'] as String?,
      priorityPlayerIdRound1: map['priorityPlayerIdRound1'] as String?,
      rounds: (map['rounds'] as List<dynamic>)
          .map((e) => Round.fromJson(e as Map<String, dynamic>))
          .toList(),
      scoreOutOf20: map['scoreOutOf20'] as int? ?? 0,
      notes: map['notes'] as String?,
      gameState: GameState.values.firstWhere(
          (e) => e.name == map['gameState'],
          orElse: () => GameState.setup),
      underdogPlayerIdForGame: map['underdogPlayerIdForGame'] as String?,
    );
  }

  // Re-added toJson method for Game class
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'myPlayerName': myPlayerName,
      'myFactionName': myFactionName,
      'myFactionImageUrl': myFactionImageUrl,
      'myScore': myScore,
      'myDrops': myDrops,
      'myAuxiliaryUnits': myAuxiliaryUnits ? 1 : 0,
      'opponentPlayerName': opponentPlayerName,
      'opponentFactionName': opponentFactionName,
      'opponentFactionImageUrl': opponentFactionImageUrl,
      'opponentScore': opponentScore,
      'opponentDrops': opponentDrops,
      'opponentAuxiliaryUnits': opponentAuxiliaryUnits ? 1 : 0,
      'attackerPlayerId': attackerPlayerId,
      'priorityPlayerIdRound1': priorityPlayerIdRound1,
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'result': result.name,
      'scoreOutOf20': scoreOutOf20,
      'notes': notes,
      'gameState': gameState.name,
      'underdogPlayerIdForGame': underdogPlayerIdForGame,
    };
  }

static int calculateScoreOutOf20(Game game) {
    int myTotalScore = game.totalMyScore;
    int opponentTotalScore = game.totalOpponentScore;

    int scoreDiff = (myTotalScore - opponentTotalScore).abs(); // Correction ici pour .abs()
    int myScoreOutOf20;

    // Déterminer qui est le gagnant et le perdant pour assigner les scores du tableau
    if (myTotalScore > opponentTotalScore) { // Je suis le gagnant
        myScoreOutOf20 = getWinningScore(scoreDiff);
        // opponentScoreOutOf20 = getLosingScore(scoreDiff); // Non utilisé pour le retour direct
    } else if (opponentTotalScore > myTotalScore) { // L'adversaire est le gagnant
        myScoreOutOf20 = getLosingScore(scoreDiff);
        // opponentScoreOutOf20 = getWinningScore(scoreDiff); // Non utilisé pour le retour direct
    } else { // Égalité
        myScoreOutOf20 = 10;
        // opponentScoreOutOf20 = 10; // Non utilisé pour le retour direct
    }
    
    return myScoreOutOf20;
}

// Fonctions utilitaires pour récupérer les scores du tableau
static int getWinningScore(int diff) {
    if (diff == 0) return 10;
    if (diff >= 1 && diff <= 5) return 11;
    if (diff >= 6 && diff <= 10) return 12;
    if (diff >= 11 && diff <= 15) return 13;
    if (diff >= 16 && diff <= 20) return 14;
    if (diff >= 21 && diff <= 25) return 15;
    if (diff >= 26 && diff <= 30) return 16;
    if (diff >= 31 && diff <= 35) return 17;
    if (diff >= 36 && diff <= 40) return 18;
    if (diff >= 41 && diff <= 45) return 19;
    if (diff >= 46) return 20;
    return 0; // Cas par défaut, ou gestion d'erreur si l'écart est négatif (ne devrait pas arriver avec Math.abs)
}

static int getLosingScore(int diff) {
    if (diff == 0) return 10;
    if (diff >= 1 && diff <= 5) return 9;
    if (diff >= 6 && diff <= 10) return 8;
    if (diff >= 11 && diff <= 15) return 7;
    if (diff >= 16 && diff <= 20) return 6;
    if (diff >= 21 && diff <= 25) return 5;
    if (diff >= 26 && diff <= 30) return 4;
    if (diff >= 31 && diff <= 35) return 3;
    if (diff >= 36 && diff <= 40) return 2;
    if (diff >= 41 && diff <= 45) return 1;
    if (diff >= 46) return 0;
    return 0; // Cas par défaut
}
}