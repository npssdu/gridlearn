import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/game_result.dart';
import '../../layout/breakpoints.dart';
import '../../models/word.dart';
import '../../theme/app_theme.dart';
import 'adventure_view.dart';
import 'bingo_view.dart';
import 'blitz_view.dart';
import 'game_menu.dart';
import 'match_view.dart';
import 'results_view.dart';

/// Abre el modo evaluación. Todo lo que hay detrás se desenfoca y oscurece para
/// que no se vean las palabras mientras se juega: hoja inferior en móvil,
/// tarjeta centrada en tablet y web.
Future<void> showQuiz(
  BuildContext context,
  List<Word> words,
  ScreenSize size, {
  Random? random,
}) {
  final compact = size.isCompact;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Evaluación',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) {
      void close() => Navigator.of(dialogContext).pop();
      final media = MediaQuery.of(dialogContext);
      // Alto fijo para que el panel no "salte" entre menú, juego y resultados.
      final available =
          media.size.height -
          media.viewInsets.bottom -
          media.padding.vertical -
          (compact ? 0 : 32);
      final height = min(compact ? available * 0.96 : 760.0, available);
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
        // Con foco propio, Escape funciona también en el menú (sin campos de texto).
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              const Positioned.fill(child: QuizBackdrop()),
              SafeArea(
                child: Align(
                  alignment: compact
                      ? Alignment.bottomCenter
                      : Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? double.infinity : 700,
                      ),
                      child: SizedBox(
                        height: height,
                        child: Material(
                          color: Colors.white,
                          elevation: 12,
                          borderRadius: compact
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(AppRadii.card),
                                )
                              : BorderRadius.circular(AppRadii.card),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            child: GameShell(
                              words: words,
                              onClose: close,
                              random: random,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: compact ? const Offset(0, 0.12) : const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Desenfoque fuerte + capa oscura: las palabras de atrás no se pueden leer.
class QuizBackdrop extends StatelessWidget {
  const QuizBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(color: AppColors.navy.withValues(alpha: 0.62)),
      ),
    );
  }
}

enum _Phase { menu, playing, results }

/// Controla el recorrido: menú → juego → resultados (→ otra partida).
class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.words,
    required this.onClose,
    this.random,
  });

  final List<Word> words;
  final VoidCallback onClose;
  final Random? random;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  _Phase _phase = _Phase.menu;
  GameMode _mode = GameMode.adventure;
  List<Word> _playWords = const [];
  GameResult? _result;

  /// Cambia en cada partida para crear una vista (y sesión) nueva.
  int _gameId = 0;

  void _start(GameMode mode, {List<Word>? only}) {
    setState(() {
      _mode = mode;
      _playWords = only ?? widget.words;
      _result = null;
      _gameId++;
      _phase = _Phase.playing;
    });
  }

  void _toMenu() => setState(() => _phase = _Phase.menu);

  void _finish(GameResult result) {
    setState(() {
      _result = result;
      _phase = _Phase.results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (_phase) {
      case _Phase.menu:
        child = GameMenu(
          key: const ValueKey('menu'),
          wordCount: widget.words.length,
          onPick: _start,
          onClose: widget.onClose,
        );
      case _Phase.playing:
        child = KeyedSubtree(key: ValueKey('game$_gameId'), child: _gameView());
      case _Phase.results:
        final result = _result!;
        child = ResultsView(
          key: ValueKey('results$_gameId'),
          result: result,
          onPlayAgain: () => _start(_mode, only: _playWords),
          onMenu: _toMenu,
          onReviewMissed: result.missed.isEmpty
              ? null
              : () => _start(GameMode.adventure, only: result.missed),
        );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: child,
    );
  }

  Widget _gameView() {
    switch (_mode) {
      case GameMode.adventure:
        return AdventureView(
          words: _playWords,
          onFinished: _finish,
          onExit: _toMenu,
          random: widget.random,
        );
      case GameMode.blitz:
        return BlitzView(
          words: _playWords,
          onFinished: _finish,
          onExit: _toMenu,
          random: widget.random,
        );
      case GameMode.match:
        return MatchView(
          words: _playWords,
          onFinished: _finish,
          onExit: _toMenu,
          random: widget.random,
        );
      case GameMode.bingo:
        return BingoView(
          words: _playWords,
          onFinished: _finish,
          onExit: _toMenu,
          random: widget.random,
        );
    }
  }
}
