// lib/widgets/round/quest_section.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/models/quest.dart';
import 'package:octominia/widgets/round/quest_checkbox.dart';

class QuestSection extends StatelessWidget {
  // NOUVEAU : Constructeur simplifié
  final bool isMyPlayer;
  final Round currentRound;
  // Le callback est maintenant beaucoup plus simple !
  final Function(int suiteIndex, int questIndex) onUpdateQuest;

  const QuestSection({
    super.key,
    required this.isMyPlayer,
    required this.currentRound,
    required this.onUpdateQuest,
  });

  @override
  Widget build(BuildContext context) {
    // TOUTE LA LOGIQUE A ÉTÉ RETIRÉE. Le widget ne fait qu'afficher.

    final questSuites = isMyPlayer
        ? [currentRound.myQuestsSuite1, currentRound.myQuestsSuite2]
        : [currentRound.opponentQuestsSuite1, currentRound.opponentQuestsSuite2];

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
            // Boucle pour générer les deux suites de quêtes
            for (int suiteIndex = 0; suiteIndex < questSuites.length; suiteIndex++)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(questSuites[suiteIndex].length, (questIndex) {
                    final quest = questSuites[suiteIndex][questIndex];
                    // La logique pour savoir si une quête est activée est maintenant très simple :
                    // elle est active si son statut n'est pas "locked".
                    // Le moteur "game.dart" a déjà fait tout le travail de calcul.
                    return QuestCheckbox(
                      label: '${suiteIndex + 1} - ${quest.name}',
                      value: quest.status == QuestStatus.completed,
                      isEnabled: quest.status != QuestStatus.locked,
                      onChanged: (newValue) {
                        // Le callback est simple, il passe juste les index.
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