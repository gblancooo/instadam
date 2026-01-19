import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'services/preferences_service.dart';
import 'database/db_helper.dart';

void main() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaDAM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeExampleData();
  }

  Future<void> _initializeExampleData() async {
    DBHelper dbHelper = DBHelper();
    
    // Verificar si ya hay posts de ejemplo
    List<Map<String, dynamic>> posts = await (await dbHelper.database).query('posts');
    
    // Si no hay posts, insertar datos de ejemplo
    if (posts.isEmpty) {
      try {
        // Buscar usuario blanco
        Map<String, dynamic>? demoUser = await dbHelper.getUserByUsername('blanco');
        
        if (demoUser == null) {
          await dbHelper.insertUser({
            'username': 'blanco',
            'password': 'blanco',
            'email': 'blanco@gmail.com',
          });
          demoUser = await dbHelper.getUserByUsername('blanco');
        }
        
        if (demoUser != null) {
          int demoUserId = demoUser['id'];
          
          // Insertar posts de ejemplo
          await dbHelper.insertPost({
            'userId': demoUserId,
            'content': 'Primer post INSTADAM ',
            'imagePath': 'https://s2.abcstatics.com/media/sociedad/2016/02/24/sindrome-down-anciano--620x349.jpg',
            'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          });
          
          await dbHelper.insertPost({
            'userId': demoUserId,
            'content': 'Segundo post INSTADAM ',
            'imagePath': 'assets/imagen2.png',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          });
          
          await dbHelper.insertPost({
            'userId': demoUserId,
            'content': 'Tercer post INSTADAM 🦽',
            'imagePath': 'assets/imagen3.png',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        print('Error inicializando datos de ejemplo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkRememberedUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return FutureBuilder<String?>(
            future: _getUsername(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (userSnapshot.data != null) {
                return FeedScreen(username: userSnapshot.data!);
              }
              return const LoginScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }

  Future<bool> _checkRememberedUser() async {
    return await PreferencesService.getRememberUser();
  }

  Future<String?> _getUsername() async {
    return await PreferencesService.getUsername();
  }
}
