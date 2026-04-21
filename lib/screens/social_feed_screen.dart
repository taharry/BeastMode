import 'package:flutter/material.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  final List<Map<String, String>> posts = const [
    {
      'user': 'Alex',
      'workout': 'Completed Chest Day - 4 exercises',
      'time': '2 hours ago',
    },
    {
      'user': 'Jordan',
      'workout': 'Ran 3 miles and logged cardio session',
      'time': '5 hours ago',
    },
    {
      'user': 'Sam',
      'workout': 'Finished Leg Day with new squat PR',
      'time': '1 day ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(post['user'] ?? ''),
            subtitle: Text(post['workout'] ?? ''),
            trailing: Text(
              post['time'] ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
