import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

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

    if (!mounted) return;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(6),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: avatarColors[index].withOpacity(isSelected ? 0.3 : 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? avatarColors[index] : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Icon(avatars[index], color: avatarColors[index], size: 28),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: child,
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
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: avatarColors[selectedAvatar].withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: avatarColors[selectedAvatar].withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    avatars[selectedAvatar],
                    size: 44,
                    color: avatarColors[selectedAvatar],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayNameController.text.trim().isNotEmpty
                      ? displayNameController.text.trim()
                      : 'Beast User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHOOSE AVATAR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFE11D2E),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  children: List.generate(
                    avatars.length,
                    (index) => buildAvatar(index),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSection(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DISPLAY NAME',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFE11D2E),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saveProfile,
                    child: const Text(
                      'SAVE PROFILE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSection(
            context: context,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D2E).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dark_mode,
                        color: Color(0xFFE11D2E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeColor: const Color(0xFFE11D2E),
                      onChanged: (value) {
                        widget.onThemeChanged(value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE11D2E),
                      side: const BorderSide(color: Color(0xFFE11D2E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
