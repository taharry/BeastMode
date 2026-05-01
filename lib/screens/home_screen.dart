import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'log_workout_screen.dart';
import 'social_feed_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = const [
    'Dashboard',
    'Log Workout',
    'Social Feed',
    'Progress',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const LogWorkoutScreen(),
      const SocialFeedScreen(),
      const ProgressScreen(),
      ProfileScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Feed'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
