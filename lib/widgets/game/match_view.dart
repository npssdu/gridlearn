import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/game_result.dart';
import '../../game/match_round.dart';
import '../../models/word.dart';
import '../../theme/app_theme.dart';
import 'game_effects.dart';
import 'game_hud.dart';

const _pairColors = [
  AppColors.sky,
  AppColors.amber,
  AppColors.teal,
  AppColors.orange,
  AppColors.periwinkle,
  AppColors.rose,
];

/// Juego "Parejas": une cada palabra en inglés con su traducción.
class MatchView extends StatefulWidget {
  const MatchView({
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
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  late final MatchRound _round = MatchRound(widget.words, random: widget.random);
  Timer? _clock;
  Timer? _pending;
  final Map<String, int> _shakes = {};
  Set<String> _flash = {};

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_round.finished) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pending?.cancel();
    super.dispose();
  }

  bool get _busy => _flash.isNotEmpty || _round.finished;

  void _tap(String id, {required bool leftSide}) {
    if (_busy) return;
    final outcome = leftSide ? _round.selectLeft(id) : _round.selectRight(id);
    setState(() {});
    switch (outcome) {
      case MatchOutcome.match:
        HapticFeedback.selectionClick();
        if (_round.finished) {
          _clock?.cancel();
          _pending = Timer(const Duration(milliseconds: 900), () {
            if (mounted) widget.onFinished(_round.result());
          });
        }
      case MatchOutcome.mismatch:
        HapticFeedback.mediumImpact();
        final ids = {_round.selectedLeft!, _round.selectedRight!};
        setState(() {
          _flash = ids;
          for (final i in ids) {
            _shakes[i] = (_shakes[i] ?? 0) + 1;
          }
        });
        _pending = Timer(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          setState(() {
            _round.clearSelection();
            _flash = {};
          });
        });
      case MatchOutcome.none:
        break;
    }
  }

  String _time(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final r = _round;
    final score = max(0, r.matched.length * 100 - r.mistakes * 25);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameHud(
          onExit: widget.onExit,
          progress: r.matched.length / r.pairs.length,
          progressColor: AppColors.teal,
          score: score,
          trailing: Text(
            _time(r.elapsed),
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navySoft),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Une cada palabra con su traducción',
          textAlign: TextAlign.center,
          style: AppTheme.heading(18),
        ),
        if (r.mistakes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${r.mistakes} ${r.mistakes == 1 ? 'error' : 'errores'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w700),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _column(r.left, leftSide: true)),
                const SizedBox(width: 12),
                Expanded(child: _column(r.right, leftSide: false)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _column(List<Word> words, {required bool leftSide}) {
    return Column(
      children: [
        for (final w in words)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Shake(
              shakes: _shakes[w.id] ?? 0,
              child: _MatchTile(
                text: leftSide ? w.english : w.spanish,
                state: _stateOf(w.id, leftSide),
                color: _pairColors[_round.pairs.indexWhere((p) => p.id == w.id) % _pairColors.length],
                onTap: () => _tap(w.id, leftSide: leftSide),
              ),
            ),
          ),
      ],
    );
  }

  _TileState _stateOf(String id, bool leftSide) {
    if (_round.matched.contains(id)) return _TileState.matched;
    if (_flash.contains(id)) return _TileState.wrong;
    final selected = leftSide ? _round.selectedLeft : _round.selectedRight;
    return selected == id ? _TileState.selected : _TileState.idle;
  }
}

enum _TileState { idle, selected, matched, wrong }

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.text, required this.state, required this.color, required this.onTap});

  final String text;
  final _TileState state;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color border;
    switch (state) {
      case _TileState.matched:
        background = color;
        border = color;
      case _TileState.selected:
        background = AppColors.sky50;
        border = AppColors.sky;
      case _TileState.wrong:
        background = AppColors.danger.withValues(alpha: 0.12);
        border = AppColors.danger;
      case _TileState.idle:
        background = Colors.white;
        border = AppColors.slate300;
    }
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.tile),
      child: InkWell(
        onTap: state == _TileState.matched ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(color: border, width: state == _TileState.idle ? 1.5 : 2.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
              if (state == _TileState.matched) const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}
