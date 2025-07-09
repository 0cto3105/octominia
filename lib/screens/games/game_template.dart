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

    // Suppression du calcul manuel des scores totaux, car ils sont maintenant disponibles via les getters de l'objet game
    // int totalMyScore = 0;
    // int totalOpponentScore = 0;
    // for (var round in game.rounds) {
    //   totalMyScore += round.myScore;
    //   totalOpponentScore += round.opponentScore;
    // }

    if (currentPageIndex >= 2 && currentPageIndex <= 6) { // Rounds 1 to 5
      appBarTitleWidget = Align( // Aligner le contenu à gauche
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min, // Occuper l'espace minimal
          children: [
            // Afficher les scores totaux de la partie en utilisant les nouveaux getters
            Text(
              '${game.totalMyScore}-${game.totalOpponentScore}', // MODIFIÉ ICI pour utiliser les getters
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
          titleText = 'Game Setup'; // Configuration de la Partie
          break;
        case 1:
          titleText = 'Dice Roll & Priority'; // Jet de Dés & Priorité
          break;
        case 7:
          titleText = 'Game Summary'; // Résumé de la Partie
          break;
        default:
          titleText = 'Game'; // Partie (ou 'Round' si cela fait référence aux tours de jeu)
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