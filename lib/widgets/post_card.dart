import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool isLiked = false;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likeCount;
    commentCount = widget.post.commentCount;
    _initializeLikeStatus();
  }

  Future<void> _initializeLikeStatus() async {
    final user = await DBHelper().getUserByUsername(widget.currentUsername);
    if (user != null && widget.post.id != null) {
      currentUserId = user['id'];
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

  String _getImageDescription() {
    if (widget.post.imagePath == null || widget.post.imagePath!.isEmpty) {
      return 'Publicación sin imagen';
    }

    final trimmedContent = widget.post.content.trim();
    if (trimmedContent.isEmpty) {
      return 'Imagen de la publicación';
    }

    final summary = trimmedContent.length > 90
        ? '${trimmedContent.substring(0, 90)}...'
        : trimmedContent;
    return 'Imagen relacionada con: $summary';
  }

  String _buildPostSummary() {
    final author = widget.post.username ?? 'Usuario';
    final time = _formatDate(widget.post.timestamp);
    final content = widget.post.content.trim().isEmpty
        ? 'Sin descripción'
        : widget.post.content.trim();

    return 'Publicación de $author, $time. '
        '$content. '
        '$likeCount ${likeCount == 1 ? "me gusta" : "me gustas"}, '
        '$commentCount ${commentCount == 1 ? "comentario" : "comentarios"}.';
  }

  void _announceLikeChange(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Semantics(
          liveRegion: true,
          child: Text(message),
        ),
      ),
    );

    SemanticsService.announce(message, Directionality.of(context));
  }

  Future<void> _toggleLike() async {
    if (currentUserId == null || widget.post.id == null) {
      return;
    }

    try {
      if (isLiked) {
        await DBHelper().removeLike(widget.post.id!, currentUserId);
        setState(() {
          likeCount = (likeCount - 1).clamp(0, 999999);
          isLiked = false;
        });
        _announceLikeChange('Has quitado Me gusta. Ahora hay $likeCount me gustas.');
      } else {
        await DBHelper().insertLike(widget.post.id!, currentUserId);
        setState(() {
          likeCount++;
          isLiked = true;
        });
        _announceLikeChange('Has dado Me gusta. Ahora hay $likeCount me gustas.');
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
    final postSummary = _buildPostSummary();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Semantics(
              container: true,
              readOnly: true,
              label: postSummary,
              child: ExcludeSemantics(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        ExcludeSemantics(
                          child: Icon(Icons.more_vert, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    image: true,
                    label: _getImageDescription(),
                    child: ExcludeSemantics(
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey[300],
                        child: widget.post.imagePath != null &&
                                widget.post.imagePath!.isNotEmpty
                            ? Image.asset(
                                widget.post.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: ExcludeSemantics(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: ExcludeSemantics(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
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
                ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  button: true,
                  toggled: isLiked,
                  label: 'Me gusta',
                  value: isLiked ? 'Activado. $likeCount me gustas' : 'Desactivado. $likeCount me gustas',
                  hint: isLiked
                      ? 'Doble toque para quitar Me gusta'
                      : 'Doble toque para dar Me gusta',
                  onTap: _toggleLike,
                  child: ExcludeSemantics(
                    child: Material(
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
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Comentarios',
                  value: '$commentCount ${commentCount == 1 ? "comentario" : "comentarios"}',
                  hint: 'Doble toque para abrir comentarios',
                  child: ExcludeSemantics(
                    child: Material(
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
