import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Global Firebase Auth instance - using this instead of FirebaseAuth.instance directly helps avoid type cast errors
late final FirebaseAuth firebaseAuth;

void main() async {
  // Catch all Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print('Flutter error caught: ${details.exception}');
  };

  // Catch all Dart errors that aren't caught elsewhere
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase only if not on web platform
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized successfully');

        // Initialize global Firebase Auth instance
        firebaseAuth = FirebaseAuth.instance;
      } catch (e) {
        print('Failed to initialize Firebase: $e');
      }
    } else {
      print('Web platform detected - Firebase initialization skipped');
    }

    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    print('Dart error caught: $error');
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Travel Journal',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: kIsWeb ? const WebPlatformMessage() : const SignInScreen(),
      routes: {},
    );
  }
}

class WebPlatformMessage extends StatelessWidget {
  const WebPlatformMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.device_unknown,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Web Platform Not Supported',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This app currently only supports mobile platforms. Please run the app on Android or iOS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
