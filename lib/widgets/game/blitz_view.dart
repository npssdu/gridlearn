import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/answer_checker.dart';
import '../../game/blitz_session.dart';
import '../../game/game_result.dart';
import '../../models/word.dart';
import '../../theme/app_theme.dart';
import 'game_effects.dart';
import 'game_hud.dart';
import 'question_views.dart';

/// Juego "Relámpago": contrarreloj con combos. Fallar resta tiempo.
class BlitzView extends StatefulWidget {
  const BlitzView({
    super.key,
    required this.words,
    required this.onFinished,
    required this.onExit,
    this.random,
    this.duration = const Duration(seconds: 60),
  });

  final List<Word> words;
  final ValueChanged<GameResult> onFinished;
  final VoidCallback onExit;
  final Random? random;
  final Duration duration;

  @override
  State<BlitzView> createState() => _BlitzViewState();
}

class _BlitzViewState extends State<BlitzView> {
  static const _tick = Duration(milliseconds: 100);
  static const _reveal = Duration(milliseconds: 650);

  late final BlitzSession _session =
      BlitzSession(widget.words, random: widget.random, duration: widget.duration);
  Timer? _timer;
  Timer? _revealTimer;
  bool _answered = false;
  int _wrongCount = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted || _done) return;
      setState(() => _session.tick(_tick));
      _checkFinished();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  void _checkFinished() {
    if (_done || !_session.finished) return;
    _done = true;
    _timer?.cancel();
    _revealTimer?.cancel();
    widget.onFinished(_session.result());
  }

  void _onSubmit(String given) {
    if (_done) return;
    setState(() {
      final verdict = _session.submit(given);
      _answered = true;
      if (verdict == Verdict.wrong) {
        _wrongCount++;
        HapticFeedback.mediumImpact();
      }
    });
    _checkFinished();
    if (_done) return;
    _revealTimer = Timer(_reveal, () {
      if (!mounted || _done) return;
      setState(() {
        _session.next();
        _answered = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _session.current;
    if (q == null) return const SizedBox.shrink();
    final seconds = (_session.remaining.inMilliseconds / 1000).ceil();
    final urgent = _session.timeFraction < 0.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameHud(
          onExit: widget.onExit,
          progress: _session.timeFraction,
          progressColor: urgent ? AppColors.danger : AppColors.amber,
          score: _session.score,
          streak: _session.streak,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: urgent ? AppColors.danger : AppColors.navy,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 15, color: Colors.white),
                const SizedBox(width: 3),
                Text('${seconds}s', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Combo x${_session.multiplier}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _session.multiplier > 1 ? AppColors.orange : AppColors.slate400,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            child: Shake(
              shakes: _wrongCount,
              child: QuestionView(
                key: ObjectKey(q),
                question: q,
                locked: _answered,
                onSubmit: _onSubmit,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
