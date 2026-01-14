import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'services/preferences_service.dart';

void main() {
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
