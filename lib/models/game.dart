// lib/models/game.dart

import 'package:octominia/models/round.dart';
import 'package:uuid/uuid.dart'; // Add this import

class Game {
  String id; // Added ID field
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

  Game({
    String? id, // Make id optional in constructor, will generate if null
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
    required this.rounds,
    required this.result,
    required this.scoreOutOf20,
    this.notes,
  }) : this.id = id ?? const Uuid().v4(); // Generate a new UUID if id is not provided

  static String determineResult(int myTotalScore, int opponentTotalScore) {
    if (myTotalScore > opponentTotalScore) {
      return 'Victoire';
    } else if (opponentTotalScore > myTotalScore) {
      return 'Défaite';
    } else {
      return 'Égalité';
    }
  }

  static int calculateScoreOutOf20(int myTotalScore, int opponentTotalScore) {
    int scoreDifference = myTotalScore - opponentTotalScore;
    if (scoreDifference > 0) {
      return 10 + (scoreDifference ~/ 2).clamp(0, 10);
    } else if (scoreDifference < 0) {
      return 10 + (scoreDifference ~/ 2).clamp(-10, 0);
    } else {
      return 10;
    }
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
    String? result,
    int? scoreOutOf20,
    String? notes,
  }) {
    return Game(
      id: id ?? this.id, // Copy ID as well
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
      rounds: rounds ?? this.rounds,
      result: result ?? this.result,
      scoreOutOf20: scoreOutOf20 ?? this.scoreOutOf20,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include ID in map
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
      'rounds': rounds.map((x) => x.toMap()).toList(),
      'result': result,
      'scoreOutOf20': scoreOutOf20,
      'notes': notes,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String?, // Read ID, can be null for old data
      date: DateTime.parse(map['date'] as String),
      myPlayerName: map['myPlayerName'] as String,
      myFactionName: map['myFactionName'] as String,
      myFactionImageUrl: map['myFactionImageUrl'] as String?,
      myScore: map['myScore'] as int? ?? 0, // Default to 0 for robustness
      myDrops: map['myDrops'] as int? ?? 1,
      myAuxiliaryUnits: map['myAuxiliaryUnits'] as bool? ?? false,
      opponentPlayerName: map['opponentPlayerName'] as String,
      opponentFactionName: map['opponentFactionName'] as String,
      opponentFactionImageUrl: map['opponentFactionImageUrl'] as String?,
      opponentScore: map['opponentScore'] as int? ?? 0, // Default to 0 for robustness
      opponentDrops: map['opponentDrops'] as int? ?? 1,
      opponentAuxiliaryUnits: map['opponentAuxiliaryUnits'] as bool? ?? false,
      attackerPlayerId: map['attackerPlayerId'] as String?,
      priorityPlayerIdRound1: map['priorityPlayerIdRound1'] as String?,
       rounds: List<Round>.from(
        (map['rounds'] as List<dynamic>?)?.map<Round>(
          (x) => Round.fromMap(x as Map<String, dynamic>),
        ) ?? List.generate(3, (index) => Round(
            roundNumber: index + 1,
            myScore: 0,
            opponentScore: 0,
            priorityPlayerId: null,
            // Assurez-vous que l'initialisation ici est aussi complète que dans Round()
            myQuest1_1Completed: false, // Ajouté
            myQuest1_2Completed: false, // Ajouté
            myQuest1_3Completed: false, // Ajouté
            myQuest2_1Completed: false, // Ajouté
            myQuest2_2Completed: false, // Ajouté
            myQuest2_3Completed: false, // Ajouté
            opponentQuest1_1Completed: false, // Ajouté
            opponentQuest1_2Completed: false, // Ajouté
            opponentQuest1_3Completed: false, // Ajouté
            opponentQuest2_1Completed: false, // Ajouté
            opponentQuest2_2Completed: false, // Ajouté
            opponentQuest2_3Completed: false, // Ajouté
          )),),
      result: map['result'] as String? ?? 'Inconnu', // Default for result
      scoreOutOf20: map['scoreOutOf20'] as int? ?? 10, // Default for score
      notes: map['notes'] as String?,
    );
  }
}