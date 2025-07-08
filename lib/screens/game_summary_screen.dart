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

  // Fonction d'aide pour afficher les détails du tour
  Widget _buildRoundDetails(BuildContext context, Round round, String myPlayerName, String opponentPlayerName) {
    int myRoundTotal = round.calculatePlayerTotalScore(true);
    int opponentRoundTotal = round.calculatePlayerTotalScore(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Tour ${round.roundNumber}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
        _buildInfoRow(context, 'Priorité:', round.priorityPlayerId == 'me' ? myPlayerName : (round.priorityPlayerId == 'opponent' ? opponentPlayerName : 'Non défini')),
        _buildInfoRow(context, '$myPlayerName Score:', myRoundTotal.toString()),
        _buildInfoRow(context, '$opponentPlayerName Score:', opponentRoundTotal.toString()),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int myTotalScore = 0;
    int opponentTotalScore = 0;
    for (var round in game.rounds) {
      myTotalScore += round.calculatePlayerTotalScore(true);
      opponentTotalScore += round.calculatePlayerTotalScore(false);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Informations Générales'),
            _buildInfoRow(context, 'Date:', game.date.toLocal().toString().split(' ')[0]),
            _buildInfoRow(context, 'Mon Joueur:', '${game.myPlayerName} (${game.myFactionName})'),
            _buildInfoRow(context, 'Mon Score Total:', myTotalScore.toString()),
            _buildInfoRow(context, 'Adversaire:', '${game.opponentPlayerName} (${game.opponentFactionName})'),
            _buildInfoRow(context, 'Adversaire Score Total:', opponentTotalScore.toString()),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Détails des Tours'),
            ...game.rounds.map((round) => _buildRoundDetails(context, round, game.myPlayerName, game.opponentPlayerName)),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Résumé Final'),
            _buildInfoRow(context, '${game.myPlayerName}:', myTotalScore.toString()),
            _buildInfoRow(context, '${game.opponentPlayerName}:', opponentTotalScore.toString()),
            _buildInfoRow(context, 'Résultat de la Partie:', game.result.isEmpty ? Game.determineResult(myTotalScore, opponentTotalScore) : game.result),
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