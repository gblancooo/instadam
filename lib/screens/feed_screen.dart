import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  final String username;

  const FeedScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed - $username'),
      ),
      body: const Center(
        child: Text('Welcome to the Feed!'),
      ),
    );
  }
}