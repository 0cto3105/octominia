// lib/screens/games_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/services/game_json_storage.dart';
import 'package:octominia/screens/games/game_center.dart';
import 'dart:developer' as developer;
import 'dart:convert';

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
    setState(() { _isLoading = true; });
    try {
      final games = await _gameStorage.loadGames();
      setState(() {
        _games = games;
        _games.sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (e) {
      developer.log('ERREUR: Échec du chargement des parties: $e', name: 'GamesScreen');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _deleteGame(Game gameToDelete) {
    final int index = _games.indexOf(gameToDelete);
    if (index == -1) return;

    final messenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _games.removeAt(index);
    });

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Partie supprimée'),
        action: SnackBarAction(
          label: 'ANNULER',
          onPressed: () {
            setState(() {
              _games.insert(index, gameToDelete);
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    ).closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        if (!mounted) return;
        _gameStorage.deleteGame(gameToDelete.id);
      }
    });
  }

  Future<void> _deleteAllGames() async {
    await _gameStorage.clearAllGames();
    setState(() {
      _games.clear();
    });
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les parties ont été supprimées.')),
      );
    }
  }

  Future<void> _showDeleteAllConfirmationDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir supprimer TOUTES les parties ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Supprimer', style: TextStyle(color: Colors.red[700])),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteAllGames();
    }
  }

  Future<void> _insertDemoGamesIfNeeded() async {
    if (_games.isEmpty) {
      final demoGames = [
        Game(date: DateTime.now().subtract(const Duration(days: 1)), myPlayerName: 'Octo', myFactionName: 'Kruleboyz', myFactionImageUrl: "assets/images/factions/faction_kruleboyz.jpg", myDrops: 1, myAuxiliaryUnits: false, opponentPlayerName: 'Tibo', opponentFactionName: 'Seraphon', opponentFactionImageUrl: "assets/images/factions/faction_seraphon.jpg", opponentDrops: 1, opponentAuxiliaryUnits: false, notes: 'Premier match.', scoreOutOf20: 18, gameState: GameState.completed),
        Game(date: DateTime.now().subtract(const Duration(days: 5)), myPlayerName: 'Octo', myFactionName: 'Daughters of Khaine', myFactionImageUrl: "assets/images/factions/faction_daughters_of_khaine.jpg", myDrops: 1, myAuxiliaryUnits: false, opponentPlayerName: 'Yohan', opponentFactionName: 'Ogor Mawtribes', opponentFactionImageUrl: "assets/images/factions/faction_ogor_mawtribes.jpg", opponentDrops: 1, opponentAuxiliaryUnits: false, notes: 'Match très serré.', scoreOutOf20: 10, gameState: GameState.completed),
      ];
      for (var game in demoGames) {
        await _gameStorage.addGame(game);
      }
      await _loadGames();
    }
  }

  Color _getResultColor(GameResult result) {
    switch (result) {
      case GameResult.victory: return Colors.green;
      case GameResult.defeat: return Colors.red;
      case GameResult.equality: return Colors.amber;
      default: return Colors.blue;
    }
  }

  void _handleGameTap(Game game) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamerCenterScreen(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Supprimer toutes les parties',
            onPressed: _games.isEmpty ? null : _showDeleteAllConfirmationDialog,
          ),
        ],
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
                      if (!kReleaseMode)
                        ElevatedButton(
                          onPressed: _insertDemoGamesIfNeeded,
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
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
                    final Color resultColor = _getResultColor(game.result);
                    final String formattedResult = game.result.displayTitle.toUpperCase();
                    
                    final finalScores = game.getFinalScoresOutOf20();
                    final String myFinalScore = finalScores['myFinalScore'].toString();
                    final String opponentFinalScore = finalScores['opponentFinalScore'].toString();
                    
                    final String myTotalScoreText = game.totalMyScore.toString();
                    final String opponentTotalScoreText = game.totalOpponentScore.toString();

                    return Dismissible(
                      key: ValueKey(game.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteGame(game);
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: InkWell(
                        onTap: () => _handleGameTap(game),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                          clipBehavior: Clip.antiAlias,
                          color: Theme.of(context).cardColor,
                          child: SizedBox(
                            height: 140,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: SizedBox.expand(child: Opacity(opacity: 0.12, child: (game.myFactionImageUrl != null && game.myFactionImageUrl!.isNotEmpty) ? Image.asset(game.myFactionImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.transparent)) : Container(color: Colors.transparent)))),
                                    Expanded(child: SizedBox.expand(child: Opacity(opacity: 0.12, child: (game.opponentFactionImageUrl != null && game.opponentFactionImageUrl!.isNotEmpty) ? Image.asset(game.opponentFactionImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.transparent)) : Container(color: Colors.transparent)))),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(formattedDate, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[500]))]),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(game.myPlayerName, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color ?? Colors.white), overflow: TextOverflow.ellipsis), Text(game.myFactionName, style: TextStyle(fontSize: 12.0, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), overflow: TextOverflow.ellipsis)])),
                                          const SizedBox(width: 8.0),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text('$myFinalScore - $opponentFinalScore', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                                              const SizedBox(height: 2.0),
                                              Text('($myTotalScoreText - $opponentTotalScoreText)', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: Theme.of(context).textTheme.bodySmall?.color)),
                                              const SizedBox(height: 2.0),
                                              Text(formattedResult, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: resultColor)),
                                            ],
                                          ),
                                          const SizedBox(width: 8.0),
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [Text(game.opponentPlayerName, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color ?? Colors.white), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis), Text(game.opponentFactionName, style: TextStyle(fontSize: 12.0, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)])),
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
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GamerCenterScreen(
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