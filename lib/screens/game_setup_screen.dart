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
  late int _myCurrentDrops;
  late int _opponentCurrentDrops;

  @override
  void initState() {
    super.initState();
    _myPlayerNameController.text = widget.game.myPlayerName;
    _opponentPlayerNameController.text = widget.game.opponentPlayerName;

    _loadFactions();

    // Initialisation des sliders avec les valeurs de la partie
    // S'assurer que les drops sont au minimum 1
    _myCurrentDrops = widget.game.myDrops < 1 ? 1 : widget.game.myDrops; // Ensure min is 1
    _opponentCurrentDrops = widget.game.opponentDrops < 1 ? 1 : widget.game.opponentDrops; // Ensure min is 1

    // Assurez-vous que les factions sont bien définies si la game existe déjà
    if (widget.game.myFactionName.isNotEmpty) {
      _mySelectedFaction = Faction(
          uuid: 'temp_my_uuid', // Placeholder, sera mis à jour après le chargement réel
          name: widget.game.myFactionName,
          orderUuid: '',
          orderId: 0);
    }
    if (widget.game.opponentFactionName.isNotEmpty) {
      _opponentSelectedFaction = Faction(
          uuid: 'temp_opponent_uuid', // Placeholder
          name: widget.game.opponentFactionName,
          orderUuid: '',
          orderId: 0);
    }

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

  Future<void> _loadFactions() async {
    setState(() {
      _isLoadingFactions = true;
    });
    final dbHelper = DatabaseHelper();
    final loadedFactions = await dbHelper.getFactions();
    setState(() {
      _factions = loadedFactions;
      if (widget.game.myFactionName.isNotEmpty) {
        _mySelectedFaction = _factions.firstWhere(
          (faction) => faction.name == widget.game.myFactionName,
          orElse: () => null as Faction, // Gérer le cas où la faction n'est pas trouvée
        );
      }
      if (widget.game.opponentFactionName.isNotEmpty) {
        _opponentSelectedFaction = _factions.firstWhere(
          (faction) => faction.name == widget.game.opponentFactionName,
          orElse: () => null as Faction, // Gérer le cas où la faction n'est pas trouvée
        );
      }
      _isLoadingFactions = false;
    });
  }

  void _updateGame() {
    widget.onUpdate(widget.game.copyWith(
      myPlayerName: _myPlayerNameController.text,
      myFactionName: _mySelectedFaction?.name,
      myFactionImageUrl: _mySelectedFaction?.imageUrl,
      myDrops: _myCurrentDrops,
      opponentPlayerName: _opponentPlayerNameController.text,
      opponentFactionName: _opponentSelectedFaction?.name,
      opponentFactionImageUrl: _opponentSelectedFaction?.imageUrl,
      opponentDrops: _opponentCurrentDrops,
    ));
  }

  Widget _buildPlayerSetup(
      String playerName,
      TextEditingController controller,
      Faction? selectedFaction,
      ValueChanged<Faction?> onFactionChanged,
      int currentDrops,
      ValueChanged<double> onDropsChanged,
      bool hasAuxiliaryUnits,
      ValueChanged<bool?> onAuxiliaryUnitsChanged,
      bool isMyPlayer,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMyPlayer ? 'Mon Joueur' : 'Adversaire',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Nom du ${isMyPlayer ? 'joueur' : 'adversaire'}'),
          onChanged: (value) => _updateGame(),
        ),
        const SizedBox(height: 16.0),
        _isLoadingFactions
            ? const CircularProgressIndicator()
            : DropdownButtonFormField<Faction>(
          value: selectedFaction,
          decoration: const InputDecoration(labelText: 'Faction'),
          items: _factions.map((faction) {
            return DropdownMenuItem(
              value: faction,
              child: Text(faction.name),
            );
          }).toList(),
          onChanged: (Faction? newValue) {
            setState(() {
              if (isMyPlayer) {
                _mySelectedFaction = newValue;
              } else {
                _opponentSelectedFaction = newValue;
              }
              _updateGame();
            });
          },
          isExpanded: true,
          menuMaxHeight: 300,
        ),
        const SizedBox(height: 16.0),
        Text('Drops: $currentDrops'),
        Slider(
          value: currentDrops.toDouble(),
          min: 1, // Min drop is 1
          max: 5, // Max drop is 5
          divisions: 4, // Divisions for 1, 2, 3, 4, 5
          label: currentDrops.round().toString(),
          onChanged: (double value) {
            setState(() {
              if (isMyPlayer) {
                _myCurrentDrops = value.round();
              } else {
                _opponentCurrentDrops = value.round();
              }
              _updateGame();
            });
          },
          activeColor: isMyPlayer ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
          inactiveColor: (isMyPlayer ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary).withOpacity(0.3),
        ),
        Row(
          children: [
            Checkbox(
              value: hasAuxiliaryUnits,
              onChanged: onAuxiliaryUnitsChanged,
              checkColor: isMyPlayer ? Colors.white : Colors.black,
              activeColor: isMyPlayer ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
            ),
            Text(
              '${isMyPlayer ? 'J\'ai' : 'L\'adversaire a'} des unités auxiliaires',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildPlayerSetup(
                _myPlayerNameController.text,
                _myPlayerNameController,
                _mySelectedFaction,
                    (newValue) {
                  setState(() {
                    _mySelectedFaction = newValue;
                    _updateGame();
                  });
                },
                _myCurrentDrops,
                    (value) {
                  setState(() {
                    _myCurrentDrops = value.round();
                    _updateGame();
                  });
                },
                widget.game.myAuxiliaryUnits,
                    (newValue) {
                  setState(() {
                    widget.onUpdate(widget.game.copyWith(myAuxiliaryUnits: newValue));
                  });
                },
                true,
              ),
              _buildPlayerSetup(
                _opponentPlayerNameController.text,
                _opponentPlayerNameController,
                _opponentSelectedFaction,
                    (newValue) {
                  setState(() {
                    _opponentSelectedFaction = newValue;
                    _updateGame();
                  });
                },
                _opponentCurrentDrops,
                    (value) {
                  setState(() {
                    _opponentCurrentDrops = value.round();
                    _updateGame();
                  });
                },
                widget.game.opponentAuxiliaryUnits,
                    (newValue) {
                  setState(() {
                    widget.onUpdate(widget.game.copyWith(opponentAuxiliaryUnits: newValue));
                  });
                },
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}