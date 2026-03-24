# Fase 0 - Investigacion previa: Feed accesible con TalkBack (InstaDAM)

## 1. Jerarquia y agrupacion semantica

Un lector de pantalla recorre el arbol de accesibilidad, no la interfaz visual como la vemos en pantalla. Por eso, si cada texto e icono queda suelto, TalkBack lo anuncia por separado y sin contexto.

En una card de feed, varios elementos visuales (autor, tiempo, imagen, descripcion, likes, comentarios) deben percibirse como una sola unidad de informacion. Si no se agrupan, la persona usuaria escucha fragmentos inconexos y pierde el significado de la publicacion.

Aplicado a InstaDAM:
- Una publicacion debe anunciarse primero como resumen completo.
- Despues, las acciones interactivas (Me gusta, Comentarios) deben anunciarse como controles separados y claros.

## 2. Elementos decorativos vs informativos

No todo lo visible debe leerse. Los elementos decorativos (iconos de adorno, separadores, icono de mas opciones sin accion relevante para la tarea principal) se deben excluir de la semantica.

Si TalkBack anuncia demasiados detalles irrelevantes:
- Aumenta la carga cognitiva.
- La navegacion es mas lenta.
- Se dificulta encontrar acciones importantes.

Aplicado a InstaDAM:
- Excluir iconos decorativos con ExcludeSemantics.
- Mantener en semantica lo que aporta significado (autor, contenido, recuentos y botones de accion).

## 3. Descripcion de imagenes (alt text)

Una imagen necesita descripcion alternativa porque una persona que no la ve debe poder entender su funcion o contexto.

Alt text (texto alternativo): descripcion breve y util de la imagen, orientada a la accion o al mensaje que transmite.

Una descripcion util debe ser:
- Especifica: evitar textos vacios como "imagen".
- Breve: no convertirla en parrafo largo.
- Contextual: conectada al contenido del post.

Aplicado a InstaDAM:
- Si hay imagen, anunciar "Imagen relacionada con: ..." usando el contenido del post como contexto.
- Si no hay imagen, anunciar "Publicacion sin imagen".

## 4. Botones con estado (Like)

Un boton con estado no solo ejecuta una accion, tambien tiene una condicion actual.

En "Me gusta":
- Estado desactivado -> accion posible: dar Me gusta.
- Estado activado -> accion posible: quitar Me gusta.

TalkBack debe anunciar:
- Que es un boton.
- Su estado actual (toggled activado/desactivado).
- La accion disponible.
- El numero de likes actual.

Aplicado a InstaDAM:
- Semantics(button: true, toggled: ...)
- value con contador de likes.
- hint diferente segun estado (dar/quitar Me gusta).

## 5. Cambios de estado y anuncios dinamicos

Cuando se da o se quita like, cambia el estado de la interfaz (icono, contador, estado del boton). Sin anuncio dinamico, la persona usuaria puede no percibir el cambio inmediatamente.

Por eso conviene anunciar cambios con region viva (live region) y/o anuncio explicito.

Aplicado a InstaDAM:
- Mostrar SnackBar con contenido en Semantics(liveRegion: true).
- Lanzar SemanticsService.announce con mensaje claro:
  - "Has dado Me gusta. Ahora hay X me gustas."
  - "Has quitado Me gusta. Ahora hay X me gustas."

## Checklist de validacion manual (TalkBack)

- Cada PostCard se entiende como unidad coherente.
- La imagen tiene etiqueta descriptiva.
- Iconos decorativos no se anuncian.
- El boton Me gusta anuncia estado y accion.
- El boton Comentarios anuncia el numero actual.
- Al dar/quitar like se anuncia el cambio.
- Es posible recorrer el feed sin mirar la pantalla y entender cada publicacion.

## Fuentes consultadas

1. Flutter Accessibility (official docs): https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
2. Flutter Semantics widget: https://api.flutter.dev/flutter/widgets/Semantics-class.html
3. Flutter MergeSemantics widget: https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html
4. Flutter ExcludeSemantics widget: https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html
5. Flutter SemanticsService.announce: https://api.flutter.dev/flutter/semantics/SemanticsService/announce.html
6. Android Accessibility (TalkBack): https://support.google.com/accessibility/android/answer/6283677
