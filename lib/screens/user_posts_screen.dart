import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';

class UserPostsScreen extends StatefulWidget {
  final String username;

  const UserPostsScreen({super.key, required this.username});

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = DBHelper().getPostsByUsername(widget.username);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadPosts();
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username} — Posts'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(child: Text('No hay posts de ${widget.username}'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: posts[index], currentUsername: widget.username);
              },
            ),
          );
        },
      ),
    );
  }
}
