// lib/screens/game_round_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/models/quest.dart';
import 'package:octominia/widgets/round/player_score_card.dart';
import 'package:octominia/widgets/round/primary_score_slider.dart';
import 'package:octominia/widgets/round/quest_section.dart';
import 'package:octominia/widgets/round/quest_checkbox.dart';


class GameRoundScreen extends StatefulWidget {
  final int roundNumber;
  final Game game;
  final Function(Round) onUpdateRound;

  const GameRoundScreen({
    super.key,
    required this.roundNumber,
    required this.game,
    required this.onUpdateRound,
  });

  @override
  State<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen> {
  late Round _currentRound;
  late String _myPlayerName;
  late String _opponentPlayerName;

  @override
  void initState() {
    super.initState();
    _myPlayerName = widget.game.myPlayerName;
    _opponentPlayerName = widget.game.opponentPlayerName;

    // Retrieve the current round.
    // Ensure it exists and has quests properly initialized.
    _currentRound = widget.game.rounds.firstWhere(
      (round) => round.roundNumber == widget.roundNumber,
      // If for some reason a round doesn't exist, create a new one with initial quests.
      // This fallback is crucial for robustness if 'game.rounds' was not perfectly populated.
      orElse: () => Round(
        roundNumber: widget.roundNumber,
        myScore: 0,
        opponentScore: 0,
        myQuestsSuite1: Round.createInitialQuests(isMyPlayer: true, suiteNumber: 1),
        myQuestsSuite2: Round.createInitialQuests(isMyPlayer: true, suiteNumber: 2),
        opponentQuestsSuite1: Round.createInitialQuests(isMyPlayer: false, suiteNumber: 1),
        opponentQuestsSuite2: Round.createInitialQuests(isMyPlayer: false, suiteNumber: 2),
        myQuestSuite1CompletedThisRound: false,
        myQuestSuite2CompletedThisRound: false,
        opponentQuestSuite1CompletedThisRound: false,
        opponentQuestSuite2CompletedThisRound: false,
      ),
    );

    // DÉFINIR 'me' COMME PRIORITÉ PAR DÉFAUT SI NULL (et mettre à jour localement)
    if (_currentRound.priorityPlayerId == null) {
      _currentRound = _currentRound.copyWith(priorityPlayerId: 'me');
    }

    // DÉFINIR 'me' COMME JET D'INITIATIVE PAR DÉFAUT SI NULL (et mettre à jour localement)
    if (_currentRound.initiativePlayerId == null) {
      _currentRound = _currentRound.copyWith(initiativePlayerId: 'me');
    }

    // Always recalculate flags in initState to ensure consistency upon screen load
    // This will correctly update myPlayerHadDoubleFreeTurn, opponentPlayerHadDoubleFreeTurn,
    // and underdogPlayerIdAtEndOfRound for the *current* round based on *previous* rounds' states.
    _recalculateUnderdogAndDoubleTurnFlags();

    // Now, _currentRound is ready. If any copyWith happened above, it's already updated.
    // No need to call _updateRoundLocally here unless you want to persist these initial defaults immediately.
    // Generally, initial defaults are part of the 'new game' creation logic or fromJson.
  }

  void _updateRoundLocally(Round updatedRound) {
    setState(() {
      _currentRound = updatedRound;
    });
    // Appeler la fonction de mise à jour du parent pour persister le round
    widget.onUpdateRound(_currentRound);
  }

  void _updatePriority(String? playerKey) {
    String? previousRoundPriorityPlayerId;
    if (widget.roundNumber > 1) {
      final previousRound = widget.game.rounds.firstWhere(
            (round) => round.roundNumber == widget.roundNumber - 1,
        orElse: () => Round( // Fallback if previous round not found, shouldn't happen
            roundNumber: 0, myScore: 0, opponentScore: 0,
            myQuestsSuite1: [], myQuestsSuite2: [], opponentQuestsSuite1: [], opponentQuestsSuite2: [],
            myQuestSuite1CompletedThisRound: false, myQuestSuite2CompletedThisRound: false,
            opponentQuestSuite1CompletedThisRound: false, opponentQuestSuite2CompletedThisRound: false,
        ),
      );
      previousRoundPriorityPlayerId = previousRound.priorityPlayerId;
    }

    String? playerWhoWasSecondLastRound;
    if (previousRoundPriorityPlayerId != null) {
      if (previousRoundPriorityPlayerId == 'me') {
        playerWhoWasSecondLastRound = 'opponent';
      } else {
        playerWhoWasSecondLastRound = 'me';
      }
    }

    // Update priority and then recalculate everything
    _currentRound = _currentRound.copyWith(priorityPlayerId: playerKey);
    _recalculateUnderdogAndDoubleTurnFlags(); // This will use the new priorityPlayerId
    _updateRoundLocally(_currentRound); // Persist the updated round
  }

  void _updateInitiative(String? playerKey) {
    // Update initiative and then recalculate everything
    _currentRound = _currentRound.copyWith(initiativePlayerId: playerKey);
    _recalculateUnderdogAndDoubleTurnFlags(); // This will use the new initiativePlayerId
    _updateRoundLocally(_currentRound); // Persist the updated round
  }

  void _recalculateUnderdogAndDoubleTurnFlags() {
    // Note: This method is now called whenever initiative, priority, or primary score changes.
    // It should ONLY update the flags for _currentRound, not re-assign _currentRound itself.
    // The `_currentRound = _currentRound.copyWith(...)` is outside this method in _updatePriority, _updateInitiative, _updatePrimaryScore.

    int myTotalScorePreviousRounds = 0;
    int opponentTotalScorePreviousRounds = 0;

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myTotalScorePreviousRounds += round.calculatePlayerTotalScore(true);
        opponentTotalScorePreviousRounds += round.calculatePlayerTotalScore(false);
      }
    }

