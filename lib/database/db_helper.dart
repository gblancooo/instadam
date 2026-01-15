import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';
import '../models/comment.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'instadam.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
      )
    ''');

    // Create posts table
    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        content TEXT,
        imagePath TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create comments table
    await db.execute('''
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (postId) REFERENCES posts (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create likes table
    await db.execute('''
      CREATE TABLE likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (postId) REFERENCES posts (id),
        FOREIGN KEY (userId) REFERENCES users (id),
        UNIQUE(postId, userId)
      )
    ''');
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int?> getUserIdByUsername(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      columns: ['id'],
    );
    return result.isNotEmpty ? result.first['id'] : null;
  }

  // Post operations
  Future<int> insertPost(Map<String, dynamic> post) async {
    Database db = await database;
    return await db.insert('posts', post);
  }

  Future<List<Post>> getPostsByUsername(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        p.id, 
        p.userId, 
        p.content, 
        p.imagePath, 
        p.timestamp,
        u.username,
        (SELECT COUNT(*) FROM likes WHERE postId = p.id) as likeCount,
        (SELECT COUNT(*) FROM comments WHERE postId = p.id) as commentCount
      FROM posts p
      JOIN users u ON p.userId = u.id
      WHERE u.username = ?
      ORDER BY p.timestamp DESC
    ''', [username]);
    
    return result.map((map) => Post.fromMap(map)).toList();
  }

  Future<List<Post>> getAllPosts() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        p.id, 
        p.userId, 
        p.content, 
        p.imagePath, 
        p.timestamp,
        u.username,
        (SELECT COUNT(*) FROM likes WHERE postId = p.id) as likeCount,
        (SELECT COUNT(*) FROM comments WHERE postId = p.id) as commentCount
      FROM posts p
      JOIN users u ON p.userId = u.id
      ORDER BY p.timestamp DESC
    ''');
    
    return result.map((map) => Post.fromMap(map)).toList();
  }

  Future<List<Comment>> getCommentsByPostId(int postId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        c.id,
        c.postId,
        c.userId,
        c.content,
        c.timestamp,
        u.username
      FROM comments c
      JOIN users u ON c.userId = u.id
      WHERE c.postId = ?
      ORDER BY c.timestamp DESC
    ''', [postId]);
    
    return result.map((map) => Comment.fromMap(map)).toList();
  }

  Future<int> insertComment(Map<String, dynamic> comment) async {
    Database db = await database;
    return await db.insert('comments', comment);
  }

  Future<int> getLikeCount(int postId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'likes',
      where: 'postId = ?',
      whereArgs: [postId],
    );
    return result.length;
  }

  Future<int> insertLike(int postId, int userId) async {
    Database db = await database;
    return await db.insert(
      'likes',
      {'postId': postId, 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> removeLike(int postId, int userId) async {
    Database db = await database;
    return await db.delete(
      'likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
  }

  // Add more methods as needed for posts, comments, likes
}
