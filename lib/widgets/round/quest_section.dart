// lib/widgets/round/quest_section.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/models/quest.dart';
import 'package:octominia/widgets/round/quest_checkbox.dart';

class QuestSection extends StatelessWidget {
  final bool isMyPlayer;
  final Round currentRound;
  final Function(int suiteIndex, int questIndex) onUpdateQuest;

  const QuestSection({
    super.key,
    required this.isMyPlayer,
    required this.currentRound,
    required this.onUpdateQuest,
  });

  @override
  Widget build(BuildContext context) {
    final questSuites = isMyPlayer
        ? [currentRound.myQuestsSuite1, currentRound.myQuestsSuite2]
        : [currentRound.opponentQuestsSuite1, currentRound.opponentQuestsSuite2];

    final suite1CompletedThisRound = isMyPlayer ? currentRound.myQuestSuite1CompletedThisRound : currentRound.opponentQuestSuite1CompletedThisRound;
    final suite2CompletedThisRound = isMyPlayer ? currentRound.myQuestSuite2CompletedThisRound : currentRound.opponentQuestSuite2CompletedThisRound;
    final suitesCompletedThisRound = [suite1CompletedThisRound, suite2CompletedThisRound];

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
            for (int suiteIndex = 0; suiteIndex < questSuites.length; suiteIndex++)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(questSuites[suiteIndex].length, (questIndex) {
                    final quest = questSuites[suiteIndex][questIndex];
                    final bool suiteCompletedThisRound = suitesCompletedThisRound[suiteIndex];

                    // CORRECTION: Logique pour pouvoir décocher une quête
                    // Une quête est pré-complétée (grisée) si elle est faite, mais pas ce tour-ci
                    final bool isPreCompleted = quest.status == QuestStatus.completed && !suiteCompletedThisRound;
                    
                    // Une quête est interactive si :
                    // 1. Elle est débloquée et aucune autre de la suite n'a été faite ce tour-ci
                    final bool canBeCompleted = quest.status == QuestStatus.unlocked && !suiteCompletedThisRound;
                    // 2. OU si c'est ELLE qui a été complétée ce tour-ci (permet de la décocher)
                    final bool canBeUncompleted = quest.status == QuestStatus.completed && suiteCompletedThisRound;
                    
                    final bool isEnabled = canBeCompleted || canBeUncompleted;

                    return QuestCheckbox(
                      label: '${suiteIndex + 1} - ${quest.name}',
                      value: quest.status == QuestStatus.completed,
                      isEnabled: isEnabled,
                      isPreCompleted: isPreCompleted,
                      onChanged: (newValue) {
                        onUpdateQuest(suiteIndex + 1, questIndex);
                      },
                    );
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }
}