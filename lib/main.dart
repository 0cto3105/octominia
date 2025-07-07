// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:octominia/database/database_helper.dart';
import 'package:octominia/screens/collection_screen.dart';
import 'package:octominia/screens/dashboard_screen.dart';

import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
            color: Colors.black,
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
  int _selectedIndex = 0; // Index de l'onglet sélectionné (0 correspondra au Dashboard)
  final PageStorageBucket _bucket = PageStorageBucket(); // Pour préserver l'état de défilement

  // Déclarez une GlobalKey pour votre DashboardScreen
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();

  // LISTE DES ÉCRANS : INVERSÉ L'ORDRE
  // Passez la GlobalKey au DashboardScreen
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey), // Associez la GlobalKey
      const CollectionScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Si l'onglet sélectionné est le Dashboard, déclenchez son rafraîchissement
    if (index == 0) {
      // Vérifiez que la key est attachée et que l'état existe
      _dashboardKey.currentState?.refreshData();
    }
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
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Collection',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}