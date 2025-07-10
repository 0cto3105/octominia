// lib/screens/game_template.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/round.dart';

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
    Widget appBarTitleWidget;

    if (currentPageIndex >= 2 && currentPageIndex <= 6) { // Rounds 1 to 5
      appBarTitleWidget = Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${game.totalMyScore}-${game.totalOpponentScore}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${game.myPlayerName} vs ${game.opponentPlayerName}',
              style: const TextStyle(
                fontSize: 16,
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
          titleText = 'Game Setup';
          break;
        case 1:
          titleText = 'Dice Roll & Priority';
          break;
        case 7:
          titleText = 'Game Summary';
          break;
        default:
          titleText = 'Game';
          break;
      }
      appBarTitleWidget = Text(titleText);
    }

    // MODIFIÉ : Logique pour le texte du bouton Suivant/Terminer
    String nextButtonText;
    if (currentPageIndex == 6) { // Si on est au tour 5
      nextButtonText = 'Voir le résumé';
    } else if (currentPageIndex == 7) { // Si on est sur le résumé
      nextButtonText = 'Terminer';
    } else {
      nextButtonText = 'Suivant';
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
          title: appBarTitleWidget,
          backgroundColor: Colors.redAccent,
          centerTitle: false,
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
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: onPreviousPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(''),
                        ),
                        if (currentPageIndex >= 2 && currentPageIndex <= 6)
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Text(
                              'Tour ${currentPageIndex - 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                      child: Text(nextButtonText), // Utilisation du texte dynamique
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