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
    _myCurrentDrops = widget.game.myDrops < 1 ? 1 : widget.game.myDrops;
    _opponentCurrentDrops = widget.game.opponentDrops < 1 ? 1 : widget.game.opponentDrops;

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
          orElse: () => null as Faction,
        );
      }
      if (widget.game.opponentFactionName.isNotEmpty) {
        _opponentSelectedFaction = _factions.firstWhere(
          (faction) => faction.name == widget.game.opponentFactionName,
          orElse: () => null as Faction,
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

  Future<Faction?> _showFactionSelectionDialog(BuildContext context, Faction? currentSelected) async {
    return showGeneralDialog<Faction?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sélectionner une Faction'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(buildContext).pop(),
            ),
          ),
          body: _isLoadingFactions
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 30.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _factions.length,
                    itemBuilder: (context, index) {
                      final faction = _factions[index];
                      final bool isSelected = faction.uuid == currentSelected?.uuid;

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(buildContext).pop(faction);
                        },
                        child: Card(
                          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.7) : Theme.of(context).cardColor,
                          elevation: isSelected ? 8 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected ? BorderSide(color: Theme.of(context).colorScheme.secondary, width: 3) : BorderSide.none,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (faction.imageUrl != null && faction.imageUrl!.isNotEmpty)
                                ClipOval(
                                  child: Image.asset(
                                    faction.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60),
                                  ),
                                )
                              else
                                Icon(Icons.shield, size: 60, color: Theme.of(context).iconTheme.color),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  faction.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
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
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Nom ${isMyPlayer ? 'du joueur' : 'de l\'adversaire'}'),
          onChanged: (value) => _updateGame(),
        ),
        const SizedBox(height: 16.0),
        GestureDetector(
          onTap: _isLoadingFactions
              ? null
              : () async {
            final Faction? pickedFaction = await _showFactionSelectionDialog(context, selectedFaction);
            if (pickedFaction != null) {
              onFactionChanged(pickedFaction);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Faction',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              // NOUVEAU : Supprimer prefixIcon car nous allons gérer l'image dans le 'child'
              suffixIcon: _isLoadingFactions
                  ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.arrow_drop_down),
            ),
            // NOUVEAU : Utiliser un Row comme enfant direct pour un contrôle total
            child: Row(
              mainAxisSize: MainAxisSize.min, // La Row prendra la taille minimale nécessaire
              children: [
                if (selectedFaction?.imageUrl != null && selectedFaction!.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0), // Padding à droite de l'image
                    child: ClipOval(
                      child: Image.asset(
                        selectedFaction!.imageUrl!,
                        width: 32, // Taille de l'image
                        height: 32,
                        fit: BoxFit.cover, // Assure que l'image remplit l'espace
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 32),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0), // Padding pour l'icône par défaut
                    child: Icon(Icons.shield, size: 32, color: Theme.of(context).iconTheme.color),
                  ),
                Expanded( // Le texte prend l'espace restant
                  child: Text(
                    selectedFaction?.name ?? 'Sélectionner une faction',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedFaction != null ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
                    ),
                    overflow: TextOverflow.ellipsis, // Tronque le texte si trop long
                    maxLines: 1, // Limite le texte à une seule ligne
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text('Drops: $currentDrops', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        Slider(
          value: currentDrops.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
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