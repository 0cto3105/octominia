// lib/screens/game_round_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';
import 'package:octominia/models/quest.dart';


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

    _currentRound = widget.game.rounds.firstWhere(
      (round) => round.roundNumber == widget.roundNumber,
    );

    // DÉFINIR 'me' COMME PRIORITÉ PAR DÉFAUT SI NULL
    if (_currentRound.priorityPlayerId == null) {
      _currentRound = _currentRound.copyWith(priorityPlayerId: 'me');
    }

    // DÉFINIR 'me' COMME JET D'INITIATIVE PAR DÉFAUT SI NULL
    if (_currentRound.initiativePlayerId == null) {
      _currentRound = _currentRound.copyWith(initiativePlayerId: 'me');
    }

    // Calculer les scores cumulés des rounds précédents pour le "Double Free Turn" et l'underdog initial
    int myTotalScorePreviousRounds = 0;
    int opponentTotalScorePreviousRounds = 0;
    String? actualUnderdogPlayerIdAcrossAllPreviousRounds; // Stocke l'underdog si défini par un double tour non gratuit précédent

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myTotalScorePreviousRounds += round.calculatePlayerTotalScore(true);
        opponentTotalScorePreviousRounds += round.calculatePlayerTotalScore(false);
        // Si un underdog a été désigné par un double tour non gratuit dans un round précédent, il persiste.
        if (round.underdogPlayerIdAtEndOfRound != null) {
          actualUnderdogPlayerIdAcrossAllPreviousRounds = round.underdogPlayerIdAtEndOfRound;
        }
      }
    }

    int scoreDifference = (myTotalScorePreviousRounds - opponentTotalScorePreviousRounds).abs();

    bool myPlayerMightHaveDoubleFreeTurnOpportunity = (myTotalScorePreviousRounds < opponentTotalScorePreviousRounds) && (scoreDifference >= 11);
    bool opponentPlayerMightHaveDoubleFreeTurnOpportunity = (opponentTotalScorePreviousRounds < myTotalScorePreviousRounds) && (scoreDifference >= 11);

    // Initialiser _currentRound avec les informations de double tour gratuit si elles ne sont pas déjà définies
    if (_currentRound.myPlayerHadDoubleFreeTurn == false && _currentRound.opponentPlayerHadDoubleFreeTurn == false) {
      _currentRound = _currentRound.copyWith(
        myPlayerHadDoubleFreeTurn: myPlayerMightHaveDoubleFreeTurnOpportunity,
        opponentPlayerHadDoubleFreeTurn: opponentPlayerMightHaveDoubleFreeTurnOpportunity,
      );
    }

    // Déterminer l'underdog initial du round
    String? calculatedUnderdogForThisRound;
    if (actualUnderdogPlayerIdAcrossAllPreviousRounds != null) {
      // Si un underdog a déjà été désigné par un double tour non gratuit dans un round précédent, il persiste.
      calculatedUnderdogForThisRound = actualUnderdogPlayerIdAcrossAllPreviousRounds;
    } else {
      // Sinon, on détermine l'underdog pour ce round basé sur la différence de score des rounds précédents
      if (myTotalScorePreviousRounds < opponentTotalScorePreviousRounds && scoreDifference >= 11) {
        calculatedUnderdogForThisRound = 'me';
      } else if (opponentTotalScorePreviousRounds < myTotalScorePreviousRounds && scoreDifference >= 11) {
        calculatedUnderdogForThisRound = 'opponent';
      }
    }
    
    _currentRound = _currentRound.copyWith(
      underdogPlayerIdAtEndOfRound: calculatedUnderdogForThisRound,
    );
  }

  void _updateRoundLocally(Round updatedRound) {
    setState(() {
      _currentRound = updatedRound;
    });
    // Appeler la fonction de mise à jour du parent pour persister le round
    widget.onUpdateRound(_currentRound);
  }

  void _updatePriority(String? playerKey) {
    String? previousRoundPriorityPlayerId;
    if (widget.roundNumber > 1) {
      final previousRound = widget.game.rounds.firstWhere(
        (round) => round.roundNumber == widget.roundNumber - 1,
        orElse: () => Round(roundNumber: 0, myScore: 0, opponentScore: 0), // Fallback pour éviter null
      );
      previousRoundPriorityPlayerId = previousRound.priorityPlayerId;
    }

    String? playerWhoWasSecondLastRound;
    if (previousRoundPriorityPlayerId != null) {
      if (previousRoundPriorityPlayerId == 'me') {
        playerWhoWasSecondLastRound = 'opponent';
      } else {
        playerWhoWasSecondLastRound = 'me';
      }
    }

    bool isDoubleTurnTriggered = false;
    if (_currentRound.initiativePlayerId != null &&
        playerKey != null && // new priority chosen
        _currentRound.initiativePlayerId == playerWhoWasSecondLastRound &&
        playerKey == playerWhoWasSecondLastRound) {
      isDoubleTurnTriggered = true;
    }

    // Récupérer l'opportunité de double tour gratuit depuis l'état persistant du round
    bool isCurrentPlayerDoubleFreeTurn = (playerKey == 'me' && _currentRound.myPlayerHadDoubleFreeTurn) ||
        (playerKey == 'opponent' && _currentRound.opponentPlayerHadDoubleFreeTurn);

    Round updatedRound = _currentRound;

    String? newUnderdogPlayerIdAtEndOfRound; // Va être recalculé dynamiquement
    bool newMyPlayerDidNonFreeDoubleTurn = false;
    bool newOpponentPlayerDidNonFreeDoubleTurn = false;

    // Calculer les scores cumulés incluant le round actuel (score primaire SEULEMENT)
    // Cela reflète l'état actuel pour la détermination dynamique de l'underdog.
    int myCurrentTotalScore = _currentRound.myScore;
    int opponentCurrentTotalScore = _currentRound.opponentScore;

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myCurrentTotalScore += round.calculatePlayerTotalScore(true);
        opponentCurrentTotalScore += round.calculatePlayerTotalScore(false);
      }
    }
    
    // Fonction utilitaire pour calculer l'underdog basé sur les scores actuels
    String? calculateUnderdogBasedOnCurrentScores() {
      int scoreDifferenceCurrent = (myCurrentTotalScore - opponentCurrentTotalScore).abs();
      if (myCurrentTotalScore < opponentCurrentTotalScore && scoreDifferenceCurrent >= 11) {
        return 'me';
      } else if (opponentCurrentTotalScore < myCurrentTotalScore && scoreDifferenceCurrent >= 11) {
        return 'opponent';
      }
      return null; // Pas d'underdog si pas de différence suffisante
    }

    // D'abord, vérifier si un underdog a été désigné par un double tour non gratuit dans un round précédent.
    // Cet état est "collant" et ne devrait être réinitialisé que par un nouveau double tour non gratuit.
    String? actualUnderdogPlayerIdAcrossAllPreviousRounds;
    if (widget.roundNumber > 1) {
      for (var round in widget.game.rounds) {
        if (round.roundNumber < widget.roundNumber && round.underdogPlayerIdAtEndOfRound != null) {
          actualUnderdogPlayerIdAcrossAllPreviousRounds = round.underdogPlayerIdAtEndOfRound;
          break; // Trouvé un underdog persistant, pas besoin de chercher plus loin.
        }
      }
    }


    if (isDoubleTurnTriggered) {
      if (!isCurrentPlayerDoubleFreeTurn) {
        // C'est un double tour NON gratuit : l'adversaire devient l'underdog pour le reste de la partie
        newMyPlayerDidNonFreeDoubleTurn = (playerKey == 'me');
        newOpponentPlayerDidNonFreeDoubleTurn = (playerKey == 'opponent');
        newUnderdogPlayerIdAtEndOfRound = (playerKey == 'me') ? 'opponent' : 'me';
      } else {
        // C'est un double tour GRATUIT : l'underdog est déterminé dynamiquement par les scores actuels
        // ou persiste si déjà défini par un double tour non gratuit passé.
        newMyPlayerDidNonFreeDoubleTurn = false;
        newOpponentPlayerDidNonFreeDoubleTurn = false;
        // Si un underdog était déjà désigné par un double tour non gratuit avant ce round, il persiste.
        // Sinon, on calcule basé sur les scores actuels (y compris le round en cours).
        newUnderdogPlayerIdAtEndOfRound = actualUnderdogPlayerIdAcrossAllPreviousRounds ?? calculateUnderdogBasedOnCurrentScores();
      }
    } else {
      // Ce n'est PAS un double tour : l'underdog est déterminé dynamiquement par les scores actuels
      // ou persiste si déjà défini par un double tour non gratuit passé.
      newMyPlayerDidNonFreeDoubleTurn = false;
      newOpponentPlayerDidNonFreeDoubleTurn = false;
      // Si un underdog était déjà désigné par un double tour non gratuit avant ce round, il persiste.
      // Sinon, on calcule basé sur les scores actuels (y compris le round en cours).
      newUnderdogPlayerIdAtEndOfRound = actualUnderdogPlayerIdAcrossAllPreviousRounds ?? calculateUnderdogBasedOnCurrentScores();
    }

    updatedRound = updatedRound.copyWith(
      priorityPlayerId: playerKey,
      myPlayerDidNonFreeDoubleTurn: newMyPlayerDidNonFreeDoubleTurn,
      opponentPlayerDidNonFreeDoubleTurn: newOpponentPlayerDidNonFreeDoubleTurn,
      underdogPlayerIdAtEndOfRound: newUnderdogPlayerIdAtEndOfRound,
    );

    _updateRoundLocally(updatedRound);
  }

  void _updateInitiative(String? playerKey) {
    // La mise à jour de l'initiative doit également potentiellement réévaluer l'underdog
    // car elle peut influencer la condition isDoubleTurnTriggered.
    // La façon la plus simple est de réappliquer la logique de _updatePriority
    // en gardant la même priorité (playerKey) mais en mettant à jour l'initiative.
    // Pour cela, nous appelons _updatePriority après avoir mis à jour l'initiative
    // ou nous intégrons la logique de l'underdog directement ici ou dans une fonction commune.
    // Pour l'instant, on se contente de mettre à jour l'initiative et de laisser _updatePriority
    // gérer l'underdog quand la priorité change. Si l'utilisateur change d'abord l'initiative,
    // puis la priorité, cela sera correct.
    setState(() {
      _currentRound = _currentRound.copyWith(initiativePlayerId: playerKey);
      // Après avoir mis à jour l'initiative, nous devons forcer une réévaluation de l'underdog
      // et des drapeaux de double tour, car cela peut changer la situation sans que la priorité ne change.
      // Appelons une fonction de recalcul qui mettra à jour l'état du round.
      _recalculateUnderdogAndDoubleTurnFlags();
    });
    // Appeler la fonction de mise à jour du parent pour persister le round
    widget.onUpdateRound(_currentRound);
  }

  // Nouvelle fonction pour recalculer l'underdog et les drapeaux de double tour
  // Utilisée après les mises à jour d'initiative ou de score.
  void _recalculateUnderdogAndDoubleTurnFlags() {
    // Recalculer les scores cumulés incluant le round actuel (score primaire SEULEMENT)
    int myCurrentTotalScore = _currentRound.myScore;
    int opponentCurrentTotalScore = _currentRound.opponentScore;

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myCurrentTotalScore += round.calculatePlayerTotalScore(true);
        opponentCurrentTotalScore += round.calculatePlayerTotalScore(false);
      }
    }

    // Fonction utilitaire pour calculer l'underdog basé sur les scores actuels
    String? calculateUnderdogBasedOnCurrentScores() {
      int scoreDifferenceCurrent = (myCurrentTotalScore - opponentCurrentTotalScore).abs();
      if (myCurrentTotalScore < opponentCurrentTotalScore && scoreDifferenceCurrent >= 11) {
        return 'me';
      } else if (opponentCurrentTotalScore < myCurrentTotalScore && scoreDifferenceCurrent >= 11) {
        return 'opponent';
      }
      return null;
    }

    // Première détermination de l'underdog du round à partir de l'historique
    String? actualUnderdogPlayerIdAcrossAllPreviousRounds;
    if (widget.roundNumber > 1) {
      for (var round in widget.game.rounds) {
        if (round.roundNumber < widget.roundNumber && round.underdogPlayerIdAtEndOfRound != null) {
          actualUnderdogPlayerIdAcrossAllPreviousRounds = round.underdogPlayerIdAtEndOfRound;
          break;
        }
      }
    }

    // Déterminer si un double tour est déclenché par les choix actuels (initiative + priorité)
    String? playerWhoWasSecondLastRound;
    if (widget.roundNumber > 1) {
      final previousRound = widget.game.rounds.firstWhere(
            (round) => round.roundNumber == widget.roundNumber - 1,
        orElse: () => Round(roundNumber: 0, myScore: 0, opponentScore: 0),
      );
      if (previousRound.priorityPlayerId != null) {
        playerWhoWasSecondLastRound = (previousRound.priorityPlayerId == 'me') ? 'opponent' : 'me';
      }
    }

    bool isDoubleTurnTriggered = false;
    if (_currentRound.initiativePlayerId != null &&
        _currentRound.priorityPlayerId != null &&
        playerWhoWasSecondLastRound != null &&
        _currentRound.initiativePlayerId == playerWhoWasSecondLastRound &&
        _currentRound.priorityPlayerId == playerWhoWasSecondLastRound) {
      isDoubleTurnTriggered = true;
    }

    // Récupérer l'opportunité de double tour gratuit depuis l'état persistant du round
    bool isCurrentPlayerDoubleFreeTurn = ((_currentRound.priorityPlayerId == 'me' && _currentRound.myPlayerHadDoubleFreeTurn) ||
        (_currentRound.priorityPlayerId == 'opponent' && _currentRound.opponentPlayerHadDoubleFreeTurn));
    
    String? newUnderdogPlayerIdAtEndOfRound;
    bool newMyPlayerDidNonFreeDoubleTurn = false;
    bool newOpponentPlayerDidNonFreeDoubleTurn = false;


    if (isDoubleTurnTriggered) {
      if (!isCurrentPlayerDoubleFreeTurn) {
        // C'est un double tour NON gratuit
        newMyPlayerDidNonFreeDoubleTurn = (_currentRound.priorityPlayerId == 'me');
        newOpponentPlayerDidNonFreeDoubleTurn = (_currentRound.priorityPlayerId == 'opponent');
        newUnderdogPlayerIdAtEndOfRound = (_currentRound.priorityPlayerId == 'me') ? 'opponent' : 'me';
      } else {
        // C'est un double tour GRATUIT. L'underdog est déterminé par les scores actuels ou celui d'avant
        newMyPlayerDidNonFreeDoubleTurn = false;
        newOpponentPlayerDidNonFreeDoubleTurn = false;
        newUnderdogPlayerIdAtEndOfRound = actualUnderdogPlayerIdAcrossAllPreviousRounds ?? calculateUnderdogBasedOnCurrentScores();
      }
    } else {
      // Ce n'est PAS un double tour. L'underdog est déterminé par les scores actuels ou celui d'avant
      newMyPlayerDidNonFreeDoubleTurn = false;
      newOpponentPlayerDidNonFreeDoubleTurn = false;
      newUnderdogPlayerIdAtEndOfRound = actualUnderdogPlayerIdAcrossAllPreviousRounds ?? calculateUnderdogBasedOnCurrentScores();
    }
    
    _currentRound = _currentRound.copyWith(
      myPlayerDidNonFreeDoubleTurn: newMyPlayerDidNonFreeDoubleTurn,
      opponentPlayerDidNonFreeDoubleTurn: newOpponentPlayerDidNonFreeDoubleTurn,
      underdogPlayerIdAtEndOfRound: newUnderdogPlayerIdAtEndOfRound,
    );
  }

  void _updatePrimaryScore(int newScore, bool isMyPlayer) {
    setState(() {
      _currentRound = isMyPlayer
          ? _currentRound.copyWith(myScore: newScore)
          : _currentRound.copyWith(opponentScore: newScore);
      // Après avoir mis à jour le score primaire, recalculer l'underdog et les drapeaux de double tour
      _recalculateUnderdogAndDoubleTurnFlags();
    });
    widget.onUpdateRound(_currentRound);
  }

  // Helper method to get the correct quest list based on player and suite
  List<Quest> _getQuestSuite(bool isMyPlayer, int suiteIndex) {
    if (isMyPlayer) {
      return (suiteIndex == 1) ? _currentRound.myQuestsSuite1 : _currentRound.myQuestsSuite2;
    } else {
      return (suiteIndex == 1) ? _currentRound.opponentQuestsSuite1 : _currentRound.opponentQuestsSuite2;
    }
  }

  // Helper method to get the index of a quest within its suite based on its key
  int _getQuestIndexFromKey(String questKey) {
    if (questKey.endsWith('1_1Completed') || questKey.endsWith('2_1Completed')) {
      return 0;
    } else if (questKey.endsWith('1_2Completed') || questKey.endsWith('2_2Completed')) {
      return 1;
    } else if (questKey.endsWith('1_3Completed') || questKey.endsWith('2_3Completed')) {
      return 2;
    }
    return -1; // Should not happen
  }

  // Helper method to get the suite index from a quest key
  int _getSuiteIndexFromKey(String questKey) {
    if (questKey.contains('1_')) {
      return 1;
    } else if (questKey.contains('2_')) {
      return 2;
    }
    return -1; // Should not happen
  }


  void _updateQuest(String questKey, bool value, bool isMyPlayer) {
    final int suiteIndex = _getSuiteIndexFromKey(questKey);
    final int questIndex = _getQuestIndexFromKey(questKey);

    if (suiteIndex == -1 || questIndex == -1) {
      return; // Invalid quest key
    }

    bool questUpdated = false;

    if (value) { // Si on veut cocher la quête
      questUpdated = _currentRound.completeQuest(isMyPlayer, suiteIndex, questIndex);
      if (!questUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez compléter la quête précédente d\'abord.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else { // Si on veut décocher la quête
      questUpdated = _currentRound.uncompleteQuest(isMyPlayer, suiteIndex, questIndex);
      if (!questUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord désactiver les quêtes suivantes.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    if (questUpdated) {
      _updateRoundLocally(_currentRound);
    }
  }


  // --- Widgets pour l'interface utilisateur ---

  // MODIFIÉ : Nouvelle version de _buildPlayerSelectionButton pour un meilleur style
  Widget _buildPlayerSelectionButton({
    required String playerKey,
    required String playerName,
    required bool isSelected,
    required Function(String) onSelect,
    double fontSize = 14,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 8),
  }) {
    String trigram = playerName.length >= 3 ? playerName.substring(0, 3).toUpperCase() : playerName.toUpperCase();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor // Couleur de fond si sélectionné
                : Theme.of(context).cardColor, // Couleur de fond par défaut (similaire à la couleur de la carte)
            foregroundColor: isSelected
                ? Colors.white // Couleur du texte si sélectionné
                : Theme.of(context).colorScheme.onSurface, // Couleur du texte par défaut
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor // Bordure de la couleur primaire si sélectionné
                  : Colors.grey.shade400, // Bordure grise pour non sélectionné
              width: 1,
            ),
            padding: padding,
            textStyle: TextStyle(fontSize: fontSize, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            minimumSize: const Size(0, 36), // Hauteur minimale pour la cohérence
            elevation: isSelected ? 4 : 0, // Élévation pour le bouton sélectionné
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Bords légèrement arrondis
          ),
          child: Text(trigram),
        ),
      ),
    );
  }

  // Widget pour l'affichage de l'initiative
  Widget _buildInitiativeRow(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80, // Largeur fixe pour le libellé
          child: Text(
            'Initiative',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'me',
          playerName: _myPlayerName,
          isSelected: _currentRound.initiativePlayerId == 'me',
          onSelect: _updateInitiative,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'opponent',
          playerName: _opponentPlayerName,
          isSelected: _currentRound.initiativePlayerId == 'opponent',
          onSelect: _updateInitiative,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }

  // Widget pour l'affichage de la priorité
  Widget _buildPriorityRow(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80, // Largeur fixe pour le libellé
          child: Text(
            'Priorité',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'me',
          playerName: _myPlayerName,
          isSelected: _currentRound.priorityPlayerId == 'me',
          onSelect: _updatePriority,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
        _buildPlayerSelectionButton(
          playerKey: 'opponent',
          playerName: _opponentPlayerName,
          isSelected: _currentRound.priorityPlayerId == 'opponent',
          onSelect: _updatePriority,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }

  // Helper method to build the primary score slider and display its value
  Widget _buildPrimaryScoreSlider(BuildContext context, int currentScore, bool isMyPlayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Primaire',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
        Row(
          children: [
            // Affichage du chiffre à gauche du slider
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                currentScore.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: currentScore.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: currentScore.toString(),
                onChanged: (double value) {
                  _updatePrimaryScore(value.round(), isMyPlayer);
                },
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Modified to accept isEnabled
  Widget _buildQuestCheckbox(String label, bool value, Function(bool)? onChanged, {required bool isEnabled}) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: isEnabled
              ? (bool? newValue) {
            if (onChanged != null) {
              onChanged(newValue ?? false);
            }
          }
              : null,
          checkColor: Colors.white,
          activeColor: Theme.of(context).primaryColor,
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isEnabled
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ],
    );
  }

  // Helper pour vérifier si une quête est complétée dans le tour actuel ou les précédents
  bool _isQuestActuallyCompleted(bool isMyPlayer, int suiteIndex, int questIndex) {
    final List<Quest> targetSuite = _getQuestSuite(isMyPlayer, suiteIndex);
    if (questIndex < 0 || questIndex >= targetSuite.length) return false;

    // Check current round status
    if (targetSuite[questIndex].status == QuestStatus.completed) {
      return true;
    }

    // Check previous rounds status
    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        final List<Quest> previousRoundSuite = isMyPlayer
            ? ((suiteIndex == 1) ? round.myQuestsSuite1 : round.myQuestsSuite2)
            : ((suiteIndex == 1) ? round.opponentQuestsSuite1 : round.opponentQuestsSuite2);
        if (questIndex < previousRoundSuite.length && previousRoundSuite[questIndex].status == QuestStatus.completed) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildQuestSection(BuildContext context, bool isMyPlayer) {
    // Déterminer si les quêtes sont désactivées pour ce joueur à cause d'un double tour non gratuit
    bool disableQuestsGlobally = (isMyPlayer && _currentRound.myPlayerDidNonFreeDoubleTurn) ||
        (!isMyPlayer && _currentRound.opponentPlayerDidNonFreeDoubleTurn);

    // Fonction pour déterminer si une quête est activée
    bool _isQuestEnabled(int suiteIndex, int questIndex) {
      if (disableQuestsGlobally) return false;

      final List<Quest> targetSuite = _getQuestSuite(isMyPlayer, suiteIndex);
      if (questIndex < 0 || questIndex >= targetSuite.length) return false;

      final Quest currentQuest = targetSuite[questIndex];

      // Une quête est activée si elle est "unlocked"
      bool isUnlocked = currentQuest.status == QuestStatus.unlocked;
      // Ou si elle est "completed" (pour permettre de la décocher si nécessaire)
      bool isCompleted = currentQuest.status == QuestStatus.completed;

      // Si c'est la première quête de la suite (index 0), elle est débloquée par défaut au début du round
      // et elle est toujours activable si elle n'est pas déjà complétée dans les tours précédents.
      if (questIndex == 0) {
        return (isUnlocked || isCompleted);
      } else {
        // Pour les quêtes suivantes, elles dépendent de la complétion de la quête précédente
        final bool previousQuestCompleted = _isQuestActuallyCompleted(isMyPlayer, suiteIndex, questIndex - 1);
        return (previousQuestCompleted && (isUnlocked || isCompleted));
      }
    }

    List<Quest> myQuestsSuite1 = _currentRound.myQuestsSuite1;
    List<Quest> myQuestsSuite2 = _currentRound.myQuestsSuite2;
    List<Quest> opponentQuestsSuite1 = _currentRound.opponentQuestsSuite1;
    List<Quest> opponentQuestsSuite2 = _currentRound.opponentQuestsSuite2;

    List<Quest> currentPlayersQuestsSuite1 = isMyPlayer ? myQuestsSuite1 : opponentQuestsSuite1;
    List<Quest> currentPlayersQuestsSuite2 = isMyPlayer ? myQuestsSuite2 : opponentQuestsSuite2;


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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Groupe de Quêtes 1
                  ...List.generate(currentPlayersQuestsSuite1.length, (index) {
                    final quest = currentPlayersQuestsSuite1[index];
                    return _buildQuestCheckbox(
                      '1 - ${quest.name}',
                      quest.status == QuestStatus.completed,
                      (newValue) => _updateQuest(
                          (isMyPlayer ? 'myQuest' : 'opponentQuest') + '1_' + (index + 1).toString() + 'Completed',
                          newValue,
                          isMyPlayer),
                      isEnabled: _isQuestEnabled(1, index),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Groupe de Quêtes 2
                  ...List.generate(currentPlayersQuestsSuite2.length, (index) {
                    final quest = currentPlayersQuestsSuite2[index];
                    return _buildQuestCheckbox(
                      '2 - ${quest.name}',
                      quest.status == QuestStatus.completed,
                      (newValue) => _updateQuest(
                          (isMyPlayer ? 'myQuest' : 'opponentQuest') + '2_' + (index + 1).toString() + 'Completed',
                          newValue,
                          isMyPlayer),
                      isEnabled: _isQuestEnabled(2, index),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerScoreCard(BuildContext context, String playerName, bool isMyPlayer, int myTotalScorePreviousRounds, int opponentTotalScorePreviousRounds) {
    // Calculer le joueur qui était second au round précédent pour déterminer le double tour
    String? previousRoundPriorityPlayerId;
    if (widget.roundNumber > 1) {
      final previousRound = widget.game.rounds.firstWhere(
            (round) => round.roundNumber == widget.roundNumber - 1,
        orElse: () => Round(roundNumber: 0, myScore: 0, opponentScore: 0),
      );
      previousRoundPriorityPlayerId = previousRound.priorityPlayerId;
    }

    String? playerWhoWasSecondLastRound;
    if (previousRoundPriorityPlayerId != null) {
      if (previousRoundPriorityPlayerId == 'me') {
        playerWhoWasSecondLastRound = 'opponent';
      } else {
        playerWhoWasSecondLastRound = 'me';
      }
    }

    // Déterminer si un double tour est déclenché par les choix actuels (initiative + priorité)
    bool isDoubleTurnTriggeredByCurrentChoice = false;
    if (_currentRound.initiativePlayerId != null &&
        _currentRound.priorityPlayerId != null &&
        _currentRound.initiativePlayerId == playerWhoWasSecondLastRound &&
        _currentRound.priorityPlayerId == playerWhoWasSecondLastRound &&
        ((isMyPlayer && _currentRound.priorityPlayerId == 'me') || (!isMyPlayer && _currentRound.priorityPlayerId == 'opponent'))
    ) {
      isDoubleTurnTriggeredByCurrentChoice = true;
    }

    // Déterminer si le joueur est l'underdog pour ce round
    bool isUnderdogForRound = (isMyPlayer && _currentRound.underdogPlayerIdAtEndOfRound == 'me') || (!isMyPlayer && _currentRound.underdogPlayerIdAtEndOfRound == 'opponent');

    // Déterminer si le joueur a l'OPPORTUNITÉ d'un double tour gratuit (basé sur les scores passés)
    bool isDoubleFreeTurnOpportunity = ((isMyPlayer && _currentRound.myPlayerHadDoubleFreeTurn) || (!isMyPlayer && _currentRound.opponentPlayerHadDoubleFreeTurn));
    
    // Déterminer si la pastille "Double Free Turn" doit être affichée (opportunité + déclenché)
    bool showDoubleFreeTurnBadge = isDoubleFreeTurnOpportunity && isDoubleTurnTriggeredByCurrentChoice;

    // Déterminer si la pastille "Going for a Double Turn" doit être affichée (déclenché mais pas gratuit)
    bool showGoingForDoubleTurnBadge = isDoubleTurnTriggeredByCurrentChoice && !isDoubleFreeTurnOpportunity;


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow, // Couleur pour le nom du joueur
                  ),
                ),
                const SizedBox(width: 8),
                // Logique d'affichage des badges par ordre de priorité
                 if (showDoubleFreeTurnBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent, // Couleur spécifique pour "Double Free Turn"
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  'Double Free Turn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (showGoingForDoubleTurnBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple, // Couleur spécifique pour "Going for a Double Turn"
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Going for a Double Turn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isUnderdogForRound) // Cette ligne a été déplacée pour changer la priorité
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey, // Couleur pour "Underdog"
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Underdog',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ],
            ),
            const SizedBox(height: 10),

            _buildPrimaryScoreSlider(
                context,
                isMyPlayer ? _currentRound.myScore : _currentRound.opponentScore,
                isMyPlayer),
            const SizedBox(height: 20),
            _buildQuestSection(context, isMyPlayer),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Les scores cumulés des rounds précédents sont toujours calculés dynamiquement pour l'affichage
    // et pour déterminer les opportunités de quêtes basées sur l'historique
    int myTotalScorePreviousRounds = 0;
    int opponentTotalScorePreviousRounds = 0;

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myTotalScorePreviousRounds += round.calculatePlayerTotalScore(true);
        opponentTotalScorePreviousRounds += round.calculatePlayerTotalScore(false);
      }
    }

    Widget myPlayerCard = _buildPlayerScoreCard(context, _myPlayerName, true, myTotalScorePreviousRounds, opponentTotalScorePreviousRounds);
    Widget opponentPlayerCard = _buildPlayerScoreCard(context, _opponentPlayerName, false, myTotalScorePreviousRounds, opponentTotalScorePreviousRounds);

    List<Widget> orderedPlayerCards = [];
    if (_currentRound.priorityPlayerId == 'me') {
      orderedPlayerCards.add(myPlayerCard);
      orderedPlayerCards.add(opponentPlayerCard);
    } else if (_currentRound.priorityPlayerId == 'opponent') {
      orderedPlayerCards.add(opponentPlayerCard);
      orderedPlayerCards.add(myPlayerCard);
    } else {
      orderedPlayerCards.add(myPlayerCard);
      orderedPlayerCards.add(opponentPlayerCard);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Jet d'initiative sur une ligne
              _buildInitiativeRow(context),
              const SizedBox(height: 10), // Petit espace entre les deux lignes

              // Priorité du tour sur une autre ligne
              _buildPriorityRow(context),
              const SizedBox(height: 20), // Espace avant les cartes de joueur

              ...orderedPlayerCards,
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}