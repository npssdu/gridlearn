import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/bingo_session.dart';
import '../../game/game_result.dart';
import '../../logic/grid_builder.dart';
import '../../models/word.dart';
import '../../theme/app_theme.dart';
import '../../theme/row_colors.dart';
import 'game_effects.dart';
import 'game_hud.dart';

/// Juego "Bingo cantado": se canta una palabra en español y hay que tocar su
/// traducción en el cartón (la grilla del vocabulario).
class BingoView extends StatefulWidget {
  const BingoView({
    super.key,
    required this.words,
    required this.onFinished,
    required this.onExit,
    this.random,
  });

  final List<Word> words;
  final ValueChanged<GameResult> onFinished;
  final VoidCallback onExit;
  final Random? random;

  @override
  State<BingoView> createState() => _BingoViewState();
}

class _BingoViewState extends State<BingoView> {
  late final BingoSession _session = BingoSession(widget.words, random: widget.random);
  Timer? _end;
  final Map<int, int> _shakes = {};
  int _callShakes = 0;

  @override
  void dispose() {
    _end?.cancel();
    super.dispose();
  }

  void _tap(int index) {
    if (_session.finished) return;
    final outcome = _session.tap(index);
    if (outcome == TapOutcome.ignored) return;
    setState(() {
      if (outcome == TapOutcome.wrong) {
        _shakes[index] = (_shakes[index] ?? 0) + 1;
        _callShakes++;
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    });
    if (_session.finished) {
      _end = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) widget.onFinished(_session.result());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final call = s.currentCall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameHud(
          onExit: widget.onExit,
          progress: s.occupiedCount == 0 ? 0 : s.marked.length / s.occupiedCount,
          progressColor: AppColors.orange,
          score: s.correct * 100,
          streak: s.streak,
          trailing: Hearts(lives: s.lives, max: s.maxLives),
        ),
        const SizedBox(height: 12),
        Shake(
          shakes: _callShakes,
          child: _CallCard(call: call, bingo: s.bingo, lost: s.lost),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 6.0;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: s.board.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    mainAxisExtent: 62,
                  ),
                  itemBuilder: (context, i) {
                    final slot = s.board[i];
                    return Shake(
                      shakes: _shakes[i] ?? 0,
                      child: _BoardCell(
                        slot: slot,
                        marked: s.marked.contains(i),
                        winning: s.winningCells.contains(i),
                        onTap: () => _tap(i),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({required this.call, required this.bingo, required this.lost});

  final GridSlot? call;
  final bool bingo;
  final bool lost;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;
    final Color background;
    if (bingo) {
      title = '¡BINGO!';
      subtitle = 'Completaste una línea';
      background = AppColors.amber;
    } else if (lost) {
      title = '¡Sin vidas!';
      subtitle = 'Se acabó la partida';
      background = AppColors.rose.withValues(alpha: 0.25);
    } else {
      title = call?.spanish ?? '';
      subtitle = 'Toca su traducción en el cartón';
      background = AppColors.sky50;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(title),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.card - 4),
          border: Border.all(color: bingo ? AppColors.amber : AppColors.sky100),
        ),
        child: Column(
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navySoft)),
            const SizedBox(height: 2),
            Text(title, textAlign: TextAlign.center, style: AppTheme.heading(28, weight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({required this.slot, required this.marked, required this.winning, required this.onTap});

  final GridSlot slot;
  final bool marked;
  final bool winning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = rowPalette[slot.row % rowPalette.length];
    final radius = BorderRadius.circular(AppRadii.tile - 2);
    if (slot.isPlaceholder) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.border.withValues(alpha: 0.6), width: 2),
        ),
      );
    }
    return Material(
      color: marked ? colors.marked : colors.tint,
      borderRadius: radius,
      child: InkWell(
        onTap: marked ? null : onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: winning ? AppColors.navy : (marked ? colors.marked : colors.border),
              width: winning ? 3 : 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  slot.english,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
              if (marked)
                const Positioned(
                  top: -2,
                  right: -2,
                  child: Icon(Icons.check_circle_rounded, size: 14, color: AppColors.navy),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
