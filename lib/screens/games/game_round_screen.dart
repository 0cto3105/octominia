// lib/screens/games/game_round_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/widgets/round/player_score_card.dart';

class GameRoundScreen extends StatelessWidget {
  final int roundNumber;
  final Game game;
  final Function(int roundNumber, {int? myScore, int? opponentScore, String? priorityPlayerId, String? initiativePlayerId}) onUpdateRound;
  final Function(int roundNumber, int suiteIndex, int questIndex, bool isMyPlayer) onToggleQuest;

  const GameRoundScreen({
    super.key,
    required this.roundNumber,
    required this.game,
    required this.onUpdateRound,
    required this.onToggleQuest,
  });

  @override
  Widget build(BuildContext context) {
    final currentRound = game.rounds.firstWhere((r) => r.roundNumber == roundNumber);

    final myPlayerCard = PlayerScoreCard(
      playerName: game.myPlayerName,
      currentRound: currentRound,
      isMyPlayer: true,
      isUnderdog: currentRound.underdogPlayerIdForRound == 'me',
      isEligibleForFreeDoubleTurn: currentRound.myPlayerIsEligibleForFreeDoubleTurn,
      isTakingDoubleTurn: currentRound.myPlayerTookDoubleTurn,
      isPenalizedDoubleTurn: currentRound.myPlayerTookPenalizedDoubleTurn,
      canCompleteQuests: !currentRound.myPlayerTookPenalizedDoubleTurn,
      onUpdatePrimaryScore: (newScore) => onUpdateRound(roundNumber, myScore: newScore),
      onUpdateQuest: (suiteIndex, questIndex) => onToggleQuest(roundNumber, suiteIndex, questIndex, true),
    );

    final opponentPlayerCard = PlayerScoreCard(
      playerName: game.opponentPlayerName,
      currentRound: currentRound,
      isMyPlayer: false,
      isUnderdog: currentRound.underdogPlayerIdForRound == 'opponent',
      isEligibleForFreeDoubleTurn: currentRound.opponentPlayerIsEligibleForFreeDoubleTurn,
      isTakingDoubleTurn: currentRound.opponentPlayerTookDoubleTurn,
      isPenalizedDoubleTurn: currentRound.opponentPlayerTookPenalizedDoubleTurn,
      canCompleteQuests: !currentRound.opponentPlayerTookPenalizedDoubleTurn,
      onUpdatePrimaryScore: (newScore) => onUpdateRound(roundNumber, opponentScore: newScore),
      onUpdateQuest: (suiteIndex, questIndex) => onToggleQuest(roundNumber, suiteIndex, questIndex, false),
    );
    
    // La priorité est déterminée par la valeur du round en cours.
    final priorityPlayerThisRound = currentRound.priorityPlayerId;

    final orderedPlayerCards = priorityPlayerThisRound == 'me'
      ? [myPlayerCard, opponentPlayerCard]
      : [opponentPlayerCard, myPlayerCard];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (roundNumber > 1)
                _buildControlRow(
                  context: context,
                  label: 'Initiative',
                  selectedValue: currentRound.initiativePlayerId,
                  onChanged: (value) => onUpdateRound(roundNumber, initiativePlayerId: value),
                ),
              if (roundNumber > 1) const SizedBox(height: 10),

              _buildControlRow(
                context: context,
                label: 'Priorité',
                selectedValue: priorityPlayerThisRound,
                // CORRECTION: L'utilisateur peut maintenant changer la priorité à chaque tour, y compris le T1
                onChanged: (value) => onUpdateRound(roundNumber, priorityPlayerId: value),
              ),
              const SizedBox(height: 20),
              ...orderedPlayerCards,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlRow({
    required BuildContext context,
    required String label,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color))),
        _buildPlayerSelectionButton(context: context, playerKey: 'me', playerName: game.myPlayerName, isSelected: selectedValue == 'me', onSelect: onChanged),
        _buildPlayerSelectionButton(context: context, playerKey: 'opponent', playerName: game.opponentPlayerName, isSelected: selectedValue == 'opponent', onSelect: onChanged),
      ],
    );
  }

  Widget _buildPlayerSelectionButton({
    required BuildContext context,
    required String playerKey,
    required String playerName,
    required bool isSelected,
    required Function(String?) onSelect,
  }) {
    String trigram = playerName.length >= 3 ? playerName.substring(0, 3).toUpperCase() : playerName.toUpperCase();
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
            foregroundColor: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400, width: 1),
            minimumSize: const Size(0, 36),
            elevation: isSelected ? 4 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: Text(trigram),
        ),
      ),
    );
  }
}