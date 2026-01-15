class Post {
  final int? id;
  final int userId;
  final String content;
  final String? imagePath;
  final String timestamp;
  final String? username;
  final int likeCount;
  final int commentCount;

  Post({
    this.id,
    required this.userId,
    required this.content,
    this.imagePath,
    required this.timestamp,
    this.username,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'imagePath': imagePath,
      'timestamp': timestamp,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      userId: map['userId'],
      content: map['content'],
      imagePath: map['imagePath'],
      timestamp: map['timestamp'],
      username: map['username'],
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
    );
  }
}

