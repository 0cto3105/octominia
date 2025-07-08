// lib/screens/game_roll_offs_screen.dart
import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';

class GameRollOffsScreen extends StatefulWidget {
  final Game game;
  final Function(Game) onUpdate;

  const GameRollOffsScreen({super.key, required this.game, required this.onUpdate});

  @override
  State<GameRollOffsScreen> createState() => _GameRollOffsScreenState();
}

class _GameRollOffsScreenState extends State<GameRollOffsScreen> {
  String? _selectedAttacker;
  String? _selectedPriorityRound1;

  @override
  void initState() {
    super.initState();
    _selectedAttacker = widget.game.attackerPlayerId;
    _selectedPriorityRound1 = widget.game.priorityPlayerIdRound1;
  }

  void _updateGame() {
    widget.onUpdate(widget.game.copyWith(
      attackerPlayerId: _selectedAttacker,
      priorityPlayerIdRound1: _selectedPriorityRound1,
    ));
  }

  // --- NOUVELLE FONCTION D'AIDE POUR LES BOUTONS DE SÉLECTION ---
  Widget _buildPlayerSelectionButton({
    required String playerKey, // 'me' ou 'opponent'
    required String playerName, // Le nom du joueur à afficher
    required bool isSelected, // Si ce bouton est actuellement sélectionné
    required ValueChanged<String> onSelect, // Callback quand le bouton est cliqué
  }) {
    // Déterminez la couleur de fond et de texte en fonction de la sélection
    final Color backgroundColor = isSelected
        ? Theme.of(context).colorScheme.secondary // Couleur de sélection (par exemple, votre orange)
        : Theme.of(context).cardColor; // Couleur non sélectionnée (par exemple, la couleur des cartes)

    final Color textColor = isSelected
        ? Colors.black // Texte noir sur fond orange
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white; // Couleur de texte par défaut

    final Color borderColor = isSelected
        ? Theme.of(context).primaryColor // Bordure plus prononcée si sélectionné
        : Theme.of(context).dividerColor; // Une bordure subtile si non sélectionné

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // Espacement entre les boutons
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor, // Couleur du texte
            elevation: isSelected ? 4 : 1, // Ombre plus prononcée si sélectionné
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Bords légèrement arrondis
              side: BorderSide(
                color: borderColor,
                width: isSelected ? 2 : 1, // Épaisseur de la bordure
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8), // Padding interne du bouton
          ),
          child: Text(
            playerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Texte en gras si sélectionné
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
  // --- FIN DE LA NOUVELLE FONCTION D'AIDE ---


  @override
  Widget build(BuildContext context) {
    final String myPlayerName = widget.game.myPlayerName;
    final String opponentPlayerName = widget.game.opponentPlayerName;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roll Offs & Priorité',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
          ),
          const SizedBox(height: 20),

          // Qui est l'attaquant ?
          Text(
            'Qui est l\'attaquant ?',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 10), // Ajout d'un petit espace
          Row(
            children: [
              _buildPlayerSelectionButton(
                playerKey: 'me',
                playerName: myPlayerName,
                isSelected: _selectedAttacker == 'me',
                onSelect: (value) {
                  setState(() {
                    _selectedAttacker = value;
                    _updateGame();
                  });
                },
              ),
              _buildPlayerSelectionButton(
                playerKey: 'opponent',
                playerName: opponentPlayerName,
                isSelected: _selectedAttacker == 'opponent',
                onSelect: (value) {
                  setState(() {
                    _selectedAttacker = value;
                    _updateGame();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Qui a gagné la priorité pour le Tour 1 ?
          Text(
            'Qui a gagné la priorité pour le Tour 1 ?',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 10), // Ajout d'un petit espace
          Row(
            children: [
              _buildPlayerSelectionButton(
                playerKey: 'me',
                playerName: myPlayerName,
                isSelected: _selectedPriorityRound1 == 'me',
                onSelect: (value) {
                  setState(() {
                    _selectedPriorityRound1 = value;
                    _updateGame();
                  });
                },
              ),
              _buildPlayerSelectionButton(
                playerKey: 'opponent',
                playerName: opponentPlayerName,
                isSelected: _selectedPriorityRound1 == 'opponent',
                onSelect: (value) {
                  setState(() {
                    _selectedPriorityRound1 = value;
                    _updateGame();
                  });
                },
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}