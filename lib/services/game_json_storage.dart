// lib/services/game_json_storage.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:octominia/models/game.dart';
import 'package:uuid/uuid.dart'; // Make sure uuid is in your pubspec.yaml

class GameJsonStorage {
  final String _filename = 'games.json'; // Define a filename for your JSON data

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile() async { // Renamed from _localFile to _getLocalFile for consistency with previous discussion
    final path = await _localPath;
    return File('$path/$_filename');
  }

  // Load all games from the JSON file
  Future<List<Game>> loadGames() async {
    try {
      final file = await _getLocalFile(); // Use the getter
      if (!await file.exists()) {
        print("DEBUG: Fichier games.json non trouvé. Retourne une liste vide.");
        return []; // Return an empty list if the file doesn't exist
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        print("DEBUG: Le fichier games.json est vide. Retourne une liste vide.");
        return []; // Handle empty file content gracefully
      }
      
      final List<dynamic> jsonList = jsonDecode(contents); // Use jsonDecode for direct parsing

      // Iterate and attempt to deserialize, filtering out any failures
      return jsonList.map((json) {
        try {
          return Game.fromMap(json as Map<String, dynamic>);
        } catch (e) {
          print('ERREUR: Lors de la désérialisation d\'une partie depuis JSON: $e');
          print('DEBUG: Données JSON problématiques: $json');
          return null; // Return null for games that fail to deserialize
        }
      }).whereType<Game>().toList(); // Filter out any nulls resulting from failed deserialization
    } catch (e) {
      print('ERREUR: Générale lors du chargement des parties depuis le stockage: $e');
      return []; // Return empty list on any general error during file operations
    }
  }

  // Save a list of games to the JSON file
  Future<void> _saveGames(List<Game> games) async {
    try {
      final file = await _getLocalFile();
      final List<Map<String, dynamic>> jsonList = games.map((game) => game.toMap()).toList();
      final jsonString = jsonEncode(jsonList); // Use jsonEncode
      await file.writeAsString(jsonString);
      print('DEBUG: Parties sauvegardées avec succès. Nombre de parties: ${games.length}');
    } catch (e) {
      print('ERREUR: Lors de la sauvegarde des parties dans le fichier: $e');
    }
  }

  // Add a new game
  Future<void> addGame(Game newGame) async {
    try {
      final List<Game> games = await loadGames();
      // The Game constructor now handles generating an ID if null, so this check is mostly for robustness
      // and backward compatibility if a Game object without ID was ever passed.
      if (newGame.id.isEmpty) {
        newGame = newGame.copyWith(id: const Uuid().v4()); // Use const Uuid().v4()
      }
      games.add(newGame);
      await _saveGames(games);
      print('DEBUG: Partie ajoutée avec succès: ${newGame.id}');
    } catch (e) {
      print('ERREUR: Lors de l\'ajout d\'une partie: $e');
    }
  }

  // Update an existing game
  Future<void> updateGame(Game updatedGame) async {
    try {
      final List<Game> games = await loadGames();
      final index = games.indexWhere((game) => game.id == updatedGame.id);
      if (index != -1) {
        games[index] = updatedGame;
        await _saveGames(games);
        print('DEBUG: Partie mise à jour avec succès: ${updatedGame.id}');
      } else {
        print('DEBUG: Partie avec ID ${updatedGame.id} non trouvée pour la mise à jour.');
      }
    } catch (e) {
      print('ERREUR: Lors de la mise à jour d\'une partie: $e');
    }
  }

  // Delete a game
  Future<void> deleteGame(String gameId) async {
    try {
      final List<Game> games = await loadGames();
      final initialLength = games.length;
      games.removeWhere((game) => game.id == gameId);
      if (games.length < initialLength) {
        await _saveGames(games);
        print('DEBUG: Partie avec ID $gameId supprimée avec succès.');
      } else {
        print('DEBUG: Partie avec ID $gameId non trouvée pour la suppression.');
      }
    } catch (e) {
      print('ERREUR: Lors de la suppression d\'une partie: $e');
    }
  }
}