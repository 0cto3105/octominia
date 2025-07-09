// lib/screens/game_template.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart'; // Importez Round si des informations de round sont affichées directement

class GameTemplate extends StatelessWidget {
  final Game game;
  final PageController pageController;
  final int currentPageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onReturnToList;
  final List<Widget> pages;

  const GameTemplate({
    super.key,
    required this.game,
    required this.pageController,
    required this.currentPageIndex,
    required this.onPageChanged,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onReturnToList,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    String myTrigram = game.myPlayerName.length >= 3 ? game.myPlayerName.substring(0, 3).toUpperCase() : game.myPlayerName.toUpperCase();
    String opponentTrigram = game.opponentPlayerName.length >= 3 ? game.opponentPlayerName.substring(0, 3).toUpperCase() : game.opponentPlayerName.toUpperCase();

    Widget appBarTitleWidget;

    if (currentPageIndex >= 2 && currentPageIndex <= 6) { // Rounds 1 to 5
      final currentRoundIndex = currentPageIndex - 2; // 0-indexed round number
      // Assurez-vous que l'index est valide avant d'accéder au round
      final currentRound = currentRoundIndex < game.rounds.length ? game.rounds[currentRoundIndex] : null;

      appBarTitleWidget = Align( // Aligner le contenu à gauche
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min, // Occuper l'espace minimal
          children: [
            if (currentRound != null) // Afficher les scores du round si le round existe
              Text(
                '${currentRound.myScore}-${currentRound.opponentScore}',
                style: const TextStyle(
                  fontSize: 28, // Taille plus grande pour les scores
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            const SizedBox(width: 8), // Espace entre les scores et les noms
            Text(
              '$myTrigram vs $opponentTrigram',
              style: const TextStyle(
                fontSize: 16, // Taille plus petite pour les noms
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    } else {
      String titleText;
      switch (currentPageIndex) {
        case 0:
          titleText = 'Configuration de la Partie';
          break;
        case 1:
          titleText = 'Jet de Dés & Priorité';
          break;
        case 7:
          titleText = 'Résumé de la Partie';
          break;
        default:
          titleText = 'Partie';
          break;
      }
      appBarTitleWidget = Text(titleText); // Pour les autres écrans, un simple Text
    }

    return PopScope(
      canPop: currentPageIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && currentPageIndex > 0) {
          onPreviousPage();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: appBarTitleWidget, // Utilisation du Widget personnalisé
          backgroundColor: Colors.redAccent,
          centerTitle: false, // Ne pas centrer le titre pour permettre l'alignement à gauche
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Retour à la liste des parties',
              onPressed: onReturnToList,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: onPageChanged,
                children: pages,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row( // Nouveau Row pour le bouton Précédent et le texte du tour
                      children: [
                        ElevatedButton.icon(
                          onPressed: onPreviousPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(''), // Étiquette vide pour le bouton
                        ),
                        if (currentPageIndex >= 2 && currentPageIndex <= 6) // Afficher "Tour X" seulement pour les rounds
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0), // Espacement entre le bouton et le texte
                            child: Text(
                              'Tour ${currentPageIndex - 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Couleur du texte
                              ),
                            ),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(currentPageIndex == 7 ? 'Finaliser la Partie' : 'Suivant'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}