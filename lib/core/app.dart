import 'package:flutter/material.dart';

/// Root application widget
///
/// This widget is the entry point of the application UI.
/// It configures the MaterialApp with theme, routes, and global settings.
class LingoDeskApp extends StatelessWidget {
  const LingoDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoDesk',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // TODO: Add home page when ready
      // home: const AppManagementDashboard(),
      home: const _PlaceholderHome(),
    );
  }

  /// Builds the application theme
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      // TODO: Customize theme as needed
      // appBarTheme: const AppBarTheme(...),
      // cardTheme: const CardTheme(...),
      // etc.
    );
  }
}

/// Placeholder home widget until the actual home page is implemented
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LingoDesk')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Welcome to LingoDesk',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Localization Management Tool',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
