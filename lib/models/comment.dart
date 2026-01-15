class Comment {
  final int? id;
  final int postId;
  final int userId;
  final String content;
  final String timestamp;
  final String? username;

  Comment({
    this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      postId: map['postId'],
      userId: map['userId'],
      content: map['content'],
      timestamp: map['timestamp'],
      username: map['username'],
    );
  }
}

