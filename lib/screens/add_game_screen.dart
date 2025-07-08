// lib/screens/add_game_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/services/game_json_storage.dart';
import 'package:octominia/screens/game_setup_screen.dart';
import 'package:octominia/screens/game_roll_offs_screen.dart';
import 'package:octominia/screens/game_round_screen.dart';
import 'package:octominia/screens/game_summary_screen.dart';

class AddGameScreen extends StatefulWidget {
  final Function() onGameAdded;

  const AddGameScreen({super.key, required this.onGameAdded});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late Game _newGame;

  final GameJsonStorage _gameStorage = GameJsonStorage();

  @override
  void initState() {
    super.initState();
    _newGame = Game(
      date: DateTime.now(),
      myPlayerName: 'Moi',
      myFactionName: '',
      opponentPlayerName: 'Adversaire',
      opponentFactionName: '',
      myScore: 0,
      opponentScore: 0,
      result: '',
      scoreOutOf20: 0,
      myDrops: 1,
      myAuxiliaryUnits: false,
      opponentDrops: 1,
      opponentAuxiliaryUnits: false,
      rounds: List.generate(3, (index) => Round(
        roundNumber: index + 1,
        myScore: 0,
        opponentScore: 0,
        priorityPlayerId: null,
        // Initialisation de TOUTES les nouvelles quêtes à false
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
      )),
      notes: null,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateGameData(Function(Game) updateFn) {
    setState(() {
      updateFn(_newGame);
      // Recalculate myScore and opponentScore based on the new Round calculation method
      _newGame.myScore = _newGame.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(true));
      _newGame.opponentScore = _newGame.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(false));
      _newGame.result = Game.determineResult(_newGame.myScore, _newGame.opponentScore);
      _newGame.scoreOutOf20 = Game.calculateScoreOutOf20(_newGame.myScore, _newGame.opponentScore);
    });
  }

  void _nextPage() {
    if (_currentPageIndex == 0) { // GameSetupScreen
      if (_newGame.myFactionName.isEmpty || _newGame.opponentFactionName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner les factions pour les deux joueurs.')),
        );
        return;
      }
    }
    if (_currentPageIndex == 1) { // GameRollOffsScreen
      if (_newGame.attackerPlayerId == null || _newGame.priorityPlayerIdRound1 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner l\'attaquant et la priorité pour le Tour 1.')),
        );
        return;
      }
    }
    // Validation for Round Screens (index 2, 3, 4)
    if (_currentPageIndex >= 2 && _currentPageIndex <= 4) {
      // Calculer le numéro de tour réel
      final int actualRoundNumber = _currentPageIndex - 1; // Tour 1 pour index 2, Tour 2 pour index 3, etc.
      // Assurez-vous que le round existe (devrait être le cas avec l'initialisation dans initState)
      if (_newGame.rounds.length < actualRoundNumber) {
          // This case should ideally not happen if Game constructor initializes 3 rounds,
          // but if it ever does, add a new round to prevent index out of bounds.
          // Note: The roundNumber here should be actualRoundNumber, not _currentPageIndex - 1 if _newGame.rounds[index] is used later.
          // Let's ensure consistency.
          _newGame.rounds.add(Round(roundNumber: actualRoundNumber, myScore: 0, opponentScore: 0, priorityPlayerId: null));
      }
      // Utiliser l'index correct pour accéder au round dans la liste
      final currentRound = _newGame.rounds[actualRoundNumber -1 ]; // List is 0-indexed, roundNumber is 1-indexed

      if (currentRound.priorityPlayerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Utiliser actualRoundNumber pour le message
          SnackBar(content: Text('Veuillez sélectionner la priorité pour le Tour $actualRoundNumber.')),
        );
        return;
      }
    }

    if (_currentPageIndex < _buildPages().length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveGame() async {
    // Recalculate final scores before saving
    _newGame.myScore = _newGame.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(true));
    _newGame.opponentScore = _newGame.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(false));
    _newGame.result = Game.determineResult(_newGame.myScore, _newGame.opponentScore);
    _newGame.scoreOutOf20 = Game.calculateScoreOutOf20(_newGame.myScore, _newGame.opponentScore);

    await _gameStorage.addGame(_newGame);
    widget.onGameAdded();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<Widget> _buildPages() {
    return [
      GameSetupScreen(
        game: _newGame,
        onUpdate: (updatedGame) => _updateGameData((game) {
          game.myPlayerName = updatedGame.myPlayerName;
          game.myFactionName = updatedGame.myFactionName;
          game.myFactionImageUrl = updatedGame.myFactionImageUrl;
          game.myDrops = updatedGame.myDrops;
          game.myAuxiliaryUnits = updatedGame.myAuxiliaryUnits;
          game.opponentPlayerName = updatedGame.opponentPlayerName;
          game.opponentFactionName = updatedGame.opponentFactionName;
          game.opponentFactionImageUrl = updatedGame.opponentFactionImageUrl;
          game.opponentDrops = updatedGame.opponentDrops;
          game.opponentAuxiliaryUnits = updatedGame.opponentAuxiliaryUnits;
        }),
      ),
      GameRollOffsScreen(
        game: _newGame,
        onUpdate: (updatedGame) => _updateGameData((game) {
          game.attackerPlayerId = updatedGame.attackerPlayerId;
          game.priorityPlayerIdRound1 = updatedGame.priorityPlayerIdRound1;
        }),
      ),
      GameRoundScreen(
        roundNumber: 1,
        game: _newGame,
        onUpdateRound: (updatedRound) => _updateGameData((game) {
          final index = game.rounds.indexWhere((r) => r.roundNumber == updatedRound.roundNumber);
          if (index != -1) {
            game.rounds[index] = updatedRound;
          } else {
            game.rounds.add(updatedRound);
            game.rounds.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
          }
        }),
      ),
      GameRoundScreen(
        roundNumber: 2,
        game: _newGame,
        onUpdateRound: (updatedRound) => _updateGameData((game) {
          final index = game.rounds.indexWhere((r) => r.roundNumber == updatedRound.roundNumber);
          if (index != -1) {
            game.rounds[index] = updatedRound;
          } else {
            game.rounds.add(updatedRound);
            game.rounds.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
          }
        }),
      ),
      GameRoundScreen(
        roundNumber: 3,
        game: _newGame,
        onUpdateRound: (updatedRound) => _updateGameData((game) {
          final index = game.rounds.indexWhere((r) => r.roundNumber == updatedRound.roundNumber);
          if (index != -1) {
            game.rounds[index] = updatedRound;
          } else {
            game.rounds.add(updatedRound);
            game.rounds.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
          }
        }),
      ),
      GameSummaryScreen(
        game: _newGame,
        onSave: _saveGame,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPageIndex == _buildPages().length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPageIndex == 0
              ? 'Nouvelle Partie'
              : _currentPageIndex == 1
                  ? 'Roll Offs & Priorité'
                  : _currentPageIndex >= 2 && _currentPageIndex <= 4
                      ? 'Tour ${_currentPageIndex - 1}'
                      : 'Résumé de la Partie',
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
              children: _buildPages(),
            ),
          ),
          if (!isLastPage)
            SafeArea(
              bottom: true,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).appBarTheme.backgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPageIndex == 0 ? null : _previousPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        minimumSize: const Size(60, 48),
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        minimumSize: const Size(60, 48),
                      ),
                      child: const Icon(Icons.arrow_forward),
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