// lib/screens/game_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/models/faction.dart';
import 'package:octominia/database/database_helper.dart';

class GameSetupScreen extends StatefulWidget {
  final Game game;
  final Function(Game) onUpdate;

  const GameSetupScreen({super.key, required this.game, required this.onUpdate});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _myPlayerNameController = TextEditingController();
  final TextEditingController _opponentPlayerNameController = TextEditingController();

  List<Faction> _factions = [];
  Faction? _mySelectedFaction;
  Faction? _opponentSelectedFaction;
  bool _isLoadingFactions = true;

  // Variables pour les sliders
  int _myCurrentDrops = 0;
  int _opponentCurrentDrops = 0;

  @override
  void initState() {
    super.initState();
    _myPlayerNameController.text = widget.game.myPlayerName;
    _opponentPlayerNameController.text = widget.game.opponentPlayerName;

    // --- MODIFICATION TRÈS IMPORTANTE ICI ---
    // Assurez-vous que la valeur initiale du slider est AU MOINS la valeur minimale (1)
    _myCurrentDrops = widget.game.myDrops < 1 ? 1 : widget.game.myDrops;
    _opponentCurrentDrops = widget.game.opponentDrops < 1 ? 1 : widget.game.opponentDrops;
    // --- FIN DE LA MODIFICATION ---

    _loadFactions();

    _myPlayerNameController.addListener(_updateGame);
    _opponentPlayerNameController.addListener(_updateGame);
  }

  @override
  void dispose() {
    _myPlayerNameController.removeListener(_updateGame);
    _opponentPlayerNameController.removeListener(_updateGame);
    _myPlayerNameController.dispose();
    _opponentPlayerNameController.dispose();
    super.dispose();
  }

  void _updateGame() {
    widget.onUpdate(widget.game.copyWith(
      myPlayerName: _myPlayerNameController.text,
      opponentPlayerName: _opponentPlayerNameController.text,
      myDrops: _myCurrentDrops,
      opponentDrops: _opponentCurrentDrops,
    ));
  }

  Future<void> _loadFactions() async {
    setState(() {
      _isLoadingFactions = true;
    });
    final List<Map<String, dynamic>> factionMaps = await DatabaseHelper().getFactions();
    setState(() {
      _factions = factionMaps.map((map) => Faction.fromMap(map)).toList();
      _factions.sort((a, b) => a.name.compareTo(b.name));

      if (widget.game.myFactionName.isNotEmpty) {
        _mySelectedFaction = _factions.firstWhere(
          (f) => f.name == widget.game.myFactionName,
          orElse: () => _factions.first,
        );
      }
      if (widget.game.opponentFactionName.isNotEmpty) {
        _opponentSelectedFaction = _factions.firstWhere(
          (f) => f.name == widget.game.opponentFactionName,
          orElse: () => _factions.first,
        );
      }
      _isLoadingFactions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoadingFactions
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Mon Joueur
                  Text(
                    'Mon Joueur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _myPlayerNameController,
                    decoration: const InputDecoration(labelText: 'Pseudo'),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    validator: (value) => value!.isEmpty ? 'Veuillez entrer votre pseudo' : null,
                  ),
                  DropdownButtonFormField<Faction>(
                    value: _mySelectedFaction,
                    hint: const Text('Sélectionner ma faction'),
                    decoration: const InputDecoration(labelText: 'Ma Faction'),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    dropdownColor: Theme.of(context).cardColor,
                    onChanged: (Faction? newValue) {
                      setState(() {
                        _mySelectedFaction = newValue;
                        widget.onUpdate(widget.game.copyWith(
                          myFactionName: newValue?.name,
                          myFactionImageUrl: newValue?.imageUrl,
                        ));
                      });
                    },
                    items: _factions.map<DropdownMenuItem<Faction>>((Faction faction) {
                      return DropdownMenuItem<Faction>(
                        value: faction,
                        child: Text(faction.name),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Veuillez sélectionner votre faction' : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mon nombre de drops: ${_myCurrentDrops}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  Slider(
                    value: _myCurrentDrops.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _myCurrentDrops.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _myCurrentDrops = value.round();
                        _updateGame();
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.secondary,
                    inactiveColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: widget.game.myAuxiliaryUnits,
                        onChanged: (bool? newValue) {
                          setState(() {
                            widget.onUpdate(widget.game.copyWith(myAuxiliaryUnits: newValue));
                          });
                        },
                        checkColor: Colors.black,
                        activeColor: Theme.of(context).colorScheme.secondary,
                      ),
                      Text(
                        'J\'ai des unités auxiliaires',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Joueur Adversaire
                  Text(
                    'Joueur Adversaire',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _opponentPlayerNameController,
                    decoration: const InputDecoration(labelText: 'Pseudo Adversaire'),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    validator: (value) => value!.isEmpty ? 'Veuillez entrer le pseudo de l\'adversaire' : null,
                  ),
                  DropdownButtonFormField<Faction>(
                    value: _opponentSelectedFaction,
                    hint: const Text('Sélectionner la faction adverse'),
                    decoration: const InputDecoration(labelText: 'Faction Adversaire'),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    dropdownColor: Theme.of(context).cardColor,
                    onChanged: (Faction? newValue) {
                      setState(() {
                        _opponentSelectedFaction = newValue;
                        widget.onUpdate(widget.game.copyWith(
                          opponentFactionName: newValue?.name,
                          opponentFactionImageUrl: newValue?.imageUrl,
                        ));
                      });
                    },
                    items: _factions.map<DropdownMenuItem<Faction>>((Faction faction) {
                      return DropdownMenuItem<Faction>(
                        value: faction,
                        child: Text(faction.name),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Veuillez sélectionner la faction de l\'adversaire' : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nombre de drops adverses: ${_opponentCurrentDrops}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  Slider(
                    value: _opponentCurrentDrops.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _opponentCurrentDrops.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _opponentCurrentDrops = value.round();
                        _updateGame();
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.secondary,
                    inactiveColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: widget.game.opponentAuxiliaryUnits,
                        onChanged: (bool? newValue) {
                          setState(() {
                            widget.onUpdate(widget.game.copyWith(opponentAuxiliaryUnits: newValue));
                          });
                        },
                        checkColor: Colors.black,
                        activeColor: Theme.of(context).colorScheme.secondary,
                      ),
                      Text(
                        'L\'adversaire a des unités auxiliaires',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          );
  }
}