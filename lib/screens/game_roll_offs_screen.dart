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
    // Set default priority for Round 1 to 'me' if not already set
    _selectedPriorityRound1 = widget.game.priorityPlayerIdRound1 ?? 'me'; 
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
    required ValueChanged<String> onSelect, // Callback quand le bouton est sélectionné
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: Text(playerName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utilisez les noms des joueurs de l'objet Game
    String myPlayerName = widget.game.myPlayerName;
    String opponentPlayerName = widget.game.opponentPlayerName;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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