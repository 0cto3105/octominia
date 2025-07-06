import 'package:flutter/material.dart';
import 'package:octominia/database/database_helper.dart'; // Assurez-vous que cet import est là
import 'package:octominia/screens/collection_screen.dart';
import 'package:octominia/screens/units_screen.dart'; // Assurez-vous que cet import est là
import 'package:octominia/screens/factions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialisation de la base de données.
  // La version 2 ajoute la colonne imageUrl aux tables 'orders' et 'factions'.
  // Si vous avez déjà une BDD v1, cela déclenchera onUpgrade.
  await DatabaseHelper().database; 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Octominia',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index de l'onglet sélectionné

  // Liste des écrans disponibles - L'ORDRE EST IMPORTANT ICI !
  final List<Widget> _screens = [
    const CollectionScreen(), // Index 0
    const UnitsScreen(),      // Index 1 (si vous l'avez) - Ajustez si vous n'avez que 3 écrans
    const FactionsScreen(),   // Index 2
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Affiche l'écran sélectionné
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory), // Icône pour la Collection
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_martial_arts), // Icône pour les Unités
            label: 'Unités',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups), // Icône pour les Factions
            label: 'Factions',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}