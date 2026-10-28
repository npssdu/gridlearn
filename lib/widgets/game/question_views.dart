import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/question.dart';
import '../../logic/text_normalizer.dart';
import '../../theme/app_theme.dart';

/// Muestra una pregunta de cualquier tipo y avisa con [onSubmit] de la respuesta:
/// el texto de la opción elegida, las letras ordenadas, lo escrito o `true`/`false`.
///
/// Se crea una vista nueva por pregunta (con `key: ObjectKey(question)`).
/// Con [locked] las respuestas quedan bloqueadas y se revela cuál era la correcta.
class QuestionView extends StatefulWidget {
  const QuestionView({super.key, required this.question, required this.onSubmit, this.locked = false});

  final Question question;
  final ValueChanged<String> onSubmit;
  final bool locked;

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  String? _given;

  bool get _answered => widget.locked || _given != null;

  void _submit(String given) {
    if (_answered) return;
    setState(() => _given = given);
    HapticFeedback.selectionClick();
    widget.onSubmit(given);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DirectionLabel(direction: q.direction, text: _label(q)),
        const SizedBox(height: 10),
        switch (q.kind) {
          QuestionKind.trueFalse => _StatementCard(prompt: q.prompt, shown: q.shownAnswer),
          _ => _PromptCard(text: q.prompt),
        },
        const SizedBox(height: 16),
        switch (q.kind) {
          QuestionKind.multipleChoice => _MultipleChoice(question: q, given: _given, locked: _answered, onPick: _submit),
          QuestionKind.trueFalse => _TrueFalse(question: q, given: _given, locked: _answered, onPick: _submit),
          QuestionKind.scramble => _Scramble(question: q, locked: _answered, onDone: _submit),
          QuestionKind.type => _TypeAnswer(question: q, locked: _answered, onSubmit: _submit),
        },
      ],
    );
  }

  String _label(Question q) {
    switch (q.kind) {
      case QuestionKind.multipleChoice:
        return 'ELIGE LA TRADUCCIÓN';
      case QuestionKind.trueFalse:
        return '¿VERDADERO O FALSO?';
      case QuestionKind.scramble:
        return 'ORDENA LAS LETRAS';
      case QuestionKind.type:
        return 'ESCRIBE EN ${q.targetLanguage.toUpperCase()}';
    }
  }
}

/// Fichas de idioma (ES → EN o al revés, como las fichas A y B del logo) y la
/// etiqueta de la pregunta.
class DirectionLabel extends StatelessWidget {
  const DirectionLabel({super.key, required this.direction, required this.text});

  final Direction direction;
  final String text;

  @override
  Widget build(BuildContext context) {
    final toEnglish = direction == Direction.esToEn;
    const es = LangTile('ES', AppColors.amber);
    const en = LangTile('EN', AppColors.sky);
    return Row(
      children: [
        toEnglish ? es : en,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.navySoft),
        ),
        toEnglish ? en : es,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.navySoft,
            ),
          ),
        ),
      ],
    );
  }
}

class LangTile extends StatelessWidget {
  const LangTile(this.label, this.color, {super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.navy),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.sky50,
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
        border: Border.all(color: AppColors.sky100),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.heading(28, weight: FontWeight.w800),
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.prompt, required this.shown});

  final String prompt;
  final String shown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.sky50,
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
        border: Border.all(color: AppColors.sky100),
      ),
      child: Column(
        children: [
          Text(prompt, textAlign: TextAlign.center, style: AppTheme.heading(26)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('significa', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w700)),
          ),
          Text(shown, textAlign: TextAlign.center, style: AppTheme.heading(26, color: AppColors.navySoft)),
        ],
      ),
    );
  }
}

// --- Opción múltiple -------------------------------------------------------

const _optionColors = [AppColors.sky, AppColors.amber, AppColors.teal, AppColors.periwinkle];

class _MultipleChoice extends StatelessWidget {
  const _MultipleChoice({required this.question, required this.given, required this.locked, required this.onPick});

