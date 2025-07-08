// lib/screens/game_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';

class GameSummaryScreen extends StatelessWidget {
  final Game game;
  final VoidCallback onSave;

  const GameSummaryScreen({super.key, required this.game, required this.onSave});

  // Fonctions d'aide pour la mise en page - Pass Context
  Widget _buildSectionTitle(BuildContext context, String title) { // context added
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) { // context added
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int myTotalScore = game.rounds.fold(0, (sum, round) => sum + round.myScore);
    final int opponentTotalScore = game.rounds.fold(0, (sum, round) => sum + round.opponentScore);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la Partie',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Informations Générales'), // context used
            _buildInfoRow(context, 'Date:', game.date.toLocal().toString().split(' ')[0]), // context used
            _buildInfoRow(context, 'Mon Nom:', game.myPlayerName), // context used
            _buildInfoRow(context, 'Ma Faction:', game.myFactionName), // context used
            _buildInfoRow(context, 'Mes Drops:', game.myDrops.toString()), // context used
            _buildInfoRow(context, 'Mes Auxiliaires:', game.myAuxiliaryUnits ? 'Oui' : 'Non'), // context used
            _buildInfoRow(context, 'Nom Opponent:', game.opponentPlayerName), // context used
            _buildInfoRow(context, 'Faction Opponent:', game.opponentFactionName), // context used
            _buildInfoRow(context, 'Drops Opponent:', game.opponentDrops.toString()), // context used
            _buildInfoRow(context, 'Auxiliaires Opponent:', game.opponentAuxiliaryUnits ? 'Oui' : 'Non'), // context used
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Roll Offs & Priorité'), // context used
            _buildInfoRow(
              context, // context used
              'Attaquant:',
              game.attackerPlayerId == 'me' ? game.myPlayerName : (game.attackerPlayerId == 'opponent' ? game.opponentPlayerName : 'Non défini'),
            ),
            _buildInfoRow(
              context, // context used
              'Priorité Tour 1:',
              game.priorityPlayerIdRound1 == 'me' ? game.myPlayerName : (game.priorityPlayerIdRound1 == 'opponent' ? game.opponentPlayerName : 'Non défini'),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Scores par Tour'), // context used
            ...game.rounds.map((round) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Tour ${round.roundNumber}: ${game.myPlayerName} ${round.myScore} - ${game.opponentPlayerName} ${round.opponentScore}',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Totaux et Résultat'), // context used
            _buildInfoRow(context, 'Score Total ${game.myPlayerName}:', myTotalScore.toString()), // context used
            _buildInfoRow(context, 'Score Total ${game.opponentPlayerName}:', opponentTotalScore.toString()), // context used
            _buildInfoRow(context, 'Résultat de la Partie:', game.result.isEmpty ? Game.determineResult(myTotalScore, opponentTotalScore) : game.result), // context used
            _buildInfoRow(context, 'Score /20:', game.scoreOutOf20.toString()), // context used
            const SizedBox(height: 30),

            if (game.notes != null && game.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Notes'), // context used
                  _buildInfoRow(context, 'Notes:', game.notes!), // context used
                  const SizedBox(height: 20),
                ],
              ),

            Center(
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder la Partie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}