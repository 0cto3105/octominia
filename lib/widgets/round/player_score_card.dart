// lib/widgets/round/player_score_card.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/widgets/round/primary_score_slider.dart';
import 'package:octominia/widgets/round/quest_section.dart';

class PlayerScoreCard extends StatelessWidget {
  final String playerName;
  final bool isMyPlayer;
  final Round currentRound;
  final Game game;
  final int roundNumber;
  final Function(int newScore, bool isMyPlayer) onUpdatePrimaryScore;
  final Function(String questKey, bool value, bool isMyPlayer) onUpdateQuest;
  final Function(bool isMyPlayer, int suiteIndex, int questIndex) isQuestActuallyCompleted;


  const PlayerScoreCard({
    super.key,
    required this.playerName,
    required this.isMyPlayer,
    required this.currentRound,
    required this.game,
    required this.roundNumber,
    required this.onUpdatePrimaryScore,
    required this.onUpdateQuest,
    required this.isQuestActuallyCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer le joueur qui était second au round précédent pour déterminer le double tour
    String? previousRoundPriorityPlayerId;
    if (roundNumber > 1) {
      final previousRound = game.rounds.firstWhere(
            (round) => round.roundNumber == roundNumber - 1,
        orElse: () => Round( // Fallback pour éviter null si le round précédent n'existe pas (devrait pas arriver)
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
      playerWhoWasSecondLastRound = (previousRoundPriorityPlayerId == 'me') ? 'opponent' : 'me';
    }

    // Déterminer si un double tour est déclenché par les choix actuels (initiative + priorité)
    bool isDoubleTurnTriggeredByCurrentChoice = false;
    if (currentRound.initiativePlayerId != null &&
        currentRound.priorityPlayerId != null &&
        playerWhoWasSecondLastRound != null &&
        currentRound.initiativePlayerId == playerWhoWasSecondLastRound &&
        currentRound.priorityPlayerId == playerWhoWasSecondLastRound &&
        ((isMyPlayer && currentRound.priorityPlayerId == 'me') || (!isMyPlayer && currentRound.priorityPlayerId == 'opponent'))
    ) {
      isDoubleTurnTriggeredByCurrentChoice = true;
    }

    // Déterminer si le joueur est l'underdog pour ce round
    bool isUnderdogForRound = (isMyPlayer && currentRound.underdogPlayerIdAtEndOfRound == 'me') || (!isMyPlayer && currentRound.underdogPlayerIdAtEndOfRound == 'opponent');

    // Déterminer si le joueur a l'OPPORTUNITÉ d'un double tour gratuit (basé sur les scores passés)
    bool isDoubleFreeTurnOpportunity = ((isMyPlayer && currentRound.myPlayerHadDoubleFreeTurn) || (!isMyPlayer && currentRound.opponentPlayerHadDoubleFreeTurn));

    // Déterminer si la pastille "Double Free Turn" doit être affichée (opportunité + déclenché)
    bool showDoubleFreeTurnBadge = isDoubleFreeTurnOpportunity && isDoubleTurnTriggeredByCurrentChoice;

    // Déterminer si la pastille "Going for a Double Turn" doit être affichée (déclenché mais pas gratuit)
    bool showGoingForDoubleTurnBadge = isDoubleTurnTriggeredByCurrentChoice && !isDoubleFreeTurnOpportunity;

    // NOUVEAU : Déterminer si le joueur a fait un double tour non gratuit ce round
    bool didNonFreeDoubleTurnThisRound = (isMyPlayer && currentRound.myPlayerDidNonFreeDoubleTurn) ||
                                         (!isMyPlayer && currentRound.opponentPlayerDidNonFreeDoubleTurn);

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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow, // Couleur pour le nom du joueur
                  ),
                ),
                const SizedBox(width: 8),
                // Logique d'affichage des badges par ordre de priorité
                if (showDoubleFreeTurnBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent, // Couleur spécifique pour "Double Free Turn"
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Text(
                      'Double Free Turn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (showGoingForDoubleTurnBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple, // Couleur spécifique pour "Going for a Double Turn"
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Going for a Double Turn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isUnderdogForRound)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey, // Couleur pour "Underdog"
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Underdog',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            PrimaryScoreSlider(
              currentScore: isMyPlayer ? currentRound.myScore : currentRound.opponentScore,
              onChanged: (newScore) => onUpdatePrimaryScore(newScore, isMyPlayer),
            ),
            const SizedBox(height: 20),
            // NOUVEAU : Condition pour afficher la QuestSection
            if (!didNonFreeDoubleTurnThisRound) // Si le joueur n'a PAS fait de double tour non gratuit
              QuestSection(
                isMyPlayer: isMyPlayer,
                currentRound: currentRound,
                onUpdateQuest: onUpdateQuest,
                isQuestActuallyCompleted: isQuestActuallyCompleted,
                game: game,
                roundNumber: roundNumber,
              )
            else // Si le joueur a fait un double tour non gratuit, afficher un message
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Pas de quête ce tour (Double Tour non gratuit)',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.error, // Couleur d'erreur ou de mise en garde
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}