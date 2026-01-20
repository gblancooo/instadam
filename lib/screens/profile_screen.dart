import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../database/db_helper.dart';
import 'user_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _photoController = TextEditingController();
  int _postCount = 0;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadPostCount();
  }

  Future<void> _loadPreferences() async {
    final displayName = await PreferencesService.getDisplayName();
    final photoPath = await PreferencesService.getProfilePhotoPath();
    setState(() {
      _nameController.text = displayName ?? widget.username;
      _photoController.text = photoPath ?? '';
      _photoPath = photoPath;
    });
  }

  Future<void> _loadPostCount() async {
    final posts = await DBHelper().getPostsByUsername(widget.username);
    setState(() {
      _postCount = posts.length;
    });
  }

  ImageProvider? _buildAvatarImage(String? path) {
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      try {
        return FileImage(File(path));
      } catch (_) {
        // fallthrough
      }
    }
    return null;
  }

  Future<void> _saveProfile() async {
    await PreferencesService.setDisplayName(_nameController.text.trim());
    final photo = _photoController.text.trim();
    await PreferencesService.setProfilePhotoPath(photo.isEmpty ? null : photo);
    setState(() {
      _photoPath = photo.isEmpty ? null : photo;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferencias guardadas')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _buildAvatarImage(_photoPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.purple.shade600,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Text(
                      widget.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre para mostrar',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _photoController,
              decoration: InputDecoration(
                labelText: 'Ruta/URL de la foto (opcional)',
                prefixIcon: const Icon(Icons.image_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Guardar preferencias'),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.post_add_outlined),
              title: const Text('Posts'),
              subtitle: Text('Has publicado $_postCount posts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserPostsScreen(username: widget.username),
                ));
                // refresh count when returning
                await _loadPostCount();
                if (result == true) {
                  // nothing for now
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
