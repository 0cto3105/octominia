// lib/screens/game_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/quest.dart';

class GameSummaryScreen extends StatelessWidget {
  final Game game;
  final VoidCallback onSave;

  const GameSummaryScreen({super.key, required this.game, required this.onSave});

  int? _getQuestCompletionRound(Quest questToFind, bool isMyPlayer, int suiteIndex) {
    for (int i = 0; i < game.rounds.length; i++) {
      final round = game.rounds[i];
      final List<Quest> questList = isMyPlayer
          ? (suiteIndex == 1 ? round.myQuestsSuite1 : round.myQuestsSuite2)
          : (suiteIndex == 1 ? round.opponentQuestsSuite1 : round.opponentQuestsSuite2);

      if (questList.length >= questToFind.id && questList[questToFind.id - 1].status == QuestStatus.completed) {
        if (i == 0) return i + 1;
        final previousRound = game.rounds[i-1];
        final List<Quest> previousQuestList = isMyPlayer
          ? (suiteIndex == 1 ? previousRound.myQuestsSuite1 : previousRound.myQuestsSuite2)
          : (suiteIndex == 1 ? previousRound.opponentQuestsSuite1 : previousRound.opponentQuestsSuite2);
        
        if(previousQuestList[questToFind.id - 1].status != QuestStatus.completed) {
          return i + 1;
        }
      }
    }
    return null;
  }

  Widget _buildScoreCell(String? text, {bool isCheck = false}) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: isCheck
            ? const Icon(Icons.check, color: Colors.green, size: 18)
            : Text(text ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildPriorityCell({required bool hasPriority}) {
    return Container(
      width: 32,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Center(
        child: hasPriority ? const Icon(Icons.check, color: Colors.green, size: 20) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color resultColor;
    switch (game.result) {
      case GameResult.victory: resultColor = Colors.green; break;
      case GameResult.defeat: resultColor = Colors.red; break;
      default: resultColor = Colors.amber;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMainScore(context, resultColor),
            const SizedBox(height: 16),
            _buildPlayerDetailCard(context, isMyPlayer: true),
            const SizedBox(height: 12),
            _buildPlayerDetailCard(context, isMyPlayer: false),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Age of Sigmar v4 • ${DateFormat('d MMMM yyyy').format(game.date)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
            if (game.gameState != GameState.completed)
              Center(
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Quit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScore(BuildContext context, Color resultColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            children: [
              Text(game.myPlayerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(game.myFactionName, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              Text('${game.totalMyScore} - ${game.totalOpponentScore}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              Text(game.result.displayTitle.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: resultColor)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(game.opponentPlayerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(game.opponentFactionName, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerDetailCard(BuildContext context, {required bool isMyPlayer}) {
    final String playerName = isMyPlayer ? game.myPlayerName : game.opponentPlayerName;
    final String? factionImageUrl = isMyPlayer ? game.myFactionImageUrl : game.opponentFactionImageUrl;
    
    final List<int> primaryScores = game.rounds.map((r) => isMyPlayer ? r.myScore : r.opponentScore).toList();
    final int primaryTotal = primaryScores.fold(0, (prev, element) => prev + element);
    
    final List<Quest> questSuite1 = isMyPlayer ? game.rounds.last.myQuestsSuite1 : game.rounds.last.opponentQuestsSuite1;
    final List<Quest> questSuite2 = isMyPlayer ? game.rounds.last.myQuestsSuite2 : game.rounds.last.opponentQuestsSuite2;
    
    final List<Quest> completedQuests1 = questSuite1.where((q) => q.status == QuestStatus.completed).toList();
    final List<Quest> completedQuests2 = questSuite2.where((q) => q.status == QuestStatus.completed).toList();
    final int secondaryTotal = (completedQuests1.length + completedQuests2.length) * 5;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          if (factionImageUrl != null && factionImageUrl.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(factionImageUrl, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playerName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 16),

                Row(
                  children: [
                    const Expanded(child: Text("Went First", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                    ...List.generate(5, (index) {
                      final priorityPlayer = game.rounds[index].priorityPlayerId;
                      return _buildPriorityCell(hasPriority: isMyPlayer ? (priorityPlayer == 'me') : (priorityPlayer == 'opponent'));
                    }),
                    SizedBox(
                      width: 50,
                      child: Text('Total', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Expanded(child: Text('Primary', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...List.generate(5, (index) => _buildScoreCell(primaryScores[index].toString())),
                    // MODIFIÉ: Ajout d'un espacement
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$primaryTotal / 50',
                        textAlign: TextAlign.center,
                        // MODIFIÉ: Police légèrement plus petite
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           if (completedQuests1.isEmpty && completedQuests2.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('No secondary point', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white38)),
                              ),

                          ...completedQuests1.map((quest) {
                              final completionRound = _getQuestCompletionRound(quest, isMyPlayer, 1);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Expanded(child: Text('1 - ${quest.name}', style: Theme.of(context).textTheme.bodyMedium)),
                                    ...List.generate(5, (index) => _buildScoreCell(null, isCheck: (index + 1) == completionRound)),
                                  ],
                                ),
                              );
                          }).toList(),

                          ...completedQuests2.map((quest) {
                              final completionRound = _getQuestCompletionRound(quest, isMyPlayer, 2);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Expanded(child: Text('2 - ${quest.name}', style: Theme.of(context).textTheme.bodyMedium)),
                                    ...List.generate(5, (index) => _buildScoreCell(null, isCheck: (index + 1) == completionRound)),
                                  ],
                                ),
                              );
                          }).toList(),
                        ],
                      ),
                    ),
                    // MODIFIÉ: Ajout d'un espacement
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$secondaryTotal / 40',
                        textAlign: TextAlign.center,
                        // MODIFIÉ: Police légèrement plus petite
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}