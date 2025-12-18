import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'di/injection_container.dart' as di;

/// Bootstrap class responsible for initializing the application
/// before running the main app widget.
class Bootstrap {
  /// Initializes the app with required setup
  ///
  /// This method should be called before [runApp] to ensure
  /// all necessary initialization is complete.
  static Future<void> initialize() async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Set up error handling
    _setupErrorHandling();

    // Configure platform-specific settings
    _configurePlatform();

    // Initialize services (storage, etc.)
    await _initializeServices();
  }

  /// Sets up global error handling for the application
  static void _setupErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kReleaseMode) {
        // In production, you might want to log to a crash reporting service
        // Example: Firebase Crashlytics, Sentry, etc.
      }
    };

    // Handle asynchronous errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kReleaseMode) {
        // Log to crash reporting service in production
      }
      return true;
    };
  }

  /// Configures platform-specific settings
  static void _configurePlatform() {
    // Set preferred orientations (optional, customize as needed)
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);

    // Set system UI overlay style
    if (defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    }

    // Enable edge-to-edge on supported platforms
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  /// Initializes application services
  ///
  /// Add initialization for:
  /// - Local storage (Hive, SharedPreferences, etc.)
  /// - Dependency injection
  /// - Analytics
  /// - Other services
  static Future<void> _initializeServices() async {
    // Initialize dependency injection
    await di.init();

    // TODO: Initialize local storage
    // Example:
    // await Hive.initFlutter();
    // await SharedPreferences.getInstance();

    // TODO: Initialize other services
    // Example: Analytics, Crash reporting, etc.
  }
}
