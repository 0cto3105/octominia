// lib/widgets/round/player_score_card.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/widgets/round/primary_score_slider.dart';
import 'package:octominia/widgets/round/quest_section.dart';

class PlayerScoreCard extends StatelessWidget {
  final String playerName;
  final Round currentRound;
  final bool isMyPlayer;

  // CORRECTION : Les noms des drapeaux sont plus clairs
  final bool isUnderdog;
  final bool isEligibleForFreeDoubleTurn;
  final bool isTakingDoubleTurn;
  final bool isPenalizedDoubleTurn;

  final bool canCompleteQuests;
  final ValueChanged<int> onUpdatePrimaryScore;
  final Function(int suiteIndex, int questIndex) onUpdateQuest;

  const PlayerScoreCard({
    super.key,
    required this.playerName,
    required this.currentRound,
    required this.isMyPlayer,
    required this.isUnderdog,
    required this.isEligibleForFreeDoubleTurn,
    required this.isTakingDoubleTurn,
    required this.isPenalizedDoubleTurn,
    required this.canCompleteQuests,
    required this.onUpdatePrimaryScore,
    required this.onUpdateQuest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  playerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.yellow),
                ),
                const SizedBox(width: 8),
                
                // CORRECTION : Nouvelle logique d'affichage des badges avec la bonne priorité
                if (isTakingDoubleTurn)
                  _buildBadge(context, 'Double Tour', isPenalizedDoubleTurn ? Colors.purple : Colors.redAccent.shade100)
                else if (isEligibleForFreeDoubleTurn)
                  _buildBadge(context, 'Double Tour Gratuit', Colors.redAccent, border: Border.all(color: Colors.white, width: 2))
                else if (isUnderdog)
                   _buildBadge(context, 'Underdog', Colors.blueGrey),

              ],
            ),
            const SizedBox(height: 10),

            PrimaryScoreSlider(
              currentScore: isMyPlayer ? currentRound.myScore : currentRound.opponentScore,
              onChanged: onUpdatePrimaryScore,
            ),
            const SizedBox(height: 20),

            if (canCompleteQuests)
              QuestSection(
                isMyPlayer: isMyPlayer,
                currentRound: currentRound,
                onUpdateQuest: onUpdateQuest,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Pas de quête ce tour (Double Tour non gratuit)',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color, {BoxBorder? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}