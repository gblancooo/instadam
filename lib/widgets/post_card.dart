import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../database/db_helper.dart';
import '../screens/comments_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String currentUsername;

  const PostCard({Key? key, required this.post, required this.currentUsername}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likeCount;
  late int commentCount;
  late bool isLiked;
  late int currentUserId;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likeCount;
    commentCount = widget.post.commentCount;
    _initializeLikeStatus();
  }

  Future<void> _initializeLikeStatus() async {
    // Obtener el userId del usuario actual
    final user = await DBHelper().getUserByUsername(widget.currentUsername);
    if (user != null && widget.post.id != null) {
      currentUserId = user['id'];
      // Verificar si el usuario ya le dio like
      final likes = await (await DBHelper().database).query(
        'likes',
        where: 'postId = ? AND userId = ?',
        whereArgs: [widget.post.id!, currentUserId],
      );
      setState(() {
        isLiked = likes.isNotEmpty;
      });
    }
  }

  Widget _buildImageWidget(String path) {
    final uri = Uri.tryParse(path);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image,
              size: 80,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }

    if (!kIsWeb && (uri != null && (uri.scheme == 'file' || path.startsWith('/')) || path.contains('storage')) ) {
      try {
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.broken_image,
                size: 80,
                color: Colors.grey[400],
              ),
            );
          },
        );
      } catch (_) {
        // Fallback a asset si falla
      }
    }

    // Por defecto intentamos como asset
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.grey[400],
          ),
        );
      },
    );
  }

  Future<void> _toggleLike() async {
    if (widget.post.id == null) return;

    try {
      if (isLiked) {
        // Eliminar like
        await DBHelper().removeLike(widget.post.id!, currentUserId);
        setState(() {
          likeCount--;
          isLiked = false;
        });
      } else {
        // Agregar like
        await DBHelper().insertLike(widget.post.id!, currentUserId);
        setState(() {
          likeCount++;
          isLiked = true;
        });
      }
    } catch (e) {
      print('Error al cambiar like: $e');
    }
  }

  String _formatDate(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();
      Duration difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Hace unos segundos';
      } else if (difference.inMinutes < 60) {
        return 'Hace ${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return 'Hace ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays}d';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return widget.post.timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Usuario y fecha
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.username ?? 'Usuario',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(widget.post.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.more_vert, color: Colors.grey[600]),
              ],
            ),
          ),
          // Imagen
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[300],
            child: widget.post.imagePath != null && widget.post.imagePath!.isNotEmpty
                ? _buildImageWidget(widget.post.imagePath!)
                : Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
          ),
          // Descripción
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.post.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          // Botones de likes y comentarios
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón de like
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey[700],
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likeCount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Botón de comentarios
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CommentsScreen(
                            post: widget.post,
                            currentUsername: widget.currentUsername,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            color: Colors.grey[700],
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ver comentarios ($commentCount)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