  final Question question;
  final String? given;
  final bool locked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 460 && question.options.length > 2;
        final width = twoColumns ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < question.options.length; i++)
              SizedBox(
                width: width,
                child: _OptionTile(
                  letter: String.fromCharCode(65 + i),
                  color: _optionColors[i % _optionColors.length],
                  text: question.options[i],
                  state: _stateOf(question.options[i]),
                  onTap: locked ? null : () => onPick(question.options[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  _OptionState _stateOf(String option) {
    if (!locked) return _OptionState.idle;
    if (normalizeText(option) == normalizeText(question.answer)) return _OptionState.correct;
    if (option == given) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.color,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final Color color;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color border;
    IconData? icon;
    switch (state) {
      case _OptionState.correct:
        background = AppColors.teal.withValues(alpha: 0.18);
        border = AppColors.teal;
        icon = Icons.check_circle_rounded;
      case _OptionState.wrong:
        background = AppColors.danger.withValues(alpha: 0.10);
        border = AppColors.danger;
        icon = Icons.cancel_rounded;
      case _OptionState.dimmed:
        background = Colors.white;
        border = AppColors.slate200;
      case _OptionState.idle:
        background = Colors.white;
        border = AppColors.slate300;
    }
    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.5 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.tile),
              border: Border.all(color: border, width: state == _OptionState.idle ? 1.5 : 2.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Text(letter, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Verdadero o falso -----------------------------------------------------

class _TrueFalse extends StatelessWidget {
  const _TrueFalse({required this.question, required this.given, required this.locked, required this.onPick});

  final Question question;
  final String? given;
  final bool locked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final correct = Question.trueFalseValue(question.isTrue);
    Widget button(String value, String label, IconData icon, Color color) {
      final isCorrect = locked && value == correct;
      final isWrong = locked && value == given && value != correct;
      return Expanded(
        child: Opacity(
          opacity: locked && !isCorrect && !isWrong ? 0.45 : 1,
          child: FilledButton.icon(
            onPressed: locked ? null : () => onPick(value),
            icon: Icon(isCorrect ? Icons.check_circle_rounded : (isWrong ? Icons.cancel_rounded : icon)),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.navy,
              disabledBackgroundColor: isCorrect ? AppColors.teal : (isWrong ? AppColors.danger : color),
              disabledForegroundColor: isWrong ? Colors.white : AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        button('true', 'Verdadero', Icons.check_rounded, AppColors.teal),
        const SizedBox(width: 10),
        button('false', 'Falso', Icons.close_rounded, AppColors.rose),
      ],
    );
  }
}

// --- Ordenar letras --------------------------------------------------------

class _Scramble extends StatefulWidget {
  const _Scramble({required this.question, required this.locked, required this.onDone});

  final Question question;
  final bool locked;
  final ValueChanged<String> onDone;

  @override
  State<_Scramble> createState() => _ScrambleState();
}

class _ScrambleState extends State<_Scramble> {
  /// Índices (de `question.letters`) en el orden en que se colocaron.
  final List<int> _placed = [];

  List<String> get _letters => widget.question.letters;

  void _place(int index) {
    if (widget.locked || _placed.contains(index)) return;
    setState(() => _placed.add(index));
    HapticFeedback.selectionClick();
    if (_placed.length == _letters.length) {
      widget.onDone(_placed.map((i) => _letters[i]).join());
    }
  }

  void _remove(int position) {
    if (widget.locked || position >= _placed.length) return;
    setState(() => _placed.removeAt(position));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.locked) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace && _placed.isNotEmpty) {
      _remove(_placed.length - 1);
      return KeyEventResult.handled;
    }
    final ch = event.character?.toUpperCase();
    if (ch != null && ch.length == 1) {
      for (var i = 0; i < _letters.length; i++) {
        if (_letters[i] == ch && !_placed.contains(i)) {
          _place(i);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final n = _letters.length;
    final correct = widget.question.answer.toUpperCase().split('');
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        children: [
          // Casillas de la respuesta (como las celdas del logo).
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < n; i++)
                _Slot(
                  key: ValueKey('slot-$i'),
                  letter: i < _placed.length ? _letters[_placed[i]] : null,
                  color: _optionColors[i % _optionColors.length],
                  revealOk: widget.locked && i < _placed.length ? _letters[_placed[i]] == correct[i] : null,
                  onTap: i < _placed.length ? () => _remove(i) : null,
                ),
            ],
          ),
          const SizedBox(height: 18),
          // Bandeja de letras.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < n; i++)
                _TrayTile(
                  key: ValueKey('tray-$i'),
                  letter: _letters[i],
                  color: _optionColors[i % _optionColors.length],
                  used: _placed.contains(i),
                  onTap: () => _place(i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.locked || _placed.isEmpty ? null : () => _remove(_placed.length - 1),
            icon: const Icon(Icons.backspace_outlined, size: 18),
            label: const Text('Borrar'),
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({super.key, required this.letter, required this.color, required this.revealOk, required this.onTap});

  final String? letter;
  final Color color;

  /// Tras responder: true si esta letra está bien colocada.
  final bool? revealOk;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = letter == null
        ? Colors.transparent
        : (revealOk == null ? color : (revealOk! ? AppColors.teal : AppColors.rose));
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          border: Border.all(color: letter == null ? AppColors.navySoft.withValues(alpha: 0.5) : bg, width: 2),
        ),
        child: Text(
          letter ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy),
        ),
      ),
    );
  }
}

class _TrayTile extends StatelessWidget {
  const _TrayTile({super.key, required this.letter, required this.color, required this.used, required this.onTap});

  final String letter;
  final Color color;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: used ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: used ? 0.18 : 1,
        child: Container(
          width: 48,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            boxShadow: used
                ? null
                : [BoxShadow(color: AppColors.navy.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Text(
            letter,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

// --- Escribir --------------------------------------------------------------

class _TypeAnswer extends StatefulWidget {
  const _TypeAnswer({required this.question, required this.locked, required this.onSubmit});

  final Question question;
  final bool locked;
  final ValueChanged<String> onSubmit;

  @override
  State<_TypeAnswer> createState() => _TypeAnswerState();
}

class _TypeAnswerState extends State<_TypeAnswer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (widget.locked) return;
    widget.onSubmit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !widget.locked,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(hintText: 'Tu respuesta'),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: widget.locked ? null : _send,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
          child: const Text('Comprobar'),
        ),
      ],
    );
  }
}
