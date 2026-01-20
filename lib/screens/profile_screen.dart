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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.purple.shade600,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                widget.username.isNotEmpty ? widget.username.substring(0, 1).toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : widget.username,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '@' + widget.username,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              InkWell(
                                onTap: () async {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => UserPostsScreen(username: widget.username),
                                  ));
                                  await _loadPostCount();
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$_postCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('Posts', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton(
                                onPressed: () => _showEditModal(),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade500),
                                child: const Text('Editar perfil'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Información y controles
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600),
                            child: const Text('Guardar preferencias'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre para mostrar'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _photoController,
                  decoration: const InputDecoration(labelText: 'Ruta/URL de la foto (opcional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _saveProfile();
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
