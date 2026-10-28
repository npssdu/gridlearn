import 'package:flutter/material.dart';

import '../state/vocab_controller.dart';
import '../theme/app_theme.dart';

/// Formulario para agregar o editar una palabra.
///
/// Con [horizontal] los tres campos van en una fila (tablet); si no, apilados.
class WordForm extends StatefulWidget {
  const WordForm({super.key, required this.controller, this.horizontal = false});

  final VocabController controller;
  final bool horizontal;

  @override
  State<WordForm> createState() => _WordFormState();
}

class _WordFormState extends State<WordForm> {
  final _formKey = GlobalKey<FormState>();
  final _english = TextEditingController();
  final _spanish = TextEditingController();
  final _phonetic = TextEditingController();
  final _englishFocus = FocusNode();
  String? _loadedId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncWithEditing);
  }

  @override
  void didUpdateWidget(WordForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncWithEditing);
      widget.controller.addListener(_syncWithEditing);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncWithEditing);
    _english.dispose();
    _spanish.dispose();
    _phonetic.dispose();
    _englishFocus.dispose();
    super.dispose();
  }

  /// Carga la palabra en edición en los campos (o los vacía al cancelar).
  void _syncWithEditing() {
    final editing = widget.controller.editing;
    if (editing?.id == _loadedId) return;
    _loadedId = editing?.id;
    if (editing == null) {
      _clear();
    } else {
      _english.text = editing.english;
      _spanish.text = editing.spanish;
      _phonetic.text = editing.phonetic;
      _englishFocus.requestFocus();
    }
    setState(() {});
  }

  void _clear() {
    _english.clear();
    _spanish.clear();
    _phonetic.clear();
    _formKey.currentState?.reset();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final editing = widget.controller.editing;
    if (editing != null) {
      widget.controller.updateWord(
        editing.id,
        english: _english.text,
        spanish: _spanish.text,
        phonetic: _phonetic.text,
      );
    } else {
      widget.controller.addWord(
        english: _english.text,
        spanish: _spanish.text,
        phonetic: _phonetic.text,
      );
    }
    _loadedId = null;
    _clear();
    _englishFocus.requestFocus();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final editing = widget.controller.editing != null;

    final fields = [
      TextFormField(
        controller: _english,
        focusNode: _englishFocus,
        decoration: const InputDecoration(hintText: 'Palabra en inglés'),
        textInputAction: TextInputAction.next,
        validator: _required,
      ),
      TextFormField(
        controller: _spanish,
        decoration: const InputDecoration(hintText: 'Traducción al español'),
        textInputAction: TextInputAction.next,
        validator: _required,
      ),
      TextFormField(
        controller: _phonetic,
        decoration: const InputDecoration(hintText: 'Fonética / Pronunciación'),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
      ),
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.horizontal)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: fields[i]),
                ],
              ],
            )
          else
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              fields[i],
            ],
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand600,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
                ),
                child: Text(editing ? 'Actualizar' : 'Agregar'),
              ),
              if (editing) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: widget.controller.cancelEditing,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.slate700,
                    side: const BorderSide(color: AppColors.slate300),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
