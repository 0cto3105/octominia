// lib/screens/games_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/services/game_json_storage.dart';
import 'package:octominia/screens/add_game_screen.dart'; // Assurez-vous que cette ligne est présente
import 'package:octominia/screens/game_summary_screen.dart'; // Import the GameSummaryScreen (conserver pour l'instant si nécessaire ailleurs)
import 'dart:developer' as developer;

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<Game> _games = [];
  bool _isLoading = true;
  final GameJsonStorage _gameStorage = GameJsonStorage();

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final games = await _gameStorage.loadGames();
      setState(() {
        _games = games;
        _games.sort((a, b) => b.date.compareTo(a.date));
      });
      developer.log('DEBUG: Parties chargées: ${_games.length}', name: 'GamesScreen');
    } catch (e) {
      developer.log('ERREUR: Échec du chargement des parties dans GamesScreen: $e', error: e, name: 'GamesScreen');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _insertDemoGamesIfNeeded() async {
    if (_games.isEmpty) {
      developer.log('Insertion de parties de démo avec les assets locaux...', name: 'GamesScreen');
      final demoGames = [
        Game(
          date: DateTime.now().subtract(const Duration(days: 1)),
          myPlayerName: 'Octo',
          myFactionName: 'Kruleboyz',
          myFactionImageUrl: "assets/images/factions/faction_kruleboyz.jpg",
          myScore: 70,
          myDrops: 1,
          myAuxiliaryUnits: false,
          opponentScore: 30,
          opponentPlayerName: 'Tibo',
          opponentFactionName: 'Seraphon',
          opponentFactionImageUrl: "assets/images/factions/faction_seraphon.jpg",
          opponentDrops: 1,
          opponentAuxiliaryUnits: false,
          rounds: [],
          result: 'VICTOIRE',
          notes: 'Premier match de la saison, bonne performance.',
          scoreOutOf20: 18,
        ),
        Game(
          date: DateTime.now().subtract(const Duration(days: 5)),
          myPlayerName: 'Octo',
          myFactionName: 'Daughters of Khaine',
          myFactionImageUrl: "assets/images/factions/faction_daughters_of_khaine.jpg",
          myScore: 40,
          myDrops: 1,
          myAuxiliaryUnits: false,
          opponentScore: 40,
          opponentPlayerName: 'Yohan',
          opponentFactionName: 'Ogor Mawtribes',
          opponentFactionImageUrl: "assets/images/factions/faction_ogor_mawtribes.jpg",
          opponentDrops: 1,
          opponentAuxiliaryUnits: false,
          rounds: [],
          result: 'EGALITE',
          notes: 'Match très serré, fin en égalité.',
          scoreOutOf20: 10,
        ),
        Game(
          date: DateTime.now().subtract(const Duration(days: 10)),
          myPlayerName: 'Octo',
          myFactionName: 'Stormcast Eternals',
          myFactionImageUrl: "assets/images/factions/faction_stormcast_eternals.jpg",
          myScore: 20,
          myDrops: 1,
          myAuxiliaryUnits: false,
          opponentScore: 60,
          opponentPlayerName: 'Marine',
          opponentFactionName: 'Slaves to Darkness',
          opponentFactionImageUrl: "assets/images/factions/faction_slaves_to_darkness.jpg",
          opponentDrops: 1,
          opponentAuxiliaryUnits: false,
          rounds: [],
          result: 'DEFAITE',
          notes: 'Défaite cuisante, besoin de revoir ma stratégie.',
          scoreOutOf20: 5,
        ),
      ];

      for (var game in demoGames) {
        await _gameStorage.addGame(game);
      }
      await _loadGames();
    }
  }

  Color _getResultColor(String result) {
    developer.log('DEBUG: Chaîne de résultat pour la couleur: "$result"', name: 'GamesScreen._getResultColor');
    switch (result.toUpperCase()) {
      case 'VICTOIRE_MAJEURE':
      case 'VICTOIRE':
        return Colors.green;
      case 'DEFAITE_MAJEURE':
      case 'DEFAITE':
        return Colors.red;
      case 'EGALITE':
        return Colors.amber;
      default:
        developer.log('WARNING: Résultat de partie non géré: "$result"', name: 'GamesScreen._getResultColor');
        return Colors.blue;
    }
  }

  String _getFormattedResultText(String result) {
    return result.replaceAll('_', ' ').toUpperCase();
  }

  // --- FONCTION MODIFIÉE POUR GÉRER LE CLIC SUR UNE CARTE DE PARTIE ---
  void _handleGameTap(Game game) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddGameScreen( // CHANGEMENT ICI : Ouvrir AddGameScreen
          initialGame: game, // Passer la partie existante pour édition
          onGameSaved: (Game savedGame) {
            // Callback déclenché après la sauvegarde d'une partie éditée.
            // On recharge les parties pour rafraîchir la liste si des modifications ont eu lieu.
            _loadGames();
          },
        ),
      ),
    );
    // Après être revenu de AddGameScreen, rechargez les parties au cas où des modifications
    // (comme la suppression ou la mise à jour) auraient été faites.
    _loadGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aucune partie trouvée.', style: TextStyle(fontSize: 18, color: Colors.white70)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _insertDemoGamesIfNeeded,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Ajouter des parties de démo'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  itemCount: _games.length,
                  itemBuilder: (context, index) {
                    final game = _games[index];
                    final String formattedDate = DateFormat('dd MMM - HH:mm').format(game.date);
                    final String myScoreText = game.myScore.toString();
                    final String opponentScoreText = game.opponentScore.toString();
                    final Color resultColor = _getResultColor(game.result);
                    final String formattedResult = _getFormattedResultText(game.result);

                    developer.log(
                      'DEBUG: Partie ${game.myPlayerName} vs ${game.opponentPlayerName}: result="${game.result}", formattedResult="$formattedResult", resultColor=$resultColor',
                      name: 'GamesScreen.CardBuilder',
                    );

                    return InkWell( // Wrap the Card with InkWell for tap detection
                      onTap: () => _handleGameTap(game),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        color: Theme.of(context).cardColor,
                        child: SizedBox(
                          height: 140, // Hauteur de la carte conservée
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox.expand(
                                      child: Opacity(
                                        opacity: 0.12,
                                        child: (game.myFactionImageUrl != null && game.myFactionImageUrl!.isNotEmpty)
                                            ? Image.asset(
                                                game.myFactionImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  developer.log('ERREUR: Impossible de charger l\'image : ${game.myFactionImageUrl}', error: error, name: 'GamesScreen.ImageError');
                                                  return Container(color: Colors.transparent, width: double.infinity, height: double.infinity);
                                                },
                                              )
                                            : Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox.expand(
                                      child: Opacity(
                                        opacity: 0.12,
                                        child: (game.opponentFactionImageUrl != null && game.opponentFactionImageUrl!.isNotEmpty)
                                            ? Image.asset(
                                                game.opponentFactionImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  developer.log('ERREUR: Impossible de charger l\'image : ${game.opponentFactionImageUrl}', error: error, name: 'GamesScreen.ImageError');
                                                  return Container(color: Colors.transparent, width: double.infinity, height: double.infinity);
                                                },
                                              )
                                            : Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.normal,
                                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(), // Pousse la Row suivante vers le bas
                                    Row(
                                      // *** NOUVELLE STRUCTURE POUR LE CENTRAGE HORIZONTAL DES 3 BLOCS ***
                                      mainAxisAlignment: MainAxisAlignment.center, // Centrer le contenu global de cette Row
                                      crossAxisAlignment: CrossAxisAlignment.center, // Centrage vertical des éléments dans cette Row
                                      children: [
                                        // Bloc "Moi" (ALIGNÉ À GAUCHE DANS SON Expanded)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start, // ALIGNEMENT À GAUCHE
                                            mainAxisAlignment: MainAxisAlignment.center, // Centrage vertical dans la colonne
                                            children: [
                                              Text(
                                                game.myPlayerName,
                                                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color ?? Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                game.myFactionName ?? 'Faction Inconnue',
                                                style: TextStyle(fontSize: 12.0, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8.0), // Espacement entre les blocs
                                        // Bloc de Scoring (TOUJOURS BIEN CENTRÉ)
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center, // Centrage vertical dans la colonne
                                          crossAxisAlignment: CrossAxisAlignment.center, // ALIGNEMENT AU CENTRE pour le texte du scoring
                                          children: [
                                            Text(
                                              '${game.scoreOutOf20}/20',
                                              style: TextStyle(
                                                fontSize: 24.0,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2.0),
                                            Text(
                                              '$myScoreText - $opponentScoreText',
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2.0),
                                            Text(
                                              formattedResult,
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.bold,
                                                color: resultColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8.0), // Espacement entre les blocs
                                        // Bloc "Adversaire" (ALIGNÉ À DROITE DANS SON Expanded)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end, // ALIGNEMENT À DROITE
                                            mainAxisAlignment: MainAxisAlignment.center, // Centrage vertical dans la colonne
                                            children: [
                                              Text(
                                                game.opponentPlayerName,
                                                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color ?? Colors.white),
                                                textAlign: TextAlign.end, // Important pour l'alignement du texte lui-même
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                game.opponentFactionName ?? 'Faction Inconnue',
                                                style: TextStyle(fontSize: 12.0, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
                                                textAlign: TextAlign.end, // Important pour l'alignement du texte lui-même
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(), // Pousse la Row précédente vers le haut
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddGameScreen(
                initialGame: null, // Indique que c'est une nouvelle partie
                onGameSaved: (Game savedGame) {
                  // Callback déclenché après la sauvegarde d'une nouvelle partie
                  // ou la mise à jour d'une partie existante.
                  _loadGames(); // Rechargez toutes les parties pour rafraîchir la liste.
                },
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}