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

  Widget _buildPlayerSelectionButton({
    required String playerKey,
    required String playerName,
    required bool isSelected,
    required ValueChanged<String?> onSelect,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
            foregroundColor: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
            side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400),
          ),
          child: Text(playerName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String myPlayerName = widget.game.myPlayerName;
    String opponentPlayerName = widget.game.opponentPlayerName;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who is the attacker',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPlayerSelectionButton(
                playerKey: 'me',
                playerName: myPlayerName,
                isSelected: _selectedAttacker == 'me',
                onSelect: (value) {
                  setState(() {
                    _selectedAttacker = value;
                    if (_selectedPriorityRound1 == null) {
                      _selectedPriorityRound1 = value;
                    }
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
                    if (_selectedPriorityRound1 == null) {
                      _selectedPriorityRound1 = value;
                    }
                    _updateGame();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          Text(
            'Who went first this battle round?',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 10),
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