# Evaluación lúdica

La evaluación es ahora un pequeño juego con **cuatro modos**. Todos preguntan al azar
sobre las palabras del vocabulario abierto; el fondo se desenfoca mientras se juega para
que no se vean las palabras (ver `docs/DISENO.md`).

Se abre con **Comenzar Evaluación** o con **Evaluar** en *Mis vocabularios*.

## Los juegos

| Juego | Palabras mínimas | Cómo funciona |
|---|---|---|
| **Aventura** | 1 | Elige hasta 8 palabras al azar. Cada una sube de nivel: **elegir** la traducción → **ordenar las letras** → **escribirla**. Al fallar baja de nivel y vuelve más tarde. Termina cuando todas están dominadas. |
| **Relámpago** | 2 | 60 segundos de preguntas rápidas (opción múltiple y verdadero/falso). Cada 3 aciertos seguidos sube el combo (hasta x4); fallar resta 5 segundos. |
| **Parejas** | 3 | Une hasta 6 palabras en inglés con su traducción. Cada error resta puntos; las parejas resueltas toman un color. |
| **Bingo cantado** | 3 | Cantamos una palabra en español y se busca su traducción en el **cartón** (la grilla). Se gana al completar una fila (o columna) o todo el cartón; 3 vidas. |

### Tipos de pregunta

- **Opción múltiple**: 4 opciones (menos si hay pocas palabras), con distractores tomados de otras palabras del vocabulario.
- **Verdadero o falso**: «*Sun* significa *Sol*» o con la traducción de otra palabra.
- **Ordenar las letras**: fichas de letras mezcladas; se arma tocando (o con el teclado) y se corrige tocando una letra puesta.
- **Escribir**: ignora tildes y mayúsculas. Un error de **una letra** en palabras de 5 o más letras cuenta como acierto parcial («¡Casi!») y muestra la forma correcta.

Las preguntas salen en **ambos sentidos** (español → inglés e inglés → español).
Las palabras de varias palabras («Jelly Beans») no se usan para ordenar letras.

### Lúdico

Puntos y estrellas, rachas con llama, combos, vidas con corazones, barra de
progreso, mensajes de ánimo, sacudida al fallar, confeti al lograr 2–3 estrellas y
vibración suave en móvil. Al final: estrellas, puntos, aciertos, mejor racha, tiempo y
**las palabras para repasar**, con el botón **Repasar falladas** (una Aventura solo con ellas).

## Por qué estos formatos

Resumen de lo que se encontró al investigar (fuentes abajo):

- **Recordar con esfuerzo fija más que reconocer.** Elegir una opción sirve para empezar a
  asociar palabra y significado, pero escribir o armar la palabra retiene más. Por eso Aventura
  empieza reconociendo y termina produciendo.
- **El espaciado importa.** Repetir seguido rinde en el momento pero retiene menos a largo plazo;
  las palabras falladas vuelven *después* de otras preguntas (no de inmediato) y con más peso.
- **Practicar en ambos sentidos** refuerza el recuerdo.
- **Dificultad adaptativa** (más preguntas sobre lo que cuesta) y **un poco de presión de tiempo**
  mantienen el esfuerzo y las ganas de seguir (enfoque de Vocabulary.com, Kahoot o Quizlet).

Fuentes: [Memdora, tarjetas con repetición espaciada (arXiv)](https://arxiv.org/pdf/2607.25096) ·
[Tesis de Nakata: recuerdo vs. reconocimiento y espaciado](https://ir.wgtn.ac.nz/items/5278988f-b1f8-472a-8a79-774d9d5c6842/full) ·
[Vocabulary.com, ciencia del aprendizaje](https://www.vocabulary.com/articles/under-the-hood/want-to-learn-vocab-try-two-methods-that-actually-work) ·
[Kahoot: aprendizaje de vocabulario basado en juegos](https://kahoot.com/blog/2026/07/10/game-based-learning-vocabulary/).
Algunas son preprints o publicaciones de empresas; no compararon directamente estos formatos entre sí,
así que el diseño combina varios en lugar de apostar por uno.

## Otras formas de evaluar (ideas para después)

- **Escuchar y escribir** (dictado) y **pronunciar** con reconocimiento de voz: requieren audio.
- **Repetición espaciada entre sesiones**: guardar el nivel de cada palabra y repasar solo las que toca (tipo Leitner).
- **Completar la frase**: la palabra dentro de una oración con un hueco.
- **Ahorcado** y **sopa de letras** con las palabras del vocabulario.
- **Modo dos jugadores** o retos con un código para compartir.
- **Récords** y racha de días por vocabulario.

## Dónde está en el código

```
lib/game/                  lógica pura y probada (sin Flutter)
  question.dart            tipos de pregunta
  question_factory.dart    genera preguntas al azar
  answer_checker.dart      corrige (tildes, "casi")
  adventure_session.dart   niveles y repetición espaciada
  blitz_session.dart       cuenta atrás y combos
  match_round.dart         parejas
  bingo_session.dart       cartón, vidas y líneas
lib/widgets/game/          pantallas: menú, cada juego, resultados, efectos
test/game_engine_test.dart motor (con semillas fijas)
test/game_ui_test.dart     juegos completos desde la interfaz
```
