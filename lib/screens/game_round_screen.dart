// lib/screens/game_round_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';

class GameRoundScreen extends StatefulWidget {
  final int roundNumber;
  final Game game;
  final Function(Round) onUpdateRound;

  const GameRoundScreen({
    super.key,
    required this.roundNumber,
    required this.game,
    required this.onUpdateRound,
  });

  @override
  State<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen> {
  late Round _currentRound;
  late String _myPlayerName;
  late String _opponentPlayerName;

  @override
  void initState() {
    super.initState();
    _myPlayerName = widget.game.myPlayerName;
    _opponentPlayerName = widget.game.opponentPlayerName;

    // Assurez-vous que _currentRound est une COPIE pour éviter les modifications directes
    // de l'objet Game parent si on ne veut pas qu'elles soient persistantes avant onUpdateRound.
    // Cependant, pour l'approche StatefulWidget, modifier _currentRound localement
    // puis appeler onUpdateRound pour propager est une bonne pratique.
    // Le Game contient déjà 3 rounds initialisés dans AddGameScreen, donc nous les trouvons.
    int roundIndex = widget.roundNumber - 1;
    if (widget.game.rounds.length > roundIndex) {
      _currentRound = widget.game.rounds[roundIndex];
    } else {
      // Ceci ne devrait pas arriver si AddGameScreen initialise toujours 3 rounds.
      // Mais pour la robustesse, on crée un Round vide.
      _currentRound = Round(
        roundNumber: widget.roundNumber,
        myScore: 0,
        opponentScore: 0,
        priorityPlayerId: null,
      );
    }
  }

  // Met à jour le Round actuel et informe le parent (AddGameScreen)
  void _updateCurrentRoundAndNotifyParent() {
    widget.onUpdateRound(_currentRound);
    setState(() {}); // Force rebuild to reflect changes
  }

  void _updatePriority(String? playerId) {
    _currentRound.priorityPlayerId = playerId;
    _updateCurrentRoundAndNotifyParent();
  }

  void _updatePrimaryScore(int? value, bool isMyPlayer) {
    if (value != null) {
      if (isMyPlayer) {
        _currentRound.myScore = value;
      } else {
        _currentRound.opponentScore = value;
      }
      _updateCurrentRoundAndNotifyParent();
    }
  }

  // Nouvelle fonction pour gérer la mise à jour des quêtes avec leur logique séquentielle
  void _updateQuestStatus(
    bool? value,
    bool isMyPlayer,
    int suiteNumber,
    int questNumber,
  ) {
    bool canUpdate = value ?? false; // True if attempting to check, false if attempting to uncheck

    setState(() {
      if (isMyPlayer) {
        if (suiteNumber == 1) {
          if (questNumber == 1) {
            _currentRound.myQuest1_1Completed = canUpdate;
            if (!canUpdate) { // Si on décoche la Q1, décocher aussi Q2 et Q3
              _currentRound.myQuest1_2Completed = false;
              _currentRound.myQuest1_3Completed = false;
            }
          } else if (questNumber == 2) {
            if (canUpdate && !_currentRound.myQuest1_1Completed) { // Ne peut cocher Q2 que si Q1 est cochée
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 1 de la Suite 1.')),
              );
              canUpdate = false; // Empêche de cocher
            }
            _currentRound.myQuest1_2Completed = canUpdate;
            if (!canUpdate) { // Si on décoche Q2, décocher aussi Q3
              _currentRound.myQuest1_3Completed = false;
            }
          } else if (questNumber == 3) {
            if (canUpdate && !_currentRound.myQuest1_2Completed) { // Ne peut cocher Q3 que si Q2 est cochée
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 2 de la Suite 1.')),
              );
              canUpdate = false; // Empêche de cocher
            }
            _currentRound.myQuest1_3Completed = canUpdate;
          }
        } else if (suiteNumber == 2) {
          if (questNumber == 1) {
            _currentRound.myQuest2_1Completed = canUpdate;
            if (!canUpdate) {
              _currentRound.myQuest2_2Completed = false;
              _currentRound.myQuest2_3Completed = false;
            }
          } else if (questNumber == 2) {
            if (canUpdate && !_currentRound.myQuest2_1Completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 1 de la Suite 2.')),
              );
              canUpdate = false;
            }
            _currentRound.myQuest2_2Completed = canUpdate;
            if (!canUpdate) {
              _currentRound.myQuest2_3Completed = false;
            }
          } else if (questNumber == 3) {
            if (canUpdate && !_currentRound.myQuest2_2Completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 2 de la Suite 2.')),
              );
              canUpdate = false;
            }
            _currentRound.myQuest2_3Completed = canUpdate;
          }
        }
      } else { // Opponent's quests
        if (suiteNumber == 1) {
          if (questNumber == 1) {
            _currentRound.opponentQuest1_1Completed = canUpdate;
            if (!canUpdate) {
              _currentRound.opponentQuest1_2Completed = false;
              _currentRound.opponentQuest1_3Completed = false;
            }
          } else if (questNumber == 2) {
            if (canUpdate && !_currentRound.opponentQuest1_1Completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 1 de la Suite 1 de l\'adversaire.')),
              );
              canUpdate = false;
            }
            _currentRound.opponentQuest1_2Completed = canUpdate;
            if (!canUpdate) {
              _currentRound.opponentQuest1_3Completed = false;
            }
          } else if (questNumber == 3) {
            if (canUpdate && !_currentRound.opponentQuest1_2Completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 2 de la Suite 1 de l\'adversaire.')),
              );
              canUpdate = false;
            }
            _currentRound.opponentQuest1_3Completed = canUpdate;
          }
        } else if (suiteNumber == 2) {
          if (questNumber == 1) {
            _currentRound.opponentQuest2_1Completed = canUpdate;
            if (!canUpdate) {
              _currentRound.opponentQuest2_2Completed = false;
              _currentRound.opponentQuest2_3Completed = false;
            }
          } else if (questNumber == 2) {
            if (canUpdate && !_currentRound.opponentQuest2_1Completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 1 de la Suite 2 de l\'adversaire.')),
              );
              canUpdate = false;
            }
            _currentRound.opponentQuest2_2Completed = canUpdate;
            if (!canUpdate) {
              _currentRound.opponentQuest2_3Completed = false;
            }
          } else if (questNumber == 3) {
            if (canUpdate && !_currentRound.opponentQuest2_2Completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez d\'abord valider la Quête 2 de la Suite 2 de l\'adversaire.')),
              );
              canUpdate = false;
            }
            _currentRound.opponentQuest2_3Completed = canUpdate;
          }
        }
      }
      _updateCurrentRoundAndNotifyParent();
    });
  }

  // Helper function to build the priority selection buttons (unchanged, as per previous fix)
  Widget _buildPrioritySelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Priorité du Tour ${widget.roundNumber}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updatePriority('me'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _currentRound.priorityPlayerId == 'me'
                      ? Theme.of(context).primaryColor // Selected color
                      : Colors.transparent, // Not selected color
                  side: BorderSide(
                    color: Theme.of(context).primaryColor, // Border color
                    width: _currentRound.priorityPlayerId == 'me' ? 2 : 1, // Thicker border when selected
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _myPlayerName,
                  style: TextStyle(
                    color: _currentRound.priorityPlayerId == 'me'
                        ? Colors.white // Text color when selected
                        : Theme.of(context).primaryColor, // Text color when not selected
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updatePriority('opponent'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _currentRound.priorityPlayerId == 'opponent'
                      ? Theme.of(context).primaryColor // Selected color
                      : Colors.transparent, // Not selected color
                  side: BorderSide(
                    color: Theme.of(context).primaryColor, // Border color
                    width: _currentRound.priorityPlayerId == 'opponent' ? 2 : 1, // Thicker border when selected
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _opponentPlayerName,
                  style: TextStyle(
                    color: _currentRound.priorityPlayerId == 'opponent'
                        ? Colors.white // Text color when selected
                        : Theme.of(context).primaryColor, // Text color when not selected
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper function for primary score selection
  Widget _buildPrimaryScoreSelection(BuildContext context, String playerName, int currentPrimaryScore, bool isMyPlayer) {
    List<int> scoreOptions = List.generate(11, (index) => index); // 0 to 10

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Score Primaire de $playerName (0-10)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: scoreOptions.map((score) {
            bool isSelected = currentPrimaryScore == score;
            return ChoiceChip(
              label: Text(score.toString()),
              selected: isSelected,
              selectedColor: Theme.of(context).primaryColor,
              onSelected: (selected) {
                if (selected) {
                  _updatePrimaryScore(score, isMyPlayer);
                }
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(color: Theme.of(context).primaryColor),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper function to build a single quest checkbox with dependencies
  Widget _buildQuestCheckbox({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required bool isEnabled,
  }) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isEnabled ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey,
        ),
      ),
      value: value,
      onChanged: isEnabled ? onChanged : null, // Disable if not enabled
      activeColor: Theme.of(context).primaryColor,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // Helper function to build quest sections for a player
  Widget _buildQuestSection(BuildContext context, String playerName, bool isMyPlayer) {
    // Determine current quest completion status for the player
    bool quest1_1 = isMyPlayer ? _currentRound.myQuest1_1Completed : _currentRound.opponentQuest1_1Completed;
    bool quest1_2 = isMyPlayer ? _currentRound.myQuest1_2Completed : _currentRound.opponentQuest1_2Completed;
    bool quest1_3 = isMyPlayer ? _currentRound.myQuest1_3Completed : _currentRound.opponentQuest1_3Completed;
    bool quest2_1 = isMyPlayer ? _currentRound.myQuest2_1Completed : _currentRound.opponentQuest2_1Completed;
    bool quest2_2 = isMyPlayer ? _currentRound.myQuest2_2Completed : _currentRound.opponentQuest2_2Completed;
    bool quest2_3 = isMyPlayer ? _currentRound.myQuest2_3Completed : _currentRound.opponentQuest2_3Completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Quêtes de $playerName (+5 points/quête)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),
        ),
        // Suite 1
        Text(
          'Suite 1',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        _buildQuestCheckbox(
          context: context,
          title: 'Quête 1.1',
          value: quest1_1,
          onChanged: (val) => _updateQuestStatus(val, isMyPlayer, 1, 1),
          isEnabled: true, // Toujours enabled pour la première quête
        ),
        _buildQuestCheckbox(
          context: context,
          title: 'Quête 1.2',
          value: quest1_2,
          onChanged: (val) => _updateQuestStatus(val, isMyPlayer, 1, 2),
          isEnabled: quest1_1, // Enabled si Quête 1.1 est complétée
        ),
        _buildQuestCheckbox(
          context: context,
          title: 'Quête 1.3',
          value: quest1_3,
          onChanged: (val) => _updateQuestStatus(val, isMyPlayer, 1, 3),
          isEnabled: quest1_2, // Enabled si Quête 1.2 est complétée
        ),
        const SizedBox(height: 16),

        // Suite 2
        Text(
          'Suite 2',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        _buildQuestCheckbox(
          context: context,
          title: 'Quête 2.1',
          value: quest2_1,
          onChanged: (val) => _updateQuestStatus(val, isMyPlayer, 2, 1),
          isEnabled: true, // Toujours enabled pour la première quête de la suite 2
        ),
        _buildQuestCheckbox(
          context: context,
          title: 'Quête 2.2',
          value: quest2_2,
          onChanged: (val) => _updateQuestStatus(val, isMyPlayer, 2, 2),
          isEnabled: quest2_1, // Enabled si Quête 2.1 est complétée
        ),
        _buildQuestCheckbox(
          context: context,
          title: 'Quête 2.3',
          value: quest2_3,
          onChanged: (val) => _updateQuestStatus(val, isMyPlayer, 2, 3),
          isEnabled: quest2_2, // Enabled si Quête 2.2 est complétée
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcul des scores totaux actuels (incluant les tours précédents)
    int myOverallTotalScore = widget.game.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(true));
    int opponentOverallTotalScore = widget.game.rounds.fold(0, (sum, round) => sum + round.calculatePlayerTotalScore(false));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Tour ${widget.roundNumber}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
              ),
            ),
            const SizedBox(height: 10),
            // Aperçu du Score Total Actuel
            Align(
              alignment: Alignment.center,
              child: Text(
                'Score Actuel: $_myPlayerName $myOverallTotalScore - $_opponentPlayerName $opponentOverallTotalScore',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            _buildPrioritySelection(context),
            const SizedBox(height: 20),

            // Section pour mon joueur
            _buildPrimaryScoreSelection(context, _myPlayerName, _currentRound.myScore, true),
            _buildQuestSection(context, _myPlayerName, true),

            // Section pour l'adversaire
            _buildPrimaryScoreSelection(context, _opponentPlayerName, _currentRound.opponentScore, false),
            _buildQuestSection(context, _opponentPlayerName, false),
          ],
        ),
      ),
    );
  }
}