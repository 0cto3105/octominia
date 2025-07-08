// lib/screens/game_round_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';

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

    _currentRound = widget.game.rounds.firstWhere(
      (round) => round.roundNumber == widget.roundNumber,
    );

    // DÉFINIR 'me' COMME PRIORITÉ PAR DÉFAUT SI NULL
    if (_currentRound.priorityPlayerId == null) {
      _currentRound = _currentRound.copyWith(priorityPlayerId: 'me');
    }
  }

  void _updateRoundLocally(Round updatedRound) {
    setState(() {
      _currentRound = updatedRound;
    });
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
    // Si l'utilisateur tente de décocher une quête
    if (!value) {
      bool canUncheck = true; // Par défaut, on peut décocher
      if (isMyPlayer) {
        // Logique pour les quêtes du joueur : empêcher de décocher si une quête suivante est cochée DANS CE ROUND
        if (questKey == 'myQuest1_2Completed' && _currentRound.myQuest1_3Completed) canUncheck = false;
        if (questKey == 'myQuest1_1Completed' && (_currentRound.myQuest1_2Completed || _currentRound.myQuest1_3Completed)) canUncheck = false;
        if (questKey == 'myQuest2_2Completed' && _currentRound.myQuest2_3Completed) canUncheck = false;
        if (questKey == 'myQuest2_1Completed' && (_currentRound.myQuest2_2Completed || _currentRound.myQuest2_3Completed)) canUncheck = false;
      } else {
        // Logique pour les quêtes de l'adversaire
        if (questKey == 'opponentQuest1_2Completed' && _currentRound.opponentQuest1_3Completed) canUncheck = false;
        if (questKey == 'opponentQuest1_1Completed' && (_currentRound.opponentQuest1_2Completed || _currentRound.opponentQuest1_3Completed)) canUncheck = false;
        if (questKey == 'opponentQuest2_2Completed' && _currentRound.opponentQuest2_3Completed) canUncheck = false;
        if (questKey == 'opponentQuest2_1Completed' && (_currentRound.opponentQuest2_2Completed || _currentRound.opponentQuest2_3Completed)) canUncheck = false;
      }

      if (!canUncheck) {
        // Afficher un message à l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord désactiver les quêtes suivantes.'),
            duration: Duration(seconds: 2),
          ),
        );
        return; // Empêche la mise à jour si le décheck est invalide
      }
    }

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
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineSmall?.color),
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
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
            foregroundColor:
                isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
      ]);
  }

  // Helper method to build the primary score slider and display its value
  Widget _buildPrimaryScoreSlider(BuildContext context, int currentScore, bool isMyPlayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Primaire',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
        Row(
          children: [
            // Affichage du chiffre à gauche du slider
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                currentScore.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Expanded(
              child: Slider(
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
            ),
          ],
        ),
      ],
    );
  }

  // Modified to accept isEnabled
  Widget _buildQuestCheckbox(String label, bool value, Function(bool)? onChanged, {required bool isEnabled}) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: isEnabled
              ? (bool? newValue) {
                    if (onChanged != null) {
                      onChanged(newValue ?? false);
                    }
                  }
              : null,
          checkColor: Colors.white,
          activeColor: Theme.of(context).primaryColor,
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isEnabled
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ],
    );
  }

  // Nouvelle fonction pour vérifier si une quête a été complétée dans un des tours précédents
  bool _wasQuestCompletedInAnyPreviousRound(String questKey, bool isMyPlayer) {
    return widget.game.rounds.any((round) {
      if (round.roundNumber < widget.roundNumber) {
        if (isMyPlayer) {
          switch (questKey) {
            case 'myQuest1_1Completed': return round.myQuest1_1Completed;
            case 'myQuest1_2Completed': return round.myQuest1_2Completed;
            case 'myQuest2_1Completed': return round.myQuest2_1Completed;
            case 'myQuest2_2Completed': return round.myQuest2_2Completed;
          }
        } else {
          switch (questKey) {
            case 'opponentQuest1_1Completed': return round.opponentQuest1_1Completed;
            case 'opponentQuest1_2Completed': return round.opponentQuest1_2Completed;
            case 'opponentQuest2_1Completed': return round.opponentQuest2_1Completed;
            case 'opponentQuest2_2Completed': return round.opponentQuest2_2Completed;
          }
        }
      }
      return false;
    });
  }


  // Refactored to group quests into two columns and use new labels.
  // Logic updated to use _wasQuestCompletedInAnyPreviousRound for unlocking Strike and Domination.
  Widget _buildQuestSection(BuildContext context, bool isMyPlayer) {
    // Déterminer l'état d'activation de chaque quête en fonction de la complétion des précédentes (dans n'importe quel tour précédent)
    bool isQuest1_1Enabled = true; // 1 - Affray est toujours activée
    bool isQuest1_2Enabled = _wasQuestCompletedInAnyPreviousRound(isMyPlayer ? 'myQuest1_1Completed' : 'opponentQuest1_1Completed', isMyPlayer); // 1 - Strike s'active si 1 - Affray a été complétée dans un tour précédent
    bool isQuest1_3Enabled = _wasQuestCompletedInAnyPreviousRound(isMyPlayer ? 'myQuest1_2Completed' : 'opponentQuest1_2Completed', isMyPlayer); // 1 - Domination s'active si 1 - Strike a été complétée dans un tour précédent

    bool isQuest2_1Enabled = true; // 2 - Affray est toujours activée
    bool isQuest2_2Enabled = _wasQuestCompletedInAnyPreviousRound(isMyPlayer ? 'myQuest2_1Completed' : 'opponentQuest2_1Completed', isMyPlayer); // 2 - Strike s'active si 2 - Affray a été complétée dans un tour précédent
    bool isQuest2_3Enabled = _wasQuestCompletedInAnyPreviousRound(isMyPlayer ? 'myQuest2_2Completed' : 'opponentQuest2_2Completed', isMyPlayer); // 2 - Domination s'active si 2 - Strike a été complétée dans un tour précédent

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Secondaire',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Groupe de Quêtes 1
                  _buildQuestCheckbox(
                    '1 - Affray',
                    isMyPlayer ? _currentRound.myQuest1_1Completed : _currentRound.opponentQuest1_1Completed,
                    (newValue) => _updateQuest(isMyPlayer ? 'myQuest1_1Completed' : 'opponentQuest1_1Completed', newValue, isMyPlayer),
                    isEnabled: isQuest1_1Enabled,
                  ),
                  _buildQuestCheckbox(
                    '1 - Strike',
                    isMyPlayer ? _currentRound.myQuest1_2Completed : _currentRound.opponentQuest1_2Completed,
                    (newValue) => _updateQuest(isMyPlayer ? 'myQuest1_2Completed' : 'opponentQuest1_2Completed', newValue, isMyPlayer),
                    isEnabled: isQuest1_2Enabled,
                  ),
                  _buildQuestCheckbox(
                    '1 - Domination',
                    isMyPlayer ? _currentRound.myQuest1_3Completed : _currentRound.opponentQuest1_3Completed,
                    (newValue) => _updateQuest(isMyPlayer ? 'myQuest1_3Completed' : 'opponentQuest1_3Completed', newValue, isMyPlayer),
                    isEnabled: isQuest1_3Enabled,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Groupe de Quêtes 2
                  _buildQuestCheckbox(
                    '2 - Affray',
                    isMyPlayer ? _currentRound.myQuest2_1Completed : _currentRound.opponentQuest2_1Completed,
                    (newValue) => _updateQuest(isMyPlayer ? 'myQuest2_1Completed' : 'opponentQuest2_1Completed', newValue, isMyPlayer),
                    isEnabled: isQuest2_1Enabled,
                  ),
                  _buildQuestCheckbox(
                    '2 - Strike',
                    isMyPlayer ? _currentRound.myQuest2_2Completed : _currentRound.opponentQuest2_2Completed,
                    (newValue) => _updateQuest(isMyPlayer ? 'myQuest2_2Completed' : 'opponentQuest2_2Completed', newValue, isMyPlayer),
                    isEnabled: isQuest2_2Enabled,
                  ),
                  _buildQuestCheckbox(
                    '2 - Domination',
                    isMyPlayer ? _currentRound.myQuest2_3Completed : _currentRound.opponentQuest2_3Completed,
                    (newValue) => _updateQuest(isMyPlayer ? 'myQuest2_3Completed' : 'opponentQuest2_3Completed', newValue, isMyPlayer),
                    isEnabled: isQuest2_3Enabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New Widget to encapsulate player's score and quest sections in a Card
  // Modified to accept total scores for underdog logic
  Widget _buildPlayerScoreCard(BuildContext context, String playerName, bool isMyPlayer, int myTotalScorePreviousRounds, int opponentTotalScorePreviousRounds) {
    // Determine the underdog
    String? underdogPlayerId;
    int scoreDifference = (myTotalScorePreviousRounds - opponentTotalScorePreviousRounds).abs();

    if (myTotalScorePreviousRounds < opponentTotalScorePreviousRounds) {
      underdogPlayerId = 'me';
    } else if (opponentTotalScorePreviousRounds < myTotalScorePreviousRounds) {
      underdogPlayerId = 'opponent';
    }

    // Determine if the current player is the underdog
    bool isUnderdog = (isMyPlayer && underdogPlayerId == 'me') || (!isMyPlayer && underdogPlayerId == 'opponent');
    bool isDoubleFreeTurn = isUnderdog && scoreDifference >= 11;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      // Padding réduit en haut pour remonter le pseudo
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0), // Top padding réduit
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pseudo de la personne concernée en haut à gauche, discret, en jaune
                Text(
                  playerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(width: 8), // Space between name and badge
                if (isUnderdog)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDoubleFreeTurn ? Colors.redAccent : Colors.blueGrey, // More prominent if double free turn
                      borderRadius: BorderRadius.circular(20),
                      border: isDoubleFreeTurn ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Text(
                      isDoubleFreeTurn ? 'Double Free Turn' : 'Underdog', // Text based on condition
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10), // Petit espace après le titre

            _buildPrimaryScoreSlider(
                context,
                isMyPlayer ? _currentRound.myScore : _currentRound.opponentScore,
                isMyPlayer),
            const SizedBox(height: 20),
            _buildQuestSection(context, isMyPlayer),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialiser les scores des tours précédents à zéro, car les 'drops' et 'auxiliary units' ne sont pas des points de score.
    int myScorePreviousRounds = 0; // CORRIGÉ : Initialisé à 0
    int opponentScorePreviousRounds = 0; // CORRIGÉ : Initialisé à 0

    // Ajouter les scores totaux de chaque tour précédent (primaire + quêtes)
    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myScorePreviousRounds += round.calculatePlayerTotalScore(true);
        opponentScorePreviousRounds += round.calculatePlayerTotalScore(false);
      }
    }

    // Create the player sections encapsulated in Cards
    // Passer les scores calculés au début du tour à _buildPlayerScoreCard
    Widget myPlayerCard = _buildPlayerScoreCard(context, _myPlayerName, true, myScorePreviousRounds, opponentScorePreviousRounds);
    Widget opponentPlayerCard = _buildPlayerScoreCard(context, _opponentPlayerName, false, myScorePreviousRounds, opponentScorePreviousRounds);

    // List of widgets to display in the body, ordered by priority
    List<Widget> orderedPlayerCards = [];
    if (_currentRound.priorityPlayerId == 'me') {
      orderedPlayerCards.add(myPlayerCard);
      orderedPlayerCards.add(opponentPlayerCard);
    } else if (_currentRound.priorityPlayerId == 'opponent') {
      orderedPlayerCards.add(opponentPlayerCard);
      orderedPlayerCards.add(myPlayerCard);
    } else {
      // Default order if no priority or priorityPlayerId is null (e.g., my player first)
      orderedPlayerCards.add(myPlayerCard);
      orderedPlayerCards.add(opponentPlayerCard);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Display the overall total score (this one uses the actual overall game score including current round)
            Align(
              alignment: Alignment.center,
              child: Text(
                '$_myPlayerName ${widget.game.myScore} - $_opponentPlayerName ${widget.game.opponentScore}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            _buildPrioritySelection(context),
            const SizedBox(height: 20),

            // Add the player sections in the order defined by round priority
            ...orderedPlayerCards,
          ],
        ),
      ),
    );
  }
}