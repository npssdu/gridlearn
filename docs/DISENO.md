# Lenguaje de diseño de GridLearn

Todo sale del logo (`assets/logo/gridlearn_logo.svg`): una **grilla de celdas
redondeadas** sobre azul marino, con tres **fichas** de colores (A, birrete, B) y la
palabra *Grid* en azul marino + *Learn* en naranja.

La idea que guía la interfaz: **la grilla es el producto**. Las celdas vacías son
solo contorno; cuando se llenan se convierten en fichas de color.

## Logo y recursos

| Archivo | Uso |
|---|---|
| `assets/logo/gridlearn_logo.svg` | Logo completo (icono + palabra). Pantallas de acceso. |
| `assets/logo/gridlearn_mark.svg` | Solo el icono. Encabezado, evaluación, favicon. |
| `assets/icon/icon.png` | Icono de aplicación (esquinas redondeadas). |
| `assets/icon/icon_foreground.svg/png` | Primer plano del icono adaptable de Android. |
| `assets/icon/icon_maskable.svg` | Icono "maskable" a sangre (PWA). |

El SVG es una vectorización de la imagen original: la geometría simple (cuerpo,
celdas, fichas) está dibujada con las medidas exactas del logo y las letras, el
birrete y la palabra están trazados con Potrace. En código se usan los widgets de
`lib/widgets/brand_logo.dart`: `BrandMark`, `BrandLogo`, `BrandWordmark` y `BrandLockup`.

Los iconos PNG de `web/icons`, `web/favicon.png` y los de Android/iOS/Windows se
generan desde estos SVG (`dart run flutter_launcher_icons` para los de plataforma).

## Color

Medidos del logo (`lib/theme/app_theme.dart`, clase `AppColors`):

| Token | Valor | Rol |
|---|---|---|
| `navy` | `#1F325C` | Texto, acciones principales, superficies oscuras, "Grid" |
| `navySoft` | `#3F5B8B` | Contorno de celdas vacías, textos secundarios, fonética |
| `sky` | `#43B0EB` | Ficha A. Foco de los campos, información |
| `amber` | `#FFB322` | Ficha del birrete. Resaltado |
| `teal` | `#41C9AF` | Ficha B. Éxito |
| `orange` | `#FF7512` | "Learn". **Acento**: la acción llamativa (Comenzar Evaluación) |

Para tener 6 filas distintas se amplía la paleta con `periwinkle` `#7B8CEA` y
`rose` `#F2698E`, de brillo y saturación similares a las fichas.

Neutros (`slate50`…`slate700`) son grises fríos con matiz del azul marino; el texto
principal es `navy`, no negro. Reglas:

- **Una acción principal por zona**: `navy` para guardar/entrar; `orange` solo para
  la llamada a la acción de la pantalla (evaluar).
- **Texto sobre color de ficha**: siempre `navy` (el blanco sobre ámbar no tiene
  contraste suficiente). El blanco solo se usa sobre `navy`.
- **Estados**: éxito `success`, aviso `warning`, error `danger` (no se usa rojo puro).

### Las 6 filas de la grilla

Orden: `sky`, `amber`, `teal` (las fichas del logo, en su orden), `orange`,
`periwinkle`, `rose`. De cada color base (`RowColors.fromBase`) salen:

- **Celda vacía**: solo contorno (`border`), como las celdas vacías del logo, con su número.
- **Celda con palabra**: fondo `tint` (color + 84 % blanco) y borde `border`.
- **Celda marcada**: la **ficha llena** con el color pleno, borde del mismo color y un check `navy`.

## Tipografía

**Nunito** (Google Fonts): sans redondeada de terminales suaves, la más cercana a la
palabra del logo.

- Marca y títulos: Nunito 800–900 (`AppTheme.heading`). El logotipo de texto
  (`BrandWordmark`) usa 900 con "Grid" en `navy` y "Learn" en `orange`.
- Texto y controles: Nunito 400–800 (`ThemeData.textTheme`; botones en 800).

## Forma

Las esquinas del logo son generosas (≈21 % del lado en el icono y ≈22 % en las fichas):

| Token | Valor | Uso |
|---|---|---|
| `AppRadii.tile` | 14 | Casillas de la grilla, fichas, filas del listado |
| `AppRadii.control` | 14 | Botones y campos de texto |
| `AppRadii.card` | 24 | Tarjetas, diálogos y la hoja de evaluación |
| `AppRadii.pill` | 999 | Chips y la cuenta |

Trazos: 2 px en celdas vacías y marcadas, 1,5 px en las demás; campos con foco en
2 px `sky`.

## Superficies y profundidad

- Fondo: `slate50` con un halo `sky` arriba a la izquierda y otro `orange` abajo a la
  derecha, muy suaves.
- Tarjetas: blanco al 92 %, borde blanco y sombra `navy` al 10 % (blur 30).
- **Evaluación**: lo de atrás se desenfoca (σ 18) y se cubre con `navy` al 62 %, de modo
  que ninguna palabra se lee. Es el equivalente a la superficie oscura del logo.
- La pregunta muestra dos **fichas de idioma** (ES ámbar → EN azul, o al revés),
  como las fichas A y B del logo.

## Responsive

Móvil (< 600), tablet (600–1023) y web/escritorio (≥ 1024) en `lib/layout/breakpoints.dart`.
En móvil el menú de cuenta muestra solo el avatar y el logo se reduce para caber.

## Dónde vive cada cosa

```
lib/theme/app_theme.dart     colores, radios, ThemeData y estilos de título
lib/theme/row_colors.dart    paleta de las 6 filas
lib/widgets/brand_logo.dart  logo, icono y palabra
```

Cualquier color o radio nuevo debe salir de estos archivos, no escribirse suelto.