    // Determine if Double Free Turn is available based on previous rounds' scores
    int scoreDifferencePreviousRounds = (myTotalScorePreviousRounds - opponentTotalScorePreviousRounds).abs();
    bool myPlayerMightHaveDoubleFreeTurnOpportunity = (myTotalScorePreviousRounds < opponentTotalScorePreviousRounds) && (scoreDifferencePreviousRounds >= 11);
    bool opponentPlayerMightHaveDoubleFreeTurnOpportunity = (opponentTotalScorePreviousRounds < myTotalScorePreviousRounds) && (scoreDifferencePreviousRounds >= 11);

    // Update these flags on _currentRound
    _currentRound = _currentRound.copyWith(
      myPlayerHadDoubleFreeTurn: myPlayerMightHaveDoubleFreeTurnOpportunity,
      opponentPlayerHadDoubleFreeTurn: opponentPlayerMightHaveDoubleFreeTurnOpportunity,
    );

    // Get previous round's priority to determine who was "second"
    String? playerWhoWasSecondLastRound;
    if (widget.roundNumber > 1) {
      final previousRound = widget.game.rounds.firstWhere(
            (round) => round.roundNumber == widget.roundNumber - 1,
        orElse: () => Round( // Fallback
            roundNumber: 0, myScore: 0, opponentScore: 0,
            myQuestsSuite1: [], myQuestsSuite2: [], opponentQuestsSuite1: [], opponentQuestsSuite2: [],
            myQuestSuite1CompletedThisRound: false, myQuestSuite2CompletedThisRound: false,
            opponentQuestSuite1CompletedThisRound: false, opponentQuestSuite2CompletedThisRound: false,
        ),
      );
      if (previousRound.priorityPlayerId != null) {
        playerWhoWasSecondLastRound = (previousRound.priorityPlayerId == 'me') ? 'opponent' : 'me';
      }
    }

    bool isDoubleTurnTriggered = false;
    if (_currentRound.initiativePlayerId != null &&
        _currentRound.priorityPlayerId != null &&
        playerWhoWasSecondLastRound != null &&
        _currentRound.initiativePlayerId == playerWhoWasSecondLastRound &&
        _currentRound.priorityPlayerId == playerWhoWasSecondLastRound) {
      isDoubleTurnTriggered = true;
    }

    bool isCurrentPlayerDoubleFreeTurn = ((_currentRound.priorityPlayerId == 'me' && _currentRound.myPlayerHadDoubleFreeTurn) ||
        (_currentRound.priorityPlayerId == 'opponent' && _currentRound.opponentPlayerHadDoubleFreeTurn));

