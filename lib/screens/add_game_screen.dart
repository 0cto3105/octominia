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
  final int? initialPageIndex;

  const AddGameScreen({
    super.key,
    this.initialGame,
    required this.onGameSaved,
    this.initialPageIndex,
  });

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  late Game _newGame;
  bool _gameInitiallySaved = false;
  final GameJsonStorage _gameStorage = GameJsonStorage();

 @override
  void initState() {
    super.initState();
    // =========================================================================
    // >>> SEULEMENT CETTE LIGNE DOIT ÊTRE PRÉSENTE AU DÉBUT DE INITSTATE <<<
    print('DEBUG: initState de AddGameScreen appelé !');
    // =========================================================================

    _newGame = widget.initialGame ?? Game(
      id: const Uuid().v4(),
      date: DateTime.now(),
      myPlayerName: 'Moi',
      myFactionName: '',
      opponentPlayerName: 'Adversaire',
      opponentFactionName: '',
      myScore: 0,
      opponentScore: 0,
      myDrops: 1,
      opponentDrops: 1,
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
      gameState: GameState.setup,
    );
    _gameInitiallySaved = widget.initialGame != null;

    int startingPageIndex = widget.initialPageIndex ?? 0;

    if (widget.initialGame != null) {
      // Si cette ligne ci-dessous n'apparaît pas, c'est que le widget.initialGame est null,
      // ce qui signifie que vous ouvrez peut-être une nouvelle partie et non une partie existante.
      print('DEBUG: initialGame n\'est PAS null. GameState: ${_newGame.gameState}, Résultat: ${_newGame.result}');

      switch (_newGame.gameState) {
        case GameState.setup:
          startingPageIndex = 0;
          break;
        case GameState.rollOffs:
          startingPageIndex = 1;
          break;
        case GameState.round1:
          startingPageIndex = 2;
          break;
        case GameState.round2:
          startingPageIndex = 3;
          break;
        case GameState.round3:
          startingPageIndex = 4;
          break;
        case GameState.round4:
          startingPageIndex = 5;
          break;
        case GameState.round5:
          startingPageIndex = 6;
          break;
        case GameState.summary:
          startingPageIndex = 6; // Retourne au Tour 5 pour permettre l'édition
          break;
        case GameState.completed:
          startingPageIndex = 7;
          break;
        default:
          startingPageIndex = 0;
          break;
      }
    } else {
      print('DEBUG: initialGame est null. C\'est une nouvelle partie.');
    }


    _currentPageIndex = startingPageIndex;
    _pageController = PageController(initialPage: _currentPageIndex);
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateGameData(Game updatedGame) {
    setState(() {
      _newGame = updatedGame;
      // Recalcul des scores totaux du jeu après chaque mise à jour de données
      int myTotalScore = 0;
      int opponentTotalScore = 0;
      for (var round in _newGame.rounds) {
        myTotalScore += round.calculatePlayerTotalScore(true);
        opponentTotalScore += round.calculatePlayerTotalScore(false);
      }
      _newGame = _newGame.copyWith(
        myScore: myTotalScore,
        opponentScore: opponentTotalScore,
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
        // Recalcul des scores totaux du jeu après chaque mise à jour de round
        int myTotalScore = 0;
        int opponentTotalScore = 0;
        for (var round in _newGame.rounds) {
          myTotalScore += round.calculatePlayerTotalScore(true);
          opponentTotalScore += round.calculatePlayerTotalScore(false);
        }
        _newGame = _newGame.copyWith(
          myScore: myTotalScore,
          opponentScore: opponentTotalScore,
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
      } else {
        await _gameStorage.updateGame(_newGame);
      }
      widget.onGameSaved(_newGame);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de sauvegarde: $e')),
      );
    }
  }

  void _nextPage() {
    // Validation for GameSetupScreen (page 0)
    if (_currentPageIndex == 0) {
      if (_newGame.myFactionName.isEmpty || _newGame.opponentFactionName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner les factions pour les deux joueurs.')),
        );
        return;
      }
      // No change to gameState here, it remains GameState.setup until roll-offs
    }

    // Validation for GameRollOffsScreen (page 1)
    if (_currentPageIndex == 1) {
      if (_newGame.attackerPlayerId == null || _newGame.priorityPlayerIdRound1 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez définir l\'attaquant et la priorité du Tour 1.')),
        );
        return;
      }
      if (!_gameInitiallySaved) {
        _saveGame(); // Save after initial setup and roll-offs are complete
      }
      // GameState is updated below in the general case, after incrementing _currentPageIndex
    }

    if (_currentPageIndex < 7) { // If not on the last page (Summary - index 7)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentPageIndex++;
        // Update gameState based on the new currentPageIndex
        switch (_currentPageIndex) {
          case 2: _newGame = _newGame.copyWith(gameState: GameState.round1); break;
          case 3: _newGame = _newGame.copyWith(gameState: GameState.round2); break;
          case 4: _newGame = _newGame.copyWith(gameState: GameState.round3); break;
          case 5: _newGame = _newGame.copyWith(gameState: GameState.round4); break;
          case 6: _newGame = _newGame.copyWith(gameState: GameState.round5); break;
          case 7: _newGame = _newGame.copyWith(gameState: GameState.summary); break; // Reached summary screen
        }
      });
    } else if (_currentPageIndex == 7) {
      // On the summary screen, the "Finaliser la Partie" button (which is _nextPage)
      setState(() {
        _newGame = _newGame.copyWith(
          result: Game.determineResult(_newGame.myScore, _newGame.opponentScore),
          scoreOutOf20: Game.calculateScoreOutOf20(_newGame.myScore, _newGame.opponentScore),
          gameState: GameState.completed, // Mark as completed
        );
      });
      _saveGame(); // Final save
      Navigator.of(context).pop(); // Exit AddGameScreen
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
        // Update gameState based on the new currentPageIndex
        switch (_currentPageIndex) {
          case 0: _newGame = _newGame.copyWith(gameState: GameState.setup); break;
          case 1: _newGame = _newGame.copyWith(gameState: GameState.rollOffs); break;
          case 2: _newGame = _newGame.copyWith(gameState: GameState.round1); break;
          case 3: _newGame = _newGame.copyWith(gameState: GameState.round2); break;
          case 4: _newGame = _newGame.copyWith(gameState: GameState.round3); break;
          case 5: _newGame = _newGame.copyWith(gameState: GameState.round4); break;
          case 6: _newGame = _newGame.copyWith(gameState: GameState.round5); break;
          // If going back from summary, it should land on Round 5
          // case 7: _newGame = _newGame.copyWith(gameState: GameState.summary); break; // This case is not reachable by _previousPage to index 7
        }
      });
    } else {
      // If on the first page and pressing back, pop the screen
      Navigator.of(context).pop();
    }
  }

  void _returnToList() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    // Get trigrams for score display in AppBar
    String myTrigram = _newGame.myPlayerName.length >= 3 ? _newGame.myPlayerName.substring(0, 3).toUpperCase() : _newGame.myPlayerName.toUpperCase();
    String opponentTrigram = _newGame.opponentPlayerName.length >= 3 ? _newGame.opponentPlayerName.substring(0, 3).toUpperCase() : _newGame.opponentPlayerName.toUpperCase();

    // Determine the title based on the current page, or the score if it's a round page
    if (_currentPageIndex >= 2 && _currentPageIndex <= 6) { // Rounds 1 to 5
      appBarTitle = '$myTrigram ${_newGame.myScore} - $opponentTrigram ${_newGame.opponentScore}';
    } else {
      switch (_currentPageIndex) {
        case 0:
          appBarTitle = 'Configuration de la Partie';
          break;
        case 1:
          appBarTitle = 'Jet de Dés & Priorité';
          break;
        case 7:
          appBarTitle = 'Résumé de la Partie';
          break;
        default:
          appBarTitle = 'Partie';
          break;
      }
    }


    return PopScope(
      canPop: _currentPageIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentPageIndex > 0) {
          _previousPage();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          backgroundColor: Colors.redAccent, // <-- L'en-tête rouge
          centerTitle: true, // Centrer le titre/score
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Retour à la liste des parties',
              onPressed: _returnToList,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swiping
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
                  GameRoundScreen(
                    game: _newGame,
                    roundNumber: 4,
                    onUpdateRound: _updateRoundData,
                  ),
                  GameRoundScreen(
                    game: _newGame,
                    roundNumber: 5,
                    onUpdateRound: _updateRoundData,
                  ),
                  GameSummaryScreen(
                    game: _newGame,
                    onSave: _nextPage, // This will now trigger the 'Finaliser la Partie' logic
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _previousPage,
                      style: ElevatedButton.styleFrom( // <-- Style pour le bouton "Précédent"
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Précédent'),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom( // <-- Style pour le bouton "Suivant" / "Finaliser la Partie"
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_currentPageIndex == 7 ? 'Finaliser la Partie' : 'Suivant'), // Updated button text for summary screen
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}