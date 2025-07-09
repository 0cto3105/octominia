// lib/screens/game_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';

class GameSummaryScreen extends StatelessWidget {
  final Game game;
  final VoidCallback onSave;

  const GameSummaryScreen({super.key, required this.game, required this.onSave});

  // Fonctions d'aide pour la mise en page (INCHANGÉES)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
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
    // CORRECTION : Les calculs manuels sont supprimés.
    // On utilise directement les getters de l'objet Game.
    
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
            // CORRECTION ICI : Utilisation de game.totalMyScore
            _buildInfoRow(context, '${game.myPlayerName}:', game.totalMyScore.toString()),
            // CORRECTION ICI : Utilisation de game.totalOpponentScore
            _buildInfoRow(context, '${game.opponentPlayerName}:', game.totalOpponentScore.toString()),
            _buildInfoRow(context, 'Résultat de la Partie:', game.result.displayTitle),
            _buildInfoRow(context, 'Score /20:', game.scoreOutOf20.toString()), // Assure-toi que scoreOutOf20 est bien calculé et sauvegardé
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
                icon: const Icon(Icons.check),
                label: const Text('Finaliser la Partie'),
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