    String? newUnderdogPlayerIdAtEndOfRound;
    bool newMyPlayerDidNonFreeDoubleTurn = false;
    bool newOpponentPlayerDidNonFreeDoubleTurn = false;

    // Check for persistent underdog from *any* previous round via non-free double turn
    String? actualUnderdogPlayerIdAcrossAllPreviousRounds;
    if (widget.roundNumber > 1) {
      for (var round in widget.game.rounds) {
        if (round.roundNumber < widget.roundNumber && round.underdogPlayerIdAtEndOfRound != null) {
          actualUnderdogPlayerIdAcrossAllPreviousRounds = round.underdogPlayerIdAtEndOfRound;
          // Break here if you want the *earliest* non-free double turn to set the underdog
          // Or continue to find the *latest* one. Given the rules, the earliest one sets it permanently.
          break;
        }
      }
    }

    // Now, determine the state for the current round
    if (isDoubleTurnTriggered) {
      if (!isCurrentPlayerDoubleFreeTurn) {
        // C'est un double tour NON gratuit : l'adversaire devient l'underdog pour le reste de la partie
        newMyPlayerDidNonFreeDoubleTurn = (_currentRound.priorityPlayerId == 'me');
        newOpponentPlayerDidNonFreeDoubleTurn = (_currentRound.priorityPlayerId == 'opponent');
        newUnderdogPlayerIdAtEndOfRound = (_currentRound.priorityPlayerId == 'me') ? 'opponent' : 'me';
      } else {
        // C'est un double tour GRATUIT : l'underdog est déterminé dynamiquement par les scores actuels
        // ou persiste si déjà défini par un double tour non gratuit passé.
        newMyPlayerDidNonFreeDoubleTurn = false;
        newOpponentPlayerDidNonFreeDoubleTurn = false;
        newUnderdogPlayerIdAtEndOfRound = actualUnderdogPlayerIdAcrossAllPreviousRounds ?? _calculateUnderdogBasedOnCurrentScores();
      }
    } else {
      // Ce n'est PAS un double tour : l'underdog est déterminé dynamiquement par les scores actuels
      // ou persiste si déjà défini par un double tour non gratuit passé.
      newMyPlayerDidNonFreeDoubleTurn = false;
      newOpponentPlayerDidNonFreeDoubleTurn = false;
      newUnderdogPlayerIdAtEndOfRound = actualUnderdogPlayerIdAcrossAllPreviousRounds ?? _calculateUnderdogBasedOnCurrentScores();
    }

    // Update _currentRound with the new flags
    _currentRound = _currentRound.copyWith(
      myPlayerDidNonFreeDoubleTurn: newMyPlayerDidNonFreeDoubleTurn,
      opponentPlayerDidNonFreeDoubleTurn: newOpponentPlayerDidNonFreeDoubleTurn,
      underdogPlayerIdAtEndOfRound: newUnderdogPlayerIdAtEndOfRound,
    );

