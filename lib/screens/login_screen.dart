import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/preferences_service.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import 'feed_screen.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final ValueChanged<String>? onLanguageChanged;
  final VoidCallback? onLogout;

  const LoginScreen({
    super.key,
    this.onThemeChanged,
    this.onLanguageChanged,
    this.onLogout,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  
  late FocusNode _usernameFocus;
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;
  late FocusNode _loginButtonFocus;
  late FocusNode _registerButtonFocus;
  
  bool _rememberUser = false;
  String _usernameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _globalError = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameFocus = FocusNode();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
    _loginButtonFocus = FocusNode();
    _registerButtonFocus = FocusNode();
    _loadRememberedUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _loginButtonFocus.dispose();
    _registerButtonFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedUser() async {
    bool remember = await PreferencesService.getRememberUser();
    if (remember) {
      String? username = await PreferencesService.getUsername();
      if (username != null) {
        setState(() {
          _usernameController.text = username;
          _rememberUser = true;
        });
      }
    }
  }

  void _clearFieldErrors() {
    setState(() {
      _usernameError = '';
      _emailError = '';
      _passwordError = '';
      _globalError = '';
    });
  }

  void _announceError(String message) {
    SemanticsService.announce(message);
  }

  Future<void> _handleLogin() async {
    _clearFieldErrors();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Validación de campos
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'El usuario es obligatorio';
      });
      _usernameFocus.requestFocus();
      _announceError('El usuario es obligatorio');
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'La contraseña es obligatoria';
      });
      _passwordFocus.requestFocus();
      _announceError('La contraseña es obligatoria');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check user in database
      Map<String, dynamic>? userMap = await DBHelper().getUserByUsername(username);
      if (userMap != null && userMap['password'] == password) {
        // Login successful
        if (_rememberUser) {
          await PreferencesService.setUsername(username);
          await PreferencesService.setRememberUser(true);
        } else {
          await PreferencesService.setRememberUser(false);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FeedScreen(
                username: username,
                currentLanguage: 'es',
                onThemeChanged: widget.onThemeChanged ?? (_) {},
                onLanguageChanged: widget.onLanguageChanged ?? (_) {},
                onLogout: widget.onLogout ?? () {},
              ),
            ),
          );
        }
      } else {
        setState(() {
          _globalError = 'Usuario o contraseña inválidos';
        });
        _announceError('Usuario o contraseña inválidos');
      }
    } catch (e) {
      setState(() {
        _globalError = 'Error al iniciar sesión: ${e.toString()}';
      });
      _announceError(_globalError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    _clearFieldErrors();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String email = _emailController.text.trim();

    // Validación de campos
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'El usuario es obligatorio';
      });
      _usernameFocus.requestFocus();
      _announceError('El usuario es obligatorio');
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _emailError = 'El correo es obligatorio';
      });
      _emailFocus.requestFocus();
      _announceError('El correo es obligatorio');
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'La contraseña es obligatoria';
      });
      _passwordFocus.requestFocus();
      _announceError('La contraseña es obligatoria');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already exists
      Map<String, dynamic>? existingUser = await DBHelper().getUserByUsername(username);
      if (existingUser != null) {
        setState(() {
          _usernameError = 'El usuario ya existe';
        });
        _usernameFocus.requestFocus();
        _announceError('El usuario ya existe');
        return;
      }

      // Insert new user
      User newUser = User(username: username, password: password, email: email);
      int result = await DBHelper().insertUser(newUser.toMap());
      if (result > 0) {
        setState(() {
          _globalError = 'Registro exitoso. Por favor, inicia sesión.';
          _usernameController.clear();
          _passwordController.clear();
          _emailController.clear();
        });
        _announceError('Registro completado exitosamente');
      } else {
        setState(() {
          _globalError = 'Error al registrarse. Intenta de nuevo.';
        });
        _announceError('Error al registrarse');
      }
    } catch (e) {
      setState(() {
        _globalError = 'Error durante el registro: ${e.toString()}';
      });
      _announceError(_globalError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              isDarkTheme ? Colors.purple[900]! : Colors.purple,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Semantics(
                      label: 'InstaDAM Login',
                      child: Text(
                        'INSTA-DAM',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Bienvenido de vuelta!',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkTheme ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Anunciador de errores globales (Live Region)
                    Semantics(
                      liveRegion: true,
                      label: _globalError.isNotEmpty ? _globalError : 'Sin errores',
                      enabled: _globalError.isNotEmpty,
                      child: _globalError.isNotEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                border: Border.all(color: Colors.red, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _globalError,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    
                    // Campo Usuario
                    Semantics(
                      label: 'Campo de usuario',
                      textField: true,
                      enabled: !_isLoading,
                      child: TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _emailFocus.requestFocus();
                        },
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: const Icon(Icons.person),
                          errorText: _usernameError.isNotEmpty ? _usernameError : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo Email
                    Semantics(
                      label: 'Campo de correo electrónico',
                      textField: true,
                      enabled: !_isLoading,
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _passwordFocus.requestFocus();
                        },
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email),
                          errorText: _emailError.isNotEmpty ? _emailError : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo Contraseña
                    Semantics(
                      label: 'Campo de contraseña',
                      textField: true,
                      enabled: !_isLoading,
                      child: TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          _loginButtonFocus.requestFocus();
                        },
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          errorText: _passwordError.isNotEmpty ? _passwordError : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Switch Recordarme
                    Semantics(
                      label: 'Recordarme',
                      onTap: () {
                        setState(() {
                          _rememberUser = !_rememberUser;
                        });
                      },
                      enabled: !_isLoading,
                      toggled: _rememberUser,
                      child: Row(
                        children: [
                          Switch(
                            value: _rememberUser,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _rememberUser = value;
                                    });
                                  },
                          ),
                          Semantics(
                            label: _rememberUser ? 'Recordarme activado' : 'Recordarme desactivado',
                            child: Text(
                              'Recordarme',
                              style: TextStyle(
                                color: isDarkTheme ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Botones de Acción
                    Row(
                      children: [
                        // Botón Login
                        Expanded(
                          child: Semantics(
                            button: true,
                            enabled: !_isLoading,
                            label: _isLoading
                                ? 'Iniciar sesión, por favor espera'
                                : 'Iniciar sesión',
                            child: ElevatedButton(
                              focusNode: _loginButtonFocus,
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 48),
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Botón Registrarse
                        Expanded(
                          child: Semantics(
                            button: true,
                            enabled: !_isLoading,
                            label: 'Registrarse',
                            child: OutlinedButton(
                              focusNode: _registerButtonFocus,
                              onPressed: _isLoading ? null : _handleRegister,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 48),
                                disabledForegroundColor: Colors.grey,
                              ),
                              child: Text(
                                'Registrarse',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _isLoading ? Colors.grey : primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}