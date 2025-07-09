// lib/models/game.dart

import 'package:octominia/models/round.dart';
import 'package:uuid/uuid.dart';

// Define the GameState enum
enum GameState {
  setup,
  rollOffs,
  round1,
  round2,
  round3,
  round4,
  round5,
  summary, // Reached the summary screen, but not yet "completed"
  completed, // Game finished and validated
}

class Game {
  String id;
  DateTime date;
  String myPlayerName;
  String myFactionName;
  String? myFactionImageUrl;
  int myScore;
  int myDrops;
  bool myAuxiliaryUnits;
  String opponentPlayerName;
  String opponentFactionName;
  String? opponentFactionImageUrl;
  int opponentScore;
  int opponentDrops;
  bool opponentAuxiliaryUnits;
  String? attackerPlayerId;
  String? priorityPlayerIdRound1;
  List<Round> rounds;
  String result;
  int scoreOutOf20;
  String? notes;
  GameState gameState;
  String? underdogPlayerIdForGame; // NEW: Field to track the underdog for the entire game

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
    required this.result,
    required this.scoreOutOf20,
    this.notes,
    GameState? gameState,
    this.underdogPlayerIdForGame, // NEW: Add to constructor
  })  : id = id ?? const Uuid().v4(),
        rounds = rounds ??
            List.generate(
              5,
              (index) => Round(
                roundNumber: index + 1,
                myScore: 0,
                opponentScore: 0,
                priorityPlayerId: null,
                myQuest1_1Completed: false,
                myQuest1_2Completed: false,
                myQuest1_3Completed: false,
                myQuest2_1Completed: false,
                myQuest2_2Completed: false,
                myQuest2_3Completed: false,
                opponentQuest1_1Completed: false,
                opponentQuest1_2Completed: false,
                opponentQuest1_3Completed: false,
                opponentQuest2_1Completed: false,
                opponentQuest2_2Completed: false,
                opponentQuest2_3Completed: false,
              ),
            ),
        gameState = gameState ?? GameState.setup;

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
    String? result,
    int? scoreOutOf20,
    String? notes,
    GameState? gameState,
    String? underdogPlayerIdForGame, // NEW: Add to copyWith
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
      opponentFactionImageUrl:
          opponentFactionImageUrl ?? this.opponentFactionImageUrl,
      opponentScore: opponentScore ?? this.opponentScore,
      opponentDrops: opponentDrops ?? this.opponentDrops,
      opponentAuxiliaryUnits:
          opponentAuxiliaryUnits ?? this.opponentAuxiliaryUnits,
      attackerPlayerId: attackerPlayerId ?? this.attackerPlayerId,
      priorityPlayerIdRound1:
          priorityPlayerIdRound1 ?? this.priorityPlayerIdRound1,
      rounds: rounds ?? this.rounds,
      result: result ?? this.result,
      scoreOutOf20: scoreOutOf20 ?? this.scoreOutOf20,
      notes: notes ?? this.notes,
      gameState: gameState ?? this.gameState,
      underdogPlayerIdForGame:
          underdogPlayerIdForGame ?? this.underdogPlayerIdForGame, // NEW: Copy underdogPlayerIdForGame
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'myPlayerName': myPlayerName,
      'myFactionName': myFactionName,
      'myFactionImageUrl': myFactionImageUrl,
      'myScore': myScore,
      'myDrops': myDrops,
      'myAuxiliaryUnits': myAuxiliaryUnits,
      'opponentPlayerName': opponentPlayerName,
      'opponentFactionName': opponentFactionName,
      'opponentFactionImageUrl': opponentFactionImageUrl,
      'opponentScore': opponentScore,
      'opponentDrops': opponentDrops,
      'opponentAuxiliaryUnits': opponentAuxiliaryUnits,
      'attackerPlayerId': attackerPlayerId,
      'priorityPlayerIdRound1': priorityPlayerIdRound1,
      'rounds': rounds.map((r) => r.toMap()).toList(),
      'result': result,
      'scoreOutOf20': scoreOutOf20,
      'notes': notes,
      'gameState': gameState.name,
      'underdogPlayerIdForGame': underdogPlayerIdForGame, // NEW: Store underdogPlayerIdForGame
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      myPlayerName: map['myPlayerName'] as String,
      myFactionName: map['myFactionName'] as String,
      myFactionImageUrl: map['myFactionImageUrl'] as String?,
      myScore: map['myScore'] as int? ?? 0,
      myDrops: map['myDrops'] as int? ?? 1,
      myAuxiliaryUnits: map['myAuxiliaryUnits'] as bool? ?? false,
      opponentPlayerName: map['opponentPlayerName'] as String,
      opponentFactionName: map['opponentFactionName'] as String,
      opponentFactionImageUrl: map['opponentFactionImageUrl'] as String?,
      opponentScore: map['opponentScore'] as int? ?? 0,
      opponentDrops: map['opponentDrops'] as int? ?? 1,
      opponentAuxiliaryUnits: map['opponentAuxiliaryUnits'] as bool? ?? false,
      attackerPlayerId: map['attackerPlayerId'] as String?,
      priorityPlayerIdRound1: map['priorityPlayerIdRound1'] as String?,
      rounds: List<Round>.from(
        (map['rounds'] as List<dynamic>?)?.map<Round>(
              (x) => Round.fromMap(x as Map<String, dynamic>),
            ).toList() ??
            List.generate(
              5,
              (index) => Round(
                roundNumber: index + 1,
                myScore: 0,
                opponentScore: 0,
                priorityPlayerId: null,
                myQuest1_1Completed: false,
                myQuest1_2Completed: false,
                myQuest1_3Completed: false,
                myQuest2_1Completed: false,
                myQuest2_2Completed: false,
                myQuest2_3Completed: false,
                opponentQuest1_1Completed: false,
                opponentQuest1_2Completed: false,
                opponentQuest1_3Completed: false,
                opponentQuest2_1Completed: false,
                opponentQuest2_2Completed: false,
                opponentQuest2_3Completed: false,
              ),
            ),
      ),
      result: map['result'] as String? ?? 'En cours',
      scoreOutOf20: map['scoreOutOf20'] as int? ?? 0,
      notes: map['notes'] as String?,
      gameState: map['gameState'] != null
          ? GameState.values.firstWhere(
              (e) => e.name == map['gameState'],
              orElse: () => GameState.setup,
            )
          : GameState.setup,
      underdogPlayerIdForGame: map['underdogPlayerIdForGame']
          as String?, // NEW: Read underdogPlayerIdForGame from map
    );
  }

  static String determineResult(int myScore, int opponentScore) {
    if (myScore > opponentScore) {
      return 'Victoire';
    } else if (myScore < opponentScore) {
      return 'Défaite';
    } else {
      return 'Égalité';
    }
  }

  static int calculateScoreOutOf20(int myScore, int opponentScore) {
    int totalScore = myScore + opponentScore;
    if (totalScore == 0) return 10;
    double myNormalizedScore = (myScore / totalScore) * 10;
    return (myNormalizedScore + 5).round();
  }
}