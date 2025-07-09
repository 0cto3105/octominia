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
    // Calculez les scores totaux pour le résumé
    int myTotalScore = game.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(true));
    int opponentTotalScore = game.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(false));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Summary'),
        backgroundColor: Colors.amberAccent[200],
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Scores Finaux'),
            _buildInfoRow(context, '${game.myPlayerName}:', myTotalScore.toString()),
            _buildInfoRow(context, '${game.opponentPlayerName}:', opponentTotalScore.toString()),
            // Utiliser game.result.displayTitle pour afficher le résultat
            _buildInfoRow(context, 'Résultat de la Partie:', game.result.displayTitle), // MODIFICATION ICI
            _buildInfoRow(context, 'Score /20:', game.scoreOutOf20.toString()),
            const SizedBox(height: 30),

            if (game.notes != null && game.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Notes'),
                  _buildInfoRow(context, 'Notes:', game.notes!),
                  const SizedBox(height: 20),
                ],
              ),

            Center(
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check), // Icône changée pour 'check' (validation)
                label: const Text('Finaliser la Partie'), // TEXTE DU BOUTON CHANGÉ
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