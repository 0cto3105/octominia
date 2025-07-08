// lib/screens/game_round_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';
import 'package:flutter/scheduler.dart'; // Import this for WidgetsBinding

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

    // Find the current round
    final existingRound = widget.game.rounds.firstWhere(
      (round) => round.roundNumber == widget.roundNumber,
      orElse: () => null as Round, // Cast to Round? explicitly for null safety
    );

    if (existingRound != null) {
      _currentRound = existingRound;
    } else {
      // If the round doesn't exist, create a new one
      final newRound = Round(
        roundNumber: widget.roundNumber,
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
      );
      _currentRound = newRound; // Assign the newly created round

      // Defer the call to onUpdateRound until after the current frame
      // This prevents calling setState on the parent during its build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Ensure the widget is still mounted before calling the callback
          widget.onUpdateRound(newRound);
        }
      });
    }
  }

  void _updateRoundLocally(Round updatedRound) {
    setState(() {
      _currentRound = updatedRound;
    });
    // Propagate changes to parent after local state is updated
    widget.onUpdateRound(_currentRound);
  }

  void _updatePriority(String? playerKey) {
    _updateRoundLocally(_currentRound.copyWith(priorityPlayerId: playerKey));
  }

  void _updatePrimaryScore(int newScore, bool isMyPlayer) {
    _updateRoundLocally(isMyPlayer
        ? _currentRound.copyWith(myScore: newScore)
        : _currentRound.copyWith(opponentScore: newScore));
  }

  void _updateQuest(String questKey, bool value, bool isMyPlayer) {
    Round updatedRound = _currentRound;
    if (isMyPlayer) {
      switch (questKey) {
        case 'myQuest1_1Completed':
          updatedRound = updatedRound.copyWith(myQuest1_1Completed: value);
          break;
        case 'myQuest1_2Completed':
          updatedRound = updatedRound.copyWith(myQuest1_2Completed: value);
          break;
        case 'myQuest1_3Completed':
          updatedRound = updatedRound.copyWith(myQuest1_3Completed: value);
          break;
        case 'myQuest2_1Completed':
          updatedRound = updatedRound.copyWith(myQuest2_1Completed: value);
          break;
        case 'myQuest2_2Completed':
          updatedRound = updatedRound.copyWith(myQuest2_2Completed: value);
          break;
        case 'myQuest2_3Completed':
          updatedRound = updatedRound.copyWith(myQuest2_3Completed: value);
          break;
      }
    } else {
      switch (questKey) {
        case 'opponentQuest1_1Completed':
          updatedRound = updatedRound.copyWith(opponentQuest1_1Completed: value);
          break;
        case 'opponentQuest1_2Completed':
          updatedRound = updatedRound.copyWith(opponentQuest1_2Completed: value);
          break;
        case 'opponentQuest1_3Completed':
          updatedRound = updatedRound.copyWith(opponentQuest1_3Completed: value);
          break;
        case 'opponentQuest2_1Completed':
          updatedRound = updatedRound.copyWith(opponentQuest2_1Completed: value);
          break;
        case 'opponentQuest2_2Completed':
          updatedRound = updatedRound.copyWith(opponentQuest2_2Completed: value);
          break;
        case 'opponentQuest2_3Completed':
          updatedRound = updatedRound.copyWith(opponentQuest2_3Completed: value);
          break;
      }
    }
    _updateRoundLocally(updatedRound);
  }


  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
      ),
    );
  }

  Widget _buildPlayerSelectionButton({
    required String playerKey,
    required String playerName,
    required bool isSelected,
    required Function(String) onSelect,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
            foregroundColor: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: Text(playerName),
        ),
      ),
    );
  }

  Widget _buildPrioritySelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Priorité du Tour'),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildPlayerSelectionButton(
              playerKey: 'me',
              playerName: _myPlayerName,
              isSelected: _currentRound.priorityPlayerId == 'me',
              onSelect: _updatePriority,
            ),
            _buildPlayerSelectionButton(
              playerKey: 'opponent',
              playerName: _opponentPlayerName,
              isSelected: _currentRound.priorityPlayerId == 'opponent',
              onSelect: _updatePriority,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryScoreSelection(BuildContext context, String playerName, int currentScore, bool isMyPlayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Score Primaire ($playerName)'),
        Slider(
          value: currentScore.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: currentScore.toString(),
          onChanged: (double value) {
            _updatePrimaryScore(value.round(), isMyPlayer);
          },
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildQuestCheckbox(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (bool? newValue) {
            onChanged(newValue ?? false);
          },
          checkColor: Colors.white,
          activeColor: Theme.of(context).primaryColor,
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestSection(BuildContext context, String playerName, bool isMyPlayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Quêtes ($playerName)'),
        _buildQuestCheckbox(
          'Quête 1.1',
          isMyPlayer ? _currentRound.myQuest1_1Completed : _currentRound.opponentQuest1_1Completed,
          (newValue) => _updateQuest('myQuest1_1Completed', newValue, isMyPlayer),
        ),
        _buildQuestCheckbox(
          'Quête 1.2',
          isMyPlayer ? _currentRound.myQuest1_2Completed : _currentRound.opponentQuest1_2Completed,
          (newValue) => _updateQuest('myQuest1_2Completed', newValue, isMyPlayer),
        ),
        _buildQuestCheckbox(
          'Quête 1.3',
          isMyPlayer ? _currentRound.myQuest1_3Completed : _currentRound.opponentQuest1_3Completed,
          (newValue) => _updateQuest('myQuest1_3Completed', newValue, isMyPlayer),
        ),
        _buildQuestCheckbox(
          'Quête 2.1',
          isMyPlayer ? _currentRound.myQuest2_1Completed : _currentRound.opponentQuest2_1Completed,
          (newValue) => _updateQuest('myQuest2_1Completed', newValue, isMyPlayer),
        ),
        _buildQuestCheckbox(
          'Quête 2.2',
          isMyPlayer ? _currentRound.myQuest2_2Completed : _currentRound.opponentQuest2_2Completed,
          (newValue) => _updateQuest('myQuest2_2Completed', newValue, isMyPlayer),
        ),
        _buildQuestCheckbox(
          'Quête 2.3',
          isMyPlayer ? _currentRound.myQuest2_3Completed : _currentRound.opponentQuest2_3Completed,
          (newValue) => _updateQuest('myQuest2_3Completed', newValue, isMyPlayer),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate overall total scores for display
    int myOverallTotalScore = widget.game.myScore;
    int opponentOverallTotalScore = widget.game.opponentScore;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Tour ${widget.roundNumber}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
              ),
            ),
            const SizedBox(height: 10),
            // Aperçu du Score Total Actuel
            Align(
              alignment: Alignment.center,
              child: Text(
                'Score Actuel: $_myPlayerName $myOverallTotalScore - $_opponentPlayerName $opponentOverallTotalScore',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            _buildPrioritySelection(context),
            const SizedBox(height: 20),

            // Section pour mon joueur
            _buildPrimaryScoreSelection(context, _myPlayerName, _currentRound.myScore, true),
            _buildQuestSection(context, _myPlayerName, true),

            const SizedBox(height: 20), // Espace entre les sections joueur

            // Section pour l'adversaire
            _buildPrimaryScoreSelection(context, _opponentPlayerName, _currentRound.opponentScore, false),
            _buildQuestSection(context, _opponentPlayerName, false),
          ],
        ),
      ),
    );
  }
}