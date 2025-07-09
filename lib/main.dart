// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/screens/collection_screen.dart';
import 'package:octominia/screens/dashboard_screen.dart';
import 'package:octominia/screens/games/games_screen.dart'; // Importez le GamesScreen

import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de sqflite_common_ffi pour le bureau
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialisation de la base de données et synchronisation
  await DatabaseHelper().database;
  await DatabaseHelper().synchronizeGameData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Octominia',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.amberAccent[200],
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.yellow,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.amberAccent[200],
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white, // Changed to white for dark theme visibility
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white60),
          headlineSmall: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white70,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.white,
          ),
        ),
        expansionTileTheme: ExpansionTileThemeData(
          backgroundColor: Colors.grey[800],
          collapsedBackgroundColor: Colors.grey[800],
          iconColor: Colors.redAccent,
          textColor: Colors.white,
          collapsedIconColor: Colors.white70,
          collapsedTextColor: Colors.white70,
        ),
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
  // L'index de l'onglet "Games" est 1 dans votre configuration actuelle.
  // Nous le sélectionnons par défaut.
  int _selectedIndex = 1;

  final PageStorageBucket _bucket = PageStorageBucket();

  // Déclarez une GlobalKey pour votre DashboardScreen
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey), // L'index 0
      const GamesScreen(), // L'index 1 : C'est celui-ci que nous voulons par défaut
      const CollectionScreen(), // L'index 2
    ];
  }

  // La méthode _onItemTapped est modifiée pour ne rien faire
  // si l'index n'est pas 1 (GamesScreen).
  void _onItemTapped(int index) {
    if (index == 1) { // Autoriser uniquement le clic sur l'onglet "Games"
      setState(() {
        _selectedIndex = index;
      });
      // Si l'onglet sélectionné est le Dashboard (index 0), déclenchez son rafraîchissement
      // Note : Comme Dashboard n'est plus sélectionnable, cette partie ne sera pas appelée
      // à moins que vous ne changiez la logique plus tard.
      // if (index == 0) {
      //   _dashboardKey.currentState?.refreshData();
      // }
    }
    // Pour les autres index (0 et 2), la fonction ne fait rien,
    // ce qui les rend non cliquables.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset), // Icône pour les jeux
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Collection',
          ),
        ],
        currentIndex: _selectedIndex,
        // Utilisez les couleurs pour désaturer les onglets non cliquables
        selectedItemColor: Theme.of(context).colorScheme.secondary, // Couleur normale pour l'onglet sélectionné
        unselectedItemColor: Colors.grey, // Couleur grisée pour les onglets non cliquables
        onTap: _onItemTapped, // Conservez le onTap
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}