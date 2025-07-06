import 'package:flutter/material.dart';
import 'package:octominia/screens/factions_screen.dart'; // Nous allons créer ce fichier
import 'package:octominia/screens/units_screen.dart';    // Nous allons créer ce fichier
import 'package:octominia/screens/collection_screen.dart'; // Nous allons créer ce fichier

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Octominia',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white, // Couleur du texte de la barre
        ),
        // Personnalisation de la BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.deepOrange, // Couleur de l'icône sélectionnée
          unselectedItemColor: Colors.grey,     // Couleur des icônes non sélectionnées
          backgroundColor: Colors.blueGrey,      // Couleur de fond de la barre
        ),
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
  
  // Liste des écrans disponibles
  final List<Widget> _screens = [
    const UnitsScreen(),
    const FactionsScreen(),
    const CollectionScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Octominia'),
      ),
      body: _screens[_selectedIndex], // Affiche l'écran correspondant à l'index sélectionné
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Unités',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Factions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark),
            label: 'Ma Collection',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}