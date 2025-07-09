// lib/screens/games_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:octominia/models/game.dart'; // Assurez-vous que cette ligne est présente
import 'package:octominia/services/game_json_storage.dart';
import 'package:octominia/screens/add_game_screen.dart';
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
          notes: 'Premier match de la saison, bonne performance.',
          scoreOutOf20: 18,
          gameState: GameState.completed, // Make sure it's completed for demonstration
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
          notes: 'Match très serré, fin en égalité.',
          scoreOutOf20: 10,
          gameState: GameState.completed, // Make sure it's completed for demonstration
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
          notes: 'Défaite cuisante, besoin de revoir ma stratégie.',
          scoreOutOf20: 5,
          gameState: GameState.completed, // Make sure it's completed for demonstration
        ),
        // Add a game that is still in progress to test "En cours"
        Game(
          date: DateTime.now().subtract(const Duration(hours: 2)),
          myPlayerName: 'Octo',
          myFactionName: 'Sylvaneth',
          myFactionImageUrl: "assets/images/factions/faction_sylvaneth.jpg",
          myScore: 10,
          myDrops: 1,
          myAuxiliaryUnits: false,
          opponentScore: 5,
          opponentPlayerName: 'Alex',
          opponentFactionName: 'Skaven',
          opponentFactionImageUrl: "assets/images/factions/faction_skaven.jpg",
          opponentDrops: 1,
          opponentAuxiliaryUnits: false,
          rounds: [],
          notes: 'Partie en cours, bon début.',
          scoreOutOf20: 0, // Score /20 is 0 if not completed
          gameState: GameState.round3, // Example of in-progress state
        ),
      ];

      for (var game in demoGames) {
        await _gameStorage.addGame(game);
      }
      await _loadGames();
    }
  }

  Color _getResultColor(GameResult result) { // Parameter type is GameResult
    developer.log('DEBUG: Résultat pour la couleur: "$result"', name: 'GamesScreen._getResultColor');
    switch (result) {
      case GameResult.victory:
        return Colors.green;
      case GameResult.defeat:
        return Colors.red;
      case GameResult.equality:
        return Colors.amber;
      case GameResult.inProgress:
      default: // Fallback for any unexpected state, though inProgress should catch most
        developer.log('WARNING: Résultat de partie non géré ou en cours: "$result"', name: 'GamesScreen._getResultColor');
        return Colors.blue;
    }
  }

  // _getFormattedResultText is no longer needed as result.displayTitle is used directly

  void _handleGameTap(Game game) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddGameScreen(
          initialGame: game,
          onGameSaved: (Game savedGame) {
            _loadGames();
          },
        ),
      ),
    );
    _loadGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        backgroundColor: Colors.amberAccent[200],
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
                    final Color resultColor = _getResultColor(game.result); // game.result is now GameResult enum
                    final String formattedResult = game.result.displayTitle.toUpperCase(); // Direct use of displayTitle

                    developer.log(
                      'DEBUG: Partie ${game.myPlayerName} vs ${game.opponentPlayerName}: result="${game.result.name}", formattedResult="$formattedResult", resultColor=$resultColor',
                      name: 'GamesScreen.CardBuilder',
                    );

                    return InkWell(
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
                          height: 140,
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
                                        // Removed the checkmark icon as per user request
                                      ],
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
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
                                        const SizedBox(width: 8.0),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                              formattedResult, // Now directly uses game.result.displayTitle
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.bold,
                                                color: resultColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8.0),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                game.opponentPlayerName,
                                                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color ?? Colors.white),
                                                textAlign: TextAlign.end,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                game.opponentFactionName ?? 'Faction Inconnue',
                                                style: TextStyle(fontSize: 12.0, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
                                                textAlign: TextAlign.end,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
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
                initialGame: null,
                onGameSaved: (Game savedGame) {
                  _loadGames();
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