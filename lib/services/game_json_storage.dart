// lib/services/game_json_storage.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:octominia/models/game.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer; // Import for developer.log

class GameJsonStorage {
  final String _filename = 'games.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile() async {
    final path = await _localPath;
    return File('$path/$_filename');
  }

  Future<List<Game>> loadGames() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        developer.log("DEBUG: Fichier games.json non trouvé. Retourne une liste vide.", name: 'GameJsonStorage');
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        developer.log("DEBUG: Le fichier games.json est vide. Retourne une liste vide.", name: 'GameJsonStorage');
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(contents);

      return jsonList.map((json) {
        try {
          // MODIFICATION ICI: Utilise Game.fromJson
          return Game.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          developer.log('ERREUR: Lors de la désérialisation d\'une partie depuis JSON: $e', error: e, name: 'GameJsonStorage');
          developer.log('DEBUG: Données JSON problématiques: $json', name: 'GameJsonStorage');
          return null;
        }
      }).whereType<Game>().toList();
    } catch (e) {
      developer.log('ERREUR: Générale lors du chargement des parties depuis le stockage: $e', error: e, name: 'GameJsonStorage');
      return [];
    }
  }

  Future<void> _saveGames(List<Game> games) async {
    try {
      final file = await _getLocalFile();
      // MODIFICATION ICI: Utilise game.toJson()
      final List<Map<String, dynamic>> jsonList = games.map((game) => game.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
      developer.log('DEBUG: Parties sauvegardées avec succès. Nombre de parties: ${games.length}', name: 'GameJsonStorage');
    } catch (e) {
      developer.log('ERREUR: Lors de la sauvegarde des parties dans le fichier: $e', error: e, name: 'GameJsonStorage');
    }
  }

  Future<void> addGame(Game newGame) async {
    try {
      final List<Game> games = await loadGames();
      if (newGame.id.isEmpty) {
        newGame = newGame.copyWith(id: const Uuid().v4());
      }
      games.add(newGame);
      await _saveGames(games);
      developer.log('DEBUG: Partie ajoutée avec succès: ${newGame.id}', name: 'GameJsonStorage');
    } catch (e) {
      developer.log('ERREUR: Lors de l\'ajout d\'une partie: $e', error: e, name: 'GameJsonStorage');
    }
  }

  Future<void> updateGame(Game updatedGame) async {
    try {
      final List<Game> games = await loadGames();
      final index = games.indexWhere((game) => game.id == updatedGame.id);
      if (index != -1) {
        games[index] = updatedGame;
        await _saveGames(games);
        developer.log('DEBUG: Partie mise à jour avec succès: ${updatedGame.id}', name: 'GameJsonStorage');
      } else {
        developer.log('DEBUG: Partie avec ID ${updatedGame.id} non trouvée pour la mise à jour.', name: 'GameJsonStorage');
      }
    } catch (e) {
      developer.log('ERREUR: Lors de la mise à jour d\'une partie: $e', error: e, name: 'GameJsonStorage');
    }
  }

  Future<void> deleteGame(String gameId) async {
    try {
      final List<Game> games = await loadGames();
      final initialLength = games.length;
      games.removeWhere((game) => game.id == gameId);
      if (games.length < initialLength) {
        await _saveGames(games);
        developer.log('DEBUG: Partie avec ID $gameId supprimée avec succès.', name: 'GameJsonStorage');
      } else {
        developer.log('DEBUG: Partie avec ID $gameId non trouvée pour la suppression.', name: 'GameJsonStorage');
      }
    } catch (e) {
      developer.log('ERREUR: Lors de la suppression d\'une partie: $e', error: e, name: 'GameJsonStorage');
    }
  }

  Future<void> clearAllGames() async {
  final file = await _getLocalFile();
  // Écrit simplement une liste JSON vide dans le fichier, ce qui efface tout.
  await file.writeAsString('[]');
}
}