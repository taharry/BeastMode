import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BeastModeApp());
}

class BeastModeApp extends StatefulWidget {
  const BeastModeApp({super.key});

  @override
  State<BeastModeApp> createState() => _BeastModeAppState();
}

class _BeastModeAppState extends State<BeastModeApp> {
  bool isDarkMode = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? true;
      isLoading = false;
    });
  }

  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);

    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF080808),
      primaryColor: const Color(0xFFE11D2E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE11D2E),
        secondary: Color(0xFFFFF3F3),
        surface: Color(0xFF151515),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF080808),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardColor: const Color(0xFF151515),
      dividerColor: const Color(0xFF2A2A2A),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: const Color(0xFFE11D2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2D2D2D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2D2D2D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE11D2E), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE11D2E),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF101010),
        selectedItemColor: Color(0xFFE11D2E),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
    );

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F2F2),
      primaryColor: const Color(0xFFD90429),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD90429),
        secondary: Color(0xFF111111),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F2F2),
        foregroundColor: Color(0xFF111111),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF111111),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFD9D3D3),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.black45),
        labelStyle: const TextStyle(color: Colors.black87),
        prefixIconColor: const Color(0xFFD90429),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2DCDC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2DCDC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD90429), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD90429),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFD90429),
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
      ),
    );

    return MaterialApp(
      title: 'Beast Mode',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: darkTheme,
      theme: lightTheme,
      home: currentUser == null
          ? LoginScreen(isDarkMode: isDarkMode, onThemeChanged: toggleTheme)
          : HomeScreen(isDarkMode: isDarkMode, onThemeChanged: toggleTheme),
    );
  }
}
