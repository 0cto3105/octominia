// lib/screens/add_game_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/services/game_json_storage.dart';
import 'package:octominia/screens/games/game_setup_screen.dart';
import 'package:octominia/screens/games/game_roll_offs_screen.dart';
import 'package:octominia/screens/games/game_round_screen.dart';
import 'package:octominia/screens/games/game_summary_screen.dart';
import 'package:octominia/screens/games/game_template.dart'; // Importez le nouveau template

class GamerCenterScreen extends StatefulWidget {
  final Game? initialGame;
  final Function(Game game) onGameSaved;
  final int? initialPageIndex;

  const GamerCenterScreen({
    super.key,
    this.initialGame,
    required this.onGameSaved,
    this.initialPageIndex,
  });

  @override
  State<GamerCenterScreen> createState() => _GamerCenterScreenState();
}

class _GamerCenterScreenState extends State<GamerCenterScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  late Game _newGame;
  bool _gameInitiallySaved = false;
  final GameJsonStorage _gameStorage = GameJsonStorage();

  @override
  void initState() {
    super.initState();
    print('DEBUG: initState de GamerCenterScreen appelé !');

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
        ),
      ),
      attackerPlayerId: 'me',
      priorityPlayerIdRound1: 'me',
      scoreOutOf20: 0,
      gameState: GameState.setup,
    );
    _gameInitiallySaved = widget.initialGame != null;

    int startingPageIndex = widget.initialPageIndex ?? 0;

    if (widget.initialGame != null) {
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
          scoreOutOf20: Game.calculateScoreOutOf20(_newGame.myScore, _newGame.opponentScore),
          gameState: GameState.completed, // Mark as completed
        );
      });
      _saveGame(); // Final save
      Navigator.of(context).pop(); // Exit GamerCenterScreen
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
    return GameTemplate(
      game: _newGame,
      pageController: _pageController,
      currentPageIndex: _currentPageIndex,
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      onNextPage: _nextPage,
      onPreviousPage: _previousPage,
      onReturnToList: _returnToList,
      pages: [
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
          onSave: _nextPage, // The "Finaliser la Partie" button
        ),
      ],
    );
  }
}