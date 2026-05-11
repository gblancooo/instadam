import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import '../services/translations.dart';
import 'login_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class FeedScreen extends StatefulWidget {
  final String username;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLogout;
  final String currentLanguage;

  const FeedScreen({
    super.key,
    required this.username,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onLogout,
    this.currentLanguage = 'es',
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Post>> _postsFuture;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.currentLanguage;
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = DBHelper().getAllPosts();
  }

  void _refreshPosts() {
    setState(() {
      _loadPosts();
    });
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(username: widget.username),
      ),
    );
    
    if (result == true) {
      _refreshPosts();
    }
  }

  Future<void> _navigateToSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SettingsScreen(
        onThemeChanged: (isDark) {
          widget.onThemeChanged(isDark);
        },
        onLanguageChanged: (language) {
          setState(() {
            _currentLanguage = language;
          });
          widget.onLanguageChanged(language);
        },
        onLogout: () {
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
            widget.onLogout();
          }
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = (String key) => Translations.translate(key, _currentLanguage);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _navigateToSettings,
        ),
        title: const Text('INSTA-DAM'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade600,
                Colors.pink.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPosts,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _navigateToCreatePost,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ProfileScreen(username: widget.username),
              ));
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar los posts',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('no_posts'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('create_post'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          List<Post> posts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _refreshPosts();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            displacement: 40,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(
                  post: posts[index],
                  currentUsername: widget.username,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: Colors.pink.shade500,
        child: const Icon(Icons.add),
      ),
    );
  }
}
