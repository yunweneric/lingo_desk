import 'package:flutter/material.dart';
import 'core/bootstrap.dart';
import 'core/app.dart';

/// Application entry point
///
/// This function initializes the app using the Bootstrap class
/// and then runs the LingoDeskApp widget.
void main() async {
  // Initialize app services and configuration
  await Bootstrap.initialize();

  // Run the application
  runApp(const LingoDeskApp());
}
