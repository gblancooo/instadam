import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'services/preferences_service.dart';
import 'services/translations.dart';
import 'database/db_helper.dart';

void main() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;
  String _currentLanguage = 'es';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isDark = await PreferencesService.isDarkTheme();
    final language = await PreferencesService.getLanguage();
    
    setState(() {
      _isDarkTheme = isDark;
      _currentLanguage = language;
    });
  }

  void _updateTheme(bool isDark) {
    setState(() {
      _isDarkTheme = isDark;
    });
  }

  void _updateLanguage(String language) {
    setState(() {
      _currentLanguage = language;
    });
  }

  void _logout() {
    // Navegar a LoginScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaDAM',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: AuthWrapper(
        onThemeChanged: _updateTheme,
        onLanguageChanged: _updateLanguage,
        onLogout: _logout,
        currentLanguage: _currentLanguage,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLogout;
  final String currentLanguage;

  const AuthWrapper({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onLogout,
    required this.currentLanguage,
  });

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
            'imagePath': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Benjamin_Netanyahu%2C_February_2023.jpg/960px-Benjamin_Netanyahu%2C_February_2023.jpg',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          });
          
          await dbHelper.insertPost({
            'userId': demoUserId,
            'content': 'Tercer post INSTADAM 🦽',
            'imagePath': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTDO4gQ1xlWlx9HSvZux-uDYgJf4k3ugsAzdA&s',
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
                return FeedScreen(
                  username: userSnapshot.data!,
                  onThemeChanged: widget.onThemeChanged,
                  onLanguageChanged: widget.onLanguageChanged,
                  onLogout: widget.onLogout,
                  currentLanguage: widget.currentLanguage,
                );
              }
              return LoginScreen(
                onThemeChanged: widget.onThemeChanged,
                onLanguageChanged: widget.onLanguageChanged,
                onLogout: widget.onLogout,
              );
            },
          );
        }
        return LoginScreen(
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
          onLogout: widget.onLogout,
        );
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
