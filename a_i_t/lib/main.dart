import 'package:a_i_t/firebase_options.dart';
import 'package:a_i_t/screens/auth.dart';
import 'package:a_i_t/screens/splash.dart';
import 'package:a_i_t/screens/teachers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

final theme = ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: Colors.lightBlueAccent, // Accent (buttons, highlights)
    secondary: Colors.cyanAccent, // Secondary accent
    surface: Colors.black, // Cards, dialogs, surfaces

    onPrimary:
        Colors.black, // Text/icons on primary (skyblue buttons → black text)
    onSecondary:
        Colors.black, // Text/icons on secondary (cyan buttons → black text)
    onSecondaryContainer: Color.fromARGB(255, 41, 40, 40),
    onSurface: Colors.white, // Text/icons on black surfaces → white
  ),
  scaffoldBackgroundColor: Colors.black,
  brightness: Brightness.dark,
  fontFamily: "Roboto",
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16),
    bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          if (snapshot.hasData) {
            return TeachersScreen();
          } else {
            return AuthScreen();
          }
        },
      ),
      theme: theme,
    );
  }
}
