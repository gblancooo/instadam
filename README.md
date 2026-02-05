# InstaDAM

Una aplicación de red social construida con Flutter.

## Descripción del Proyecto

InstaDAM es una red social donde los usuarios pueden:

- Iniciar sesión con usuario y contraseña
- Crear y compartir posts
- Dar likes a posts
- Comentar en posts
- Ver el perfil de otros usuarios
- Configurar sus preferencias

## Instalación

### Requisitos

- Flutter 3.9.2 o superior
- Dart (incluido en Flutter)

### Pasos

1. Clona o descarga el proyecto:
   ```
   cd instadam
   ```

2. Instala las dependencias:
   ```
   flutter pub get
   ```

3. Ejecuta la aplicación:
   ```
   flutter run
   ```

Para ejecutar en web:
```
flutter run -d web
```

## Estructura del Proyecto

```
lib/
├── main.dart                     
├── database/
│   └── db_helper.dart            
├── models/
│   ├── user.dart                
│   ├── post.dart                 
│   └── comment.dart              
├── screens/
│   ├── login_screen.dart        
│   ├── feed_screen.dart          
│   ├── profile_screen.dart       
│   ├── create_post_screen.dart  
│   ├── comments_screen.dart      
│   └── settings_screen.dart      
├── services/
│   └── preferences_service.dart 
└── widgets/
    ├── post_card.dart          
    ├── comment_tile.dart         
    └── like_button.dart          
```

## Funcionalidades Implementadas

- **Login**: Autenticación con usuario y contraseña
- **Posts**: Crear, ver y eliminar posts
- **Likes**: Dar o quitar likes a posts
- **Comentarios**: Agregar comentarios a posts
- **Perfil**: Ver información del usuario y sus posts
- **Configuración**: Ajustes de la aplicación
- **Base de datos**: Almacenamiento local con SQLite
- **Multiplataforma**: Funciona en Android, iOS, Web, Windows, macOS y Linux
