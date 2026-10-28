# GridLearn (Flutter)

Bingo de vocabulario inglés ↔ español, portado desde la versión web original (React + Tailwind) a Flutter para **móvil, tablet y web** (más escritorio Windows).

## Funciones

- **Cuentas:** registro e inicio de sesión (correo y contraseña) con Supabase Auth, recuperación de contraseña y cierre de sesión. Cada usuario ve solo sus datos.
- **Título opcional** del vocabulario; aparece sobre la grilla y también al **imprimir / exportar a PDF**.
- **Guardar** vocabularios y volver a abrirlos o **repasarlos** (evaluación) desde *Mis vocabularios*.
- **Evaluación con fondo desenfocado:** al empezar, todo lo de atrás se desenfoca y oscurece para que no se vean las palabras.
- Alta, edición y baja de palabras (inglés, traducción, fonética), guardadas en local.
- Grilla de bingo 5 × 6 con casillas que se marcan al tocarlas. Cada palabra ocupa **una sola casilla**, por orden de llegada: la nueva va a la primera casilla libre (las libres muestran su número). Caben 30 palabras; las demás quedan solo en el listado.
- Cada una de las 6 filas tiene su propio color (`lib/theme/row_colors.dart`) para distinguirlas a simple vista.
- **Imprimir / PDF:** el botón sobre la grilla abre el cuadro de impresión o guarda un PDF con *solo* la grilla, tal como se ve (colores y casillas marcadas incluidos).
- **Evaluación lúdica** con 4 juegos (Aventura, Relámpago, Parejas y Bingo cantado) y preguntas al azar en ambos sentidos: opción múltiple, verdadero/falso, ordenar letras y escribir. Puntos, rachas, vidas, estrellas y repaso de las falladas. Ver [`docs/EVALUACION.md`](docs/EVALUACION.md).

## Diseño responsive

| Tamaño | Ancho | Diseño |
|---|---|---|
| Móvil | < 600 px | Una columna; evaluación en hoja inferior |
| Tablet | 600–1023 px | Una columna ancha, formulario en fila, listado a 2 columnas |
| Web / escritorio | ≥ 1024 px | Dos paneles: grilla a la izquierda, formulario y listado a la derecha |

Los puntos de corte viven en `lib/layout/breakpoints.dart`.

## Estructura

```
lib/
  main.dart, app.dart        arranque y MaterialApp
  models/word.dart           modelo (JSON compatible con la versión web)
  logic/                     grilla del bingo y normalización de texto
  services/auth/             autenticación (Supabase y modo local)
  services/*_repository.dart vocabularios guardados (Supabase y local)
  services/draft_storage.dart borrador local por usuario
  services/grid_exporter.dart captura de la grilla → PDF / impresión
  state/vocab_controller.dart estado (ChangeNotifier)
  layout/breakpoints.dart    móvil / tablet / web
  screens/                   login, pantalla principal adaptable, mis vocabularios
  widgets/                   formulario, grilla, listado, evaluación
```

## Diseño

El lenguaje visual (paleta, tipografía, formas, logo) sale del logo en `assets/logo/` y está descrito en [`docs/DISENO.md`](docs/DISENO.md).

## Base de datos y despliegue

El esquema relacional (PostgreSQL con seguridad por filas) está en `supabase/migrations/`. La guía completa para **Supabase + Vercel / Render**, con seguridad y checklist, está en [`docs/DESPLIEGUE.md`](docs/DESPLIEGUE.md).

Sin configurar Supabase la app arranca en **modo local** (sin cuentas, datos solo en el navegador).

## Comandos

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json   # web con Supabase (ver env.example.json)
flutter run -d chrome        # web en modo local, sin cuentas
flutter run                  # dispositivo/emulador
flutter test
flutter build web --release  # salida en build/web
```

> En Windows, compilar Android o escritorio exige activar el **Modo desarrollador**
> (`start ms-settings:developers`) para que Flutter pueda crear enlaces simbólicos.

Los iconos de lanzamiento se generan con `dart run flutter_launcher_icons` a partir de `assets/icon/`.