    // Call setState to rebuild the UI with the updated _currentRound values
    // This setState is inside this helper because this helper is called from multiple places
    // and should trigger a UI update to reflect the new flags.
    setState(() {});
  }


  // New helper method to calculate underdog based on current (including this round's primary) scores
  String? _calculateUnderdogBasedOnCurrentScores() {
    int myCurrentTotalScore = _currentRound.myScore;
    int opponentCurrentTotalScore = _currentRound.opponentScore;

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myCurrentTotalScore += round.calculatePlayerTotalScore(true);
        opponentCurrentTotalScore += round.calculatePlayerTotalScore(false);
      }
    }
    int scoreDifferenceCurrent = (myCurrentTotalScore - opponentCurrentTotalScore).abs();
    if (myCurrentTotalScore < opponentCurrentTotalScore && scoreDifferenceCurrent >= 11) {
      return 'me';
    } else if (opponentCurrentTotalScore < myCurrentTotalScore && scoreDifferenceCurrent >= 11) {
      return 'opponent';
    }
    return null;
  }


  void _updatePrimaryScore(int newScore, bool isMyPlayer) {
    setState(() {
      _currentRound = isMyPlayer
          ? _currentRound.copyWith(myScore: newScore)
          : _currentRound.copyWith(opponentScore: newScore);
      _recalculateUnderdogAndDoubleTurnFlags(); // Recalculate based on new primary score
    });
    widget.onUpdateRound(_currentRound);
  }

  // Helper method to get the correct quest list based on player and suite
  List<Quest> _getQuestSuite(bool isMyPlayer, int suiteIndex) {
    if (isMyPlayer) {
      return (suiteIndex == 1) ? _currentRound.myQuestsSuite1 : _currentRound.myQuestsSuite2;
    } else {
      return (suiteIndex == 1) ? _currentRound.opponentQuestsSuite1 : _currentRound.opponentQuestsSuite2;
    }
  }

  // Helper method to get the index of a quest within its suite based on its key
  int _getQuestIndexFromKey(String questKey) {
    if (questKey.endsWith('1_1Completed') || questKey.endsWith('2_1Completed')) {
      return 0;
    } else if (questKey.endsWith('1_2Completed') || questKey.endsWith('2_2Completed')) {
      return 1;
    } else if (questKey.endsWith('1_3Completed') || questKey.endsWith('2_3Completed')) {
      return 2;
    }
    return -1; // Should not happen
  }

  // Helper method to get the suite index from a quest key
  int _getSuiteIndexFromKey(String questKey) {
    if (questKey.contains('1_')) {
      return 1;
    } else if (questKey.contains('2_')) {
      return 2;
    }
    return -1; // Should not happen
  }

  // MODIFIÉ : Cette méthode a été déplacée ici.
  // Helper pour vérifier si une quête est complétée dans le tour actuel ou les précédents
  bool _isQuestActuallyCompleted(bool isMyPlayer, int suiteIndex, int questIndex) {
    final List<Quest> targetSuiteCurrentRound = _getQuestSuite(isMyPlayer, suiteIndex);
    if (questIndex < 0 || questIndex >= targetSuiteCurrentRound.length) return false;

    // Check current round status
    if (targetSuiteCurrentRound[questIndex].status == QuestStatus.completed) {
      return true;
    }

    // Check previous rounds status
    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        final List<Quest> previousRoundSuite = isMyPlayer
            ? ((suiteIndex == 1) ? round.myQuestsSuite1 : round.myQuestsSuite2)
            : ((suiteIndex == 1) ? round.opponentQuestsSuite1 : round.opponentQuestsSuite2);
        if (questIndex < previousRoundSuite.length && previousRoundSuite[questIndex].status == QuestStatus.completed) {
          return true;
        }
      }
    }
    return false;
  }

  void _updateQuest(String questKey, bool value, bool isMyPlayer) {
    final int suiteIndex = _getSuiteIndexFromKey(questKey);
    final int questIndex = _getQuestIndexFromKey(questKey);

    if (suiteIndex == -1 || questIndex == -1) {
      return; // Invalid quest key
    }

    bool questUpdated = false;

    // Create a mutable copy of the current round to update quests
    Round tempRound = _currentRound.copyWith(); // Using copyWith to ensure immutability pattern

    if (value) { // Si on veut cocher la quête
      questUpdated = tempRound.completeQuest(isMyPlayer, suiteIndex, questIndex);
      if (!questUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez compléter la quête précédente d\'abord.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else { // Si on veut décocher la quête
      questUpdated = tempRound.uncompleteQuest(isMyPlayer, suiteIndex, questIndex);
      if (!questUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord désactiver les quêtes suivantes.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    if (questUpdated) {
      // Update _currentRound in the state and persist
      _updateRoundLocally(tempRound);
    }
  }


  // MODIFIÉ : Nouvelle version de _buildPlayerSelectionButton pour un meilleur style
  Widget _buildPlayerSelectionButton({
    required String playerKey,
    required String playerName,
    required bool isSelected,
    required Function(String) onSelect,
    double fontSize = 14,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 8),
  }) {
    String trigram = playerName.length >= 3 ? playerName.substring(0, 3).toUpperCase() : playerName.toUpperCase();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).cardColor,
            foregroundColor: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade400,
              width: 1,
            ),
            padding: padding,
            textStyle: TextStyle(fontSize: fontSize, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            minimumSize: const Size(0, 36),
            elevation: isSelected ? 4 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: Text(trigram),
        ),
      ),
    );
  }

  // Widget pour l'affichage de l'initiative
  Widget _buildInitiativeRow(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            'Initiative',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'me',
          playerName: _myPlayerName,
          isSelected: _currentRound.initiativePlayerId == 'me',
          onSelect: _updateInitiative,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'opponent',
          playerName: _opponentPlayerName,
          isSelected: _currentRound.initiativePlayerId == 'opponent',
          onSelect: _updateInitiative,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }

  // Widget pour l'affichage de la priorité
  Widget _buildPriorityRow(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            'Priorité',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'me',
          playerName: _myPlayerName,
          isSelected: _currentRound.priorityPlayerId == 'me',
          onSelect: _updatePriority,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'opponent',
          playerName: _opponentPlayerName,
          isSelected: _currentRound.priorityPlayerId == 'opponent',
          onSelect: _updatePriority,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Les scores cumulés des rounds précédents sont toujours calculés dynamiquement pour l'affichage
    // et pour déterminer les opportunités de quêtes basées sur l'historique
    int myTotalScorePreviousRounds = 0;
    int opponentTotalScorePreviousRounds = 0;

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myTotalScorePreviousRounds += round.calculatePlayerTotalScore(true);
        opponentTotalScorePreviousRounds += round.calculatePlayerTotalScore(false);
      }
    }

    // Les données nécessaires pour les PlayerScoreCard
    Map<String, dynamic> myPlayerData = {
      'playerName': _myPlayerName,
      'isMyPlayer': true,
      'currentRound': _currentRound,
      'game': widget.game,
      'roundNumber': widget.roundNumber,
      'onUpdatePrimaryScore': _updatePrimaryScore,
      'onUpdateQuest': _updateQuest,
      'isQuestActuallyCompleted': _isQuestActuallyCompleted, // Pass the method here
    };

    Map<String, dynamic> opponentPlayerData = {
      'playerName': _opponentPlayerName,
      'isMyPlayer': false,
      'currentRound': _currentRound,
      'game': widget.game,
      'roundNumber': widget.roundNumber,
      'onUpdatePrimaryScore': _updatePrimaryScore,
      'onUpdateQuest': _updateQuest,
      'isQuestActuallyCompleted': _isQuestActuallyCompleted, // Pass the method here
    };


    Widget myPlayerCard = PlayerScoreCard(
      playerName: myPlayerData['playerName'],
      isMyPlayer: myPlayerData['isMyPlayer'],
      currentRound: myPlayerData['currentRound'],
      game: myPlayerData['game'],
      roundNumber: myPlayerData['roundNumber'],
      onUpdatePrimaryScore: myPlayerData['onUpdatePrimaryScore'],
      onUpdateQuest: myPlayerData['onUpdateQuest'],
      isQuestActuallyCompleted: myPlayerData['isQuestActuallyCompleted'],
    );

    Widget opponentPlayerCard = PlayerScoreCard(
      playerName: opponentPlayerData['playerName'],
      isMyPlayer: opponentPlayerData['isMyPlayer'],
      currentRound: opponentPlayerData['currentRound'],
      game: opponentPlayerData['game'],
      roundNumber: opponentPlayerData['roundNumber'],
      onUpdatePrimaryScore: opponentPlayerData['onUpdatePrimaryScore'],
      onUpdateQuest: opponentPlayerData['onUpdateQuest'],
      isQuestActuallyCompleted: opponentPlayerData['isQuestActuallyCompleted'],
    );

    List<Widget> orderedPlayerCards = [];
    if (_currentRound.priorityPlayerId == 'me') {
      orderedPlayerCards.add(myPlayerCard);
      orderedPlayerCards.add(opponentPlayerCard);
    } else if (_currentRound.priorityPlayerId == 'opponent') {
      orderedPlayerCards.add(opponentPlayerCard);
      orderedPlayerCards.add(myPlayerCard);
    } else {
      orderedPlayerCards.add(myPlayerCard);
      orderedPlayerCards.add(opponentPlayerCard);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Jet d'initiative sur une ligne
              _buildInitiativeRow(context),
              const SizedBox(height: 10),

              // Priorité du tour sur une autre ligne
              _buildPriorityRow(context),
              const SizedBox(height: 20),

              ...orderedPlayerCards,
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}