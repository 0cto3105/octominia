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

  void _updateQuest(String questKey, bool value, bool isMyPlayer) {
    // Si l'utilisateur tente de décocher une quête
    if (!value) {
      bool canUncheck = true; // Par défaut, on peut décocher
      if (isMyPlayer) {
        // Logique pour les quêtes du joueur : empêcher de décocher si une quête suivante est cochée DANS CE ROUND
        if (questKey == 'myQuest1_2Completed' && _currentRound.myQuest1_3Completed) canUncheck = false;
        if (questKey == 'myQuest1_1Completed' && (_currentRound.myQuest1_2Completed || _currentRound.myQuest1_3Completed)) canUncheck = false;
        if (questKey == 'myQuest2_2Completed' && _currentRound.myQuest2_3Completed) canUncheck = false;
        if (questKey == 'myQuest2_1Completed' && (_currentRound.myQuest2_2Completed || _currentRound.myQuest2_3Completed)) canUncheck = false;
      } else {
        // Logique pour les quêtes de l'adversaire
        if (questKey == 'opponentQuest1_2Completed' && _currentRound.opponentQuest1_3Completed) canUncheck = false;
        if (questKey == 'opponentQuest1_1Completed' && (_currentRound.opponentQuest1_2Completed || _currentRound.opponentQuest1_3Completed)) canUncheck = false;
        if (questKey == 'opponentQuest2_2Completed' && _currentRound.opponentQuest2_3Completed) canUncheck = false;
        if (questKey == 'opponentQuest2_1Completed' && (_currentRound.opponentQuest2_2Completed || _currentRound.opponentQuest2_3Completed)) canUncheck = false;
      }

      if (!canUncheck) {
        // Afficher un message à l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord désactiver les quêtes suivantes.'),
            duration: Duration(seconds: 2),
          ),
        );
        return; // Empêche la mise à jour si le décheck est invalide
      }
    }

    Round updatedRound = _currentRound;
    if (isMyPlayer) {
      switch (questKey) {
        case 'myQuest1_1Completed':
          updatedRound = updatedRound.copyWith(myQuest1_1Completed: value);
          break;
        case 'myQuest1_2Completed':
          updatedRound = updatedRound.copyWith(myQuest1_2Completed: value);
          break;
        case 'myQuest1_3Completed':
          updatedRound = updatedRound.copyWith(myQuest1_3Completed: value);
          break;
        case 'myQuest2_1Completed':
          updatedRound = updatedRound.copyWith(myQuest2_1Completed: value);
          break;
        case 'myQuest2_2Completed':
          updatedRound = updatedRound.copyWith(myQuest2_2Completed: value);
          break;
        case 'myQuest2_3Completed':
          updatedRound = updatedRound.copyWith(myQuest2_3Completed: value);
          break;
      }
    } else {
      switch (questKey) {
        case 'opponentQuest1_1Completed':
          updatedRound = updatedRound.copyWith(opponentQuest1_1Completed: value);
          break;
        case 'opponentQuest1_2Completed':
          updatedRound = updatedRound.copyWith(opponentQuest1_2Completed: value);
          break;
        case 'opponentQuest1_3Completed':
          updatedRound = updatedRound.copyWith(opponentQuest1_3Completed: value);
          break;
        case 'opponentQuest2_1Completed':
          updatedRound = updatedRound.copyWith(opponentQuest2_1Completed: value);
          break;
        case 'opponentQuest2_2Completed':
          updatedRound = updatedRound.copyWith(opponentQuest2_2Completed: value);
          break;
        case 'opponentQuest2_3Completed':
          updatedRound = updatedRound.copyWith(opponentQuest2_3Completed: value);
          break;
      }
    }
    _updateRoundLocally(updatedRound);
  }

  // --- Widgets pour l'interface utilisateur ---

  // Nouvelle version de _buildPlayerSelectionButton avec plus d'options de customisation
  Widget _buildPlayerSelectionButton({
    required String playerKey,
    required String playerName,
    required bool isSelected,
    required Function(String) onSelect,
    double fontSize = 14,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 8),
  }) {
    // Utilise les trois premières lettres en majuscules pour le trigramme
    String trigram = playerName.length >= 3 ? playerName.substring(0, 3).toUpperCase() : playerName.toUpperCase();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ElevatedButton(
          onPressed: () => onSelect(playerKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
            foregroundColor: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            padding: padding,
            textStyle: TextStyle(fontSize: fontSize),
            minimumSize: const Size(0, 36), // Hauteur minimale pour la cohérence
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

  // Nouvelle fonction pour vérifier si une quête a été complétée dans un des tours précédents
  bool _wasQuestCompletedInAnyPreviousRound(String questKey, bool isMyPlayer) {
    return widget.game.rounds.any((round) {
      if (round.roundNumber < widget.roundNumber) { // Checks only previous rounds
        if (isMyPlayer) {
          switch (questKey) {
            case 'myQuest1_1Completed': return round.myQuest1_1Completed;
            case 'myQuest1_2Completed': return round.myQuest1_2Completed;
            case 'myQuest1_3Completed': return round.myQuest1_3Completed;
            case 'myQuest2_1Completed': return round.myQuest2_1Completed;
            case 'myQuest2_2Completed': return round.myQuest2_2Completed;
            case 'myQuest2_3Completed': return round.myQuest2_3Completed;
          }
        } else {
          switch (questKey) {
            case 'opponentQuest1_1Completed': return round.opponentQuest1_1Completed;
            case 'opponentQuest1_2Completed': return round.opponentQuest1_2Completed;
            case 'opponentQuest1_3Completed': return round.opponentQuest1_3Completed;
            case 'opponentQuest2_1Completed': return round.opponentQuest2_1Completed;
            case 'opponentQuest2_2Completed': return round.opponentQuest2_2Completed;
            case 'opponentQuest2_3Completed': return round.opponentQuest2_3Completed;
          }
        }
      }
      return false;
    });
  }

  // Helper pour vérifier si une quête est complétée dans le tour actuel ou les précédents
  bool _isQuestActuallyCompleted(String questKey, bool isMyPlayer) {
    bool completedInCurrent = false;
    if (isMyPlayer) {
      switch (questKey) {
        case 'myQuest1_1Completed': completedInCurrent = _currentRound.myQuest1_1Completed; break;
        case 'myQuest1_2Completed': completedInCurrent = _currentRound.myQuest1_2Completed; break;;
        case 'myQuest1_3Completed': completedInCurrent = _currentRound.myQuest1_3Completed; break;
        case 'myQuest2_1Completed': completedInCurrent = _currentRound.myQuest2_1Completed; break;
        case 'myQuest2_2Completed': completedInCurrent = _currentRound.myQuest2_2Completed; break;
        case 'myQuest2_3Completed': completedInCurrent = _currentRound.myQuest2_3Completed; break;
      }
    } else {
      switch (questKey) {
        case 'opponentQuest1_1Completed': completedInCurrent = _currentRound.opponentQuest1_1Completed; break;
        case 'opponentQuest1_2Completed': completedInCurrent = _currentRound.opponentQuest1_2Completed; break;
        case 'opponentQuest1_3Completed': completedInCurrent = _currentRound.opponentQuest1_3Completed; break;
        case 'opponentQuest2_1Completed': completedInCurrent = _currentRound.opponentQuest2_1Completed; break;
        case 'opponentQuest2_2Completed': completedInCurrent = _currentRound.opponentQuest2_2Completed; break;
        case 'opponentQuest2_3Completed': completedInCurrent = _currentRound.opponentQuest2_3Completed; break;
      }
    }
    return completedInCurrent || _wasQuestCompletedInAnyPreviousRound(questKey, isMyPlayer);
  }

  Widget _buildQuestSection(BuildContext context, bool isMyPlayer) {
    // Déterminer si les quêtes sont désactivées pour ce joueur à cause d'un double tour non gratuit
    bool disableQuestsGlobally = (isMyPlayer && _currentRound.myPlayerDidNonFreeDoubleTurn) ||
        (!isMyPlayer && _currentRound.opponentPlayerDidNonFreeDoubleTurn);

    // --- Suite 1 ---
    String quest1_1Key = isMyPlayer ? 'myQuest1_1Completed' : 'opponentQuest1_1Completed';
    bool quest1_1CompletedPreviously = _wasQuestCompletedInAnyPreviousRound(quest1_1Key, isMyPlayer);
    bool quest1_1CompletedInCurrentRound = isMyPlayer ? _currentRound.myQuest1_1Completed : _currentRound.opponentQuest1_1Completed;
    
    String quest1_2Key = isMyPlayer ? 'myQuest1_2Completed' : 'opponentQuest1_2Completed';
    bool quest1_2CompletedPreviously = _wasQuestCompletedInAnyPreviousRound(quest1_2Key, isMyPlayer);
    bool quest1_2CompletedInCurrentRound = isMyPlayer ? _currentRound.myQuest1_2Completed : _currentRound.opponentQuest1_2Completed;

    String quest1_3Key = isMyPlayer ? 'myQuest1_3Completed' : 'opponentQuest1_3Completed';
    bool quest1_3CompletedPreviously = _wasQuestCompletedInAnyPreviousRound(quest1_3Key, isMyPlayer);
    bool quest1_3CompletedInCurrentRound = isMyPlayer ? _currentRound.myQuest1_3Completed : _currentRound.opponentQuest1_3Completed;

    // Condition: Y a-t-il une autre quête (différente de celle-ci) dans la suite 1 complétée dans le tour actuel?
    bool anyOtherQuest1CompletedInCurrentRound(String currentQuestKey) {
        if (isMyPlayer) {
            return (quest1_1CompletedInCurrentRound && currentQuestKey != quest1_1Key) ||
                   (quest1_2CompletedInCurrentRound && currentQuestKey != quest1_2Key) ||
                   (quest1_3CompletedInCurrentRound && currentQuestKey != quest1_3Key);
        } else {
            return (quest1_1CompletedInCurrentRound && currentQuestKey != quest1_1Key) ||
                   (quest1_2CompletedInCurrentRound && currentQuestKey != quest1_2Key) ||
                   (quest1_3CompletedInCurrentRound && currentQuestKey != quest1_3Key);
        }
    }

    // Enabled state for Suite 1 Quests
    bool isQuest1_1Enabled = !disableQuestsGlobally &&
                             !quest1_1CompletedPreviously &&
                             (quest1_1CompletedInCurrentRound || !anyOtherQuest1CompletedInCurrentRound(quest1_1Key));
    
    bool isQuest1_2Enabled = !disableQuestsGlobally &&
                             !quest1_2CompletedPreviously &&
                             _isQuestActuallyCompleted(quest1_1Key, isMyPlayer) && // Sequential dependency
                             (quest1_2CompletedInCurrentRound || !anyOtherQuest1CompletedInCurrentRound(quest1_2Key));

    bool isQuest1_3Enabled = !disableQuestsGlobally &&
                             !quest1_3CompletedPreviously &&
                             _isQuestActuallyCompleted(quest1_2Key, isMyPlayer) && // Sequential dependency
                             (quest1_3CompletedInCurrentRound || !anyOtherQuest1CompletedInCurrentRound(quest1_3Key));

    // --- Suite 2 ---
    String quest2_1Key = isMyPlayer ? 'myQuest2_1Completed' : 'opponentQuest2_1Completed';
    bool quest2_1CompletedPreviously = _wasQuestCompletedInAnyPreviousRound(quest2_1Key, isMyPlayer);
    bool quest2_1CompletedInCurrentRound = isMyPlayer ? _currentRound.myQuest2_1Completed : _currentRound.opponentQuest2_1Completed;
    
    String quest2_2Key = isMyPlayer ? 'myQuest2_2Completed' : 'opponentQuest2_2Completed';
    bool quest2_2CompletedPreviously = _wasQuestCompletedInAnyPreviousRound(quest2_2Key, isMyPlayer);
    bool quest2_2CompletedInCurrentRound = isMyPlayer ? _currentRound.myQuest2_2Completed : _currentRound.opponentQuest2_2Completed;

    String quest2_3Key = isMyPlayer ? 'myQuest2_3Completed' : 'opponentQuest2_3Completed';
    bool quest2_3CompletedPreviously = _wasQuestCompletedInAnyPreviousRound(quest2_3Key, isMyPlayer);
    bool quest2_3CompletedInCurrentRound = isMyPlayer ? _currentRound.myQuest2_3Completed : _currentRound.opponentQuest2_3Completed;

    // Condition: Y a-t-il une autre quête (différente de celle-ci) dans la suite 2 complétée dans le tour actuel?
    bool anyOtherQuest2CompletedInCurrentRound(String currentQuestKey) {
        if (isMyPlayer) {
            return (quest2_1CompletedInCurrentRound && currentQuestKey != quest2_1Key) ||
                   (quest2_2CompletedInCurrentRound && currentQuestKey != quest2_2Key) ||
                   (quest2_3CompletedInCurrentRound && currentQuestKey != quest2_3Key);
        } else {
            return (quest2_1CompletedInCurrentRound && currentQuestKey != quest2_1Key) ||
                   (quest2_2CompletedInCurrentRound && currentQuestKey != quest2_2Key) ||
                   (quest2_3CompletedInCurrentRound && currentQuestKey != quest2_3Key);
        }
    }

    // Enabled state for Suite 2 Quests
    bool isQuest2_1Enabled = !disableQuestsGlobally &&
                             !quest2_1CompletedPreviously &&
                             (quest2_1CompletedInCurrentRound || !anyOtherQuest2CompletedInCurrentRound(quest2_1Key));
    
    bool isQuest2_2Enabled = !disableQuestsGlobally &&
                             !quest2_2CompletedPreviously &&
                             _isQuestActuallyCompleted(quest2_1Key, isMyPlayer) && // Sequential dependency
                             (quest2_2CompletedInCurrentRound || !anyOtherQuest2CompletedInCurrentRound(quest2_2Key));

    bool isQuest2_3Enabled = !disableQuestsGlobally &&
                             !quest2_3CompletedPreviously &&
                             _isQuestActuallyCompleted(quest2_2Key, isMyPlayer) && // Sequential dependency
                             (quest2_3CompletedInCurrentRound || !anyOtherQuest2CompletedInCurrentRound(quest2_3Key));


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
                  _buildQuestCheckbox(
                    '1 - Affray',
                    isMyPlayer ? _currentRound.myQuest1_1Completed : _currentRound.opponentQuest1_1Completed,
                        (newValue) => _updateQuest(isMyPlayer ? 'myQuest1_1Completed' : 'opponentQuest1_1Completed', newValue, isMyPlayer),
                    isEnabled: isQuest1_1Enabled,
                  ),
                  _buildQuestCheckbox(
                    '1 - Strike',
                    isMyPlayer ? _currentRound.myQuest1_2Completed : _currentRound.opponentQuest1_2Completed,
                        (newValue) => _updateQuest(isMyPlayer ? 'myQuest1_2Completed' : 'opponentQuest1_2Completed', newValue, isMyPlayer),
                    isEnabled: isQuest1_2Enabled,
                  ),
                  _buildQuestCheckbox(
                    '1 - Domination',
                    isMyPlayer ? _currentRound.myQuest1_3Completed : _currentRound.opponentQuest1_3Completed,
                        (newValue) => _updateQuest(isMyPlayer ? 'myQuest1_3Completed' : 'opponentQuest1_3Completed', newValue, isMyPlayer),
                    isEnabled: isQuest1_3Enabled,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Groupe de Quêtes 2
                  _buildQuestCheckbox(
                    '2 - Affray',
                    isMyPlayer ? _currentRound.myQuest2_1Completed : _currentRound.opponentQuest2_1Completed,
                        (newValue) => _updateQuest(isMyPlayer ? 'myQuest2_1Completed' : 'opponentQuest2_1Completed', newValue, isMyPlayer),
                    isEnabled: isQuest2_1Enabled,
                  ),
                  _buildQuestCheckbox(
                    '2 - Strike',
                    isMyPlayer ? _currentRound.myQuest2_2Completed : _currentRound.opponentQuest2_2Completed,
                        (newValue) => _updateQuest(isMyPlayer ? 'myQuest2_2Completed' : 'opponentQuest2_2Completed', newValue, isMyPlayer),
                    isEnabled: isQuest2_2Enabled,
                  ),
                  _buildQuestCheckbox(
                    '2 - Domination',
                    isMyPlayer ? _currentRound.myQuest2_3Completed : _currentRound.opponentQuest2_3Completed,
                        (newValue) => _updateQuest(isMyPlayer ? 'myQuest2_3Completed' : 'opponentQuest2_3Completed', newValue, isMyPlayer),
                    isEnabled: isQuest2_3Enabled,
                  ),
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
    int myScorePreviousRounds = 0;
    int opponentScorePreviousRounds = 0;

    for (var round in widget.game.rounds) {
      if (round.roundNumber < widget.roundNumber) {
        myScorePreviousRounds += round.calculatePlayerTotalScore(true);
        opponentScorePreviousRounds += round.calculatePlayerTotalScore(false);
      }
    }

    Widget myPlayerCard = _buildPlayerScoreCard(context, _myPlayerName, true, myScorePreviousRounds, opponentScorePreviousRounds);
    Widget opponentPlayerCard = _buildPlayerScoreCard(context, _opponentPlayerName, false, myScorePreviousRounds, opponentScorePreviousRounds);

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
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Vérifiez si tous les champs essentiels sont remplis avant de passer au round suivant
                    if (_currentRound.priorityPlayerId != null && _currentRound.initiativePlayerId != null) {
                      widget.onUpdateRound(_currentRound);
                      // Pas de navigation ici, car le widget parent gère la navigation
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Veuillez définir l\'initiative et la priorité du tour.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // Couleur du bouton "Valider le Round"
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Valider le Round'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}