// lib/widgets/round/quest_section.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/models/quest.dart';
import 'package:octominia/models/game.dart'; // Import game to access previous rounds
import 'package:octominia/widgets/round/quest_checkbox.dart'; // Import the new QuestCheckbox widget

class QuestSection extends StatelessWidget {
  final bool isMyPlayer;
  final Round currentRound;
  final Function(String questKey, bool value, bool isMyPlayer) onUpdateQuest;
  final Function(bool isMyPlayer, int suiteIndex, int questIndex) isQuestActuallyCompleted;
  final Game game; // Pass the entire game object to access all rounds
  final int roundNumber; // Pass the current round number

  const QuestSection({
    super.key,
    required this.isMyPlayer,
    required this.currentRound,
    required this.onUpdateQuest,
    required this.isQuestActuallyCompleted,
    required this.game,
    required this.roundNumber,
  });

  // Helper method to get the correct quest list based on player and suite
  List<Quest> _getQuestSuite(bool isMyPlayer, int suiteIndex) {
    if (isMyPlayer) {
      return (suiteIndex == 1) ? currentRound.myQuestsSuite1 : currentRound.myQuestsSuite2;
    } else {
      return (suiteIndex == 1) ? currentRound.opponentQuestsSuite1 : currentRound.opponentQuestsSuite2;
    }
  }

  // Helper pour vérifier si une quête est complétée dans le tour actuel ou les précédents
  bool _isQuestActuallyCompletedLocal(bool isMyPlayer, int suiteIndex, int questIndex) {
    final List<Quest> targetSuite = _getQuestSuite(isMyPlayer, suiteIndex);
    if (questIndex < 0 || questIndex >= targetSuite.length) return false;

    // Check current round status
    if (targetSuite[questIndex].status == QuestStatus.completed) {
      return true;
    }

    // Check previous rounds status
    for (var round in game.rounds) {
      if (round.roundNumber < roundNumber) {
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

  @override
  Widget build(BuildContext context) {
    // Déterminer si les quêtes sont désactivées pour ce joueur à cause d'un double tour non gratuit
    bool disableQuestsGlobally = (isMyPlayer && currentRound.myPlayerDidNonFreeDoubleTurn) ||
        (!isMyPlayer && currentRound.opponentPlayerDidNonFreeDoubleTurn);

    // Fonction pour déterminer si une quête est activée
    bool _isQuestEnabled(int suiteIndex, int questIndex) {
      if (disableQuestsGlobally) return false;

      final List<Quest> targetSuite = _getQuestSuite(isMyPlayer, suiteIndex);
      if (questIndex < 0 || questIndex >= targetSuite.length) return false;

      final Quest currentQuest = targetSuite[questIndex];

      // Une quête est activée si elle est "unlocked"
      bool isUnlocked = currentQuest.status == QuestStatus.unlocked;
      // Ou si elle est "completed" (pour permettre de la décocher si nécessaire)
      bool isCompleted = currentQuest.status == QuestStatus.completed;

      // Si c'est la première quête de la suite (index 0), elle est débloquée par défaut au début du round
      // et elle est toujours activable si elle n'est pas déjà complétée dans les tours précédents.
      if (questIndex == 0) {
        return (isUnlocked || isCompleted);
      } else {
        // Pour les quêtes suivantes, elles dépendent de la complétion de la quête précédente
        final bool previousQuestCompleted = _isQuestActuallyCompletedLocal(isMyPlayer, suiteIndex, questIndex - 1);
        return (previousQuestCompleted && (isUnlocked || isCompleted));
      }
    }

    List<Quest> currentPlayersQuestsSuite1 = isMyPlayer ? currentRound.myQuestsSuite1 : currentRound.opponentQuestsSuite1;
    List<Quest> currentPlayersQuestsSuite2 = isMyPlayer ? currentRound.myQuestsSuite2 : currentRound.opponentQuestsSuite2;

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
                  ...List.generate(currentPlayersQuestsSuite1.length, (index) {
                    final quest = currentPlayersQuestsSuite1[index];
                    return QuestCheckbox(
                      label: '1 - ${quest.name}',
                      value: quest.status == QuestStatus.completed,
                      onChanged: (newValue) => onUpdateQuest(
                          (isMyPlayer ? 'myQuest' : 'opponentQuest') + '1_' + (index + 1).toString() + 'Completed',
                          newValue,
                          isMyPlayer),
                      isEnabled: _isQuestEnabled(1, index),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Groupe de Quêtes 2
                  ...List.generate(currentPlayersQuestsSuite2.length, (index) {
                    final quest = currentPlayersQuestsSuite2[index];
                    return QuestCheckbox(
                      label: '2 - ${quest.name}',
                      value: quest.status == QuestStatus.completed,
                      onChanged: (newValue) => onUpdateQuest(
                          (isMyPlayer ? 'myQuest' : 'opponentQuest') + '2_' + (index + 1).toString() + 'Completed',
                          newValue,
                          isMyPlayer),
                      isEnabled: _isQuestEnabled(2, index),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}