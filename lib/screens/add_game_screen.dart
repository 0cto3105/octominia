// lib/screens/add_game_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/services/game_json_storage.dart';
import 'package:octominia/screens/game_setup_screen.dart';
import 'package:octominia/screens/game_roll_offs_screen.dart';
import 'package:octominia/screens/game_round_screen.dart';
import 'package:octominia/screens/game_summary_screen.dart';

class AddGameScreen extends StatefulWidget {
  final Game? initialGame;
  final Function(Game game) onGameSaved;

  const AddGameScreen({
    super.key,
    this.initialGame,
    required this.onGameSaved,
  });

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late Game _newGame;
  bool _gameInitiallySaved = false;
  final GameJsonStorage _gameStorage = GameJsonStorage();

  @override
  void initState() {
    super.initState();
    _newGame = widget.initialGame ?? Game(
      id: const Uuid().v4(),
      date: DateTime.now(),
      myPlayerName: 'Moi',
      myFactionName: '',
      opponentPlayerName: 'Adversaire',
      opponentFactionName: '',
      myScore: 0,
      opponentScore: 0,
      myDrops: 1, // Initialisation à 1 (entre 1 et 5)
      opponentDrops: 1, // Initialisation à 1 (entre 1 et 5)
      myAuxiliaryUnits: false,
      opponentAuxiliaryUnits: false,
      rounds: List.generate(
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
      result: 'En cours',
      scoreOutOf20: 0,
    );
    _gameInitiallySaved = widget.initialGame != null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateGameData(Game updatedGame) {
    setState(() {
      _newGame = updatedGame;
      int myTotalScore = 0;
      int opponentTotalScore = 0;
      for (var round in _newGame.rounds) {
        myTotalScore += round.calculatePlayerTotalScore(true);
        opponentTotalScore += round.calculatePlayerTotalScore(false);
      }
      _newGame = _newGame.copyWith(
        myScore: myTotalScore,
        opponentScore: opponentTotalScore,
        result: Game.determineResult(myTotalScore, opponentTotalScore),
        scoreOutOf20: Game.calculateScoreOutOf20(myTotalScore, opponentTotalScore),
      );
    });
    if (_gameInitiallySaved) {
      _saveGame();
    }
  }

  void _updateRoundData(Round updatedRound) {
    setState(() {
      final updatedRounds = List<Round>.from(_newGame.rounds);
      final index = updatedRounds.indexWhere((r) => r.roundNumber == updatedRound.roundNumber);
      if (index != -1) {
        updatedRounds[index] = updatedRound;
        _newGame = _newGame.copyWith(rounds: updatedRounds);
        int myTotalScore = 0;
        int opponentTotalScore = 0;
        for (var round in _newGame.rounds) {
          myTotalScore += round.calculatePlayerTotalScore(true);
          opponentTotalScore += round.calculatePlayerTotalScore(false);
        }
        _newGame = _newGame.copyWith(
          myScore: myTotalScore,
          opponentScore: opponentTotalScore,
          result: Game.determineResult(myTotalScore, opponentTotalScore),
          scoreOutOf20: Game.calculateScoreOutOf20(myTotalScore, opponentTotalScore),
        );
      }
    });
    if (_gameInitiallySaved) {
      _saveGame();
    }
  }

  Future<void> _saveGame() async {
    try {
      if (!_gameInitiallySaved) {
        await _gameStorage.addGame(_newGame);
        setState(() {
          _gameInitiallySaved = true;
        });
        // Suppression du feedback visuel
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Partie initialisée et sauvegardée !')),
        // );
      } else {
        await _gameStorage.updateGame(_newGame);
        // Suppression du feedback visuel
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Partie mise à jour !')),
        // );
      }
      widget.onGameSaved(_newGame);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de sauvegarde: $e')),
      );
    }
  }

  void _nextPage() {
    if (_currentPageIndex == 0) {
      if (_newGame.myFactionName.isEmpty || _newGame.opponentFactionName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner les factions pour les deux joueurs.')),
        );
        return;
      }
    }

    if (_currentPageIndex == 1) {
      if (_newGame.attackerPlayerId == null || _newGame.priorityPlayerIdRound1 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez définir l\'attaquant et la priorité du Tour 1.')),
        );
        return;
      }
      if (!_gameInitiallySaved) {
        _saveGame();
      }
    }

    if (_currentPageIndex < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentPageIndex++;
      });
    } else if (_currentPageIndex == 5) {
      // Sur l'écran de résumé, le bouton de sauvegarde gère la sauvegarde finale.
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentPageIndex--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    switch (_currentPageIndex) {
      case 0:
        appBarTitle = 'Configuration de la Partie';
        break;
      case 1:
        appBarTitle = 'Jet de Dés & Priorité';
        break;
      case 2:
        appBarTitle = 'Tour 1';
        break;
      case 3:
        appBarTitle = 'Tour 2';
        break;
      case 4:
        appBarTitle = 'Tour 3';
        break;
      case 5:
        appBarTitle = 'Résumé de la Partie';
        break;
      default:
        appBarTitle = 'Partie'; // Fallback
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                GameSetupScreen(
                  game: _newGame,
                  onUpdate: _updateGameData,
                ),
                GameRollOffsScreen(
                  game: _newGame,
                  onUpdate: _updateGameData,
                ),
                GameRoundScreen(
                  game: _newGame,
                  roundNumber: 1,
                  onUpdateRound: _updateRoundData,
                ),
                GameRoundScreen(
                  game: _newGame,
                  roundNumber: 2,
                  onUpdateRound: _updateRoundData,
                ),
                GameRoundScreen(
                  game: _newGame,
                  roundNumber: 3,
                  onUpdateRound: _updateRoundData,
                ),
                GameSummaryScreen(
                  game: _newGame,
                  onSave: _saveGame,
                ),
              ],
            ),
          ),
          // Les boutons seront désormais en bas, à l'intérieur d'un SafeArea
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _previousPage,
                    child: const Text('Précédent'),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPageIndex == 5 ? 'Terminer' : 'Suivant'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}