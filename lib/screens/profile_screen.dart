import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController displayNameController = TextEditingController();

  int selectedAvatar = 0;

  final List<IconData> avatars = [
    Icons.fitness_center,
    Icons.local_fire_department,
    Icons.flash_on,
    Icons.sports_gymnastics,
    Icons.sports_kabaddi,
    Icons.directions_run,
    Icons.self_improvement,
    Icons.whatshot,
  ];

  final List<Color> avatarColors = [
    Color(0xFFE11D2E),
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      displayNameController.text = data['displayName'] ?? '';
      selectedAvatar = data['avatarIndex'] ?? 0;
      setState(() {});
    }
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': displayNameController.text.trim(),
      'avatarIndex': selectedAvatar,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  Widget buildAvatar(int index) {
    final isSelected = selectedAvatar == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAvatar = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: avatarColors[index].withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? avatarColors[index] : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(avatars[index], color: avatarColors[index], size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),

          // Avatar display
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: avatarColors[selectedAvatar].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                avatars[selectedAvatar],
                size: 40,
                color: avatarColors[selectedAvatar],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Choose Avatar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Wrap(
            children: List.generate(
              avatars.length,
              (index) => buildAvatar(index),
            ),
          ),

          const SizedBox(height: 20),

          const Text('Email'),
          const SizedBox(height: 6),
          Text(user?.email ?? ''),

          const SizedBox(height: 16),

          const Text('Display Name'),
          const SizedBox(height: 6),
          TextField(
            controller: displayNameController,
            decoration: const InputDecoration(hintText: 'Enter display name'),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D2E),
              ),
              onPressed: saveProfile,
              child: const Text('Save Profile'),
            ),
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (value) {
              widget.onThemeChanged(value);

              setState(() {});
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
