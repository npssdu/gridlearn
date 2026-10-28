import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/adventure_session.dart';
import '../../game/answer_checker.dart';
import '../../game/game_result.dart';
import '../../models/word.dart';
import '../../theme/app_theme.dart';
import 'feedback_banner.dart';
import 'game_effects.dart';
import 'game_hud.dart';
import 'question_views.dart';

/// Juego "Aventura": cada palabra sube de nivel (elegir → ordenar → escribir).
class AdventureView extends StatefulWidget {
  const AdventureView({
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
  State<AdventureView> createState() => _AdventureViewState();
}

class _AdventureViewState extends State<AdventureView> {
  late final AdventureSession _session = AdventureSession(widget.words, random: widget.random);
  bool _answered = false;
  int _wrongCount = 0;

  void _onSubmit(String given) {
    setState(() {
      final verdict = _session.submit(given);
      _answered = true;
      if (verdict == Verdict.wrong) {
        _wrongCount++;
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _continue() {
    _session.next();
    if (_session.current == null) {
      widget.onFinished(_session.result());
      return;
    }
    setState(() => _answered = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = _session.current;
    if (q == null) return const SizedBox.shrink();
    final verdict = _session.lastVerdict;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameHud(
          onExit: widget.onExit,
          progress: _session.progress,
          score: _session.score,
          streak: _session.streak,
          trailing: Tooltip(
            message: 'Palabras dominadas',
            child: Text(
              '${_session.masteredCount}/${_session.totalWords}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navySoft),
            ),
          ),
        ),
        const SizedBox(height: 14),
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
        if (_answered && verdict != null) ...[
          const SizedBox(height: 10),
          FeedbackBanner(
            verdict: verdict,
            message: _session.lastFeedback,
            onContinue: _continue,
            continueLabel: _session.finished ? 'Ver resultados' : 'Continuar',
          ),
        ],
      ],
    );
  }
}
