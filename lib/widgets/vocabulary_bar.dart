import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_repository.dart';
import '../state/vocab_controller.dart';
import '../theme/app_theme.dart';
import 'dialogs.dart';

/// Título opcional del vocabulario y sus acciones: guardar, abrir los
/// guardados ("Mis vocabularios") y empezar uno nuevo.
class VocabularyBar extends StatefulWidget {
  const VocabularyBar({super.key, required this.controller, required this.onOpenSaved});

  final VocabController controller;
  final VoidCallback onOpenSaved;

  @override
  State<VocabularyBar> createState() => _VocabularyBarState();
}

class _VocabularyBarState extends State<VocabularyBar> {
  late final TextEditingController _title = TextEditingController(text: widget.controller.title);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncTitle);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTitle);
    _title.dispose();
    super.dispose();
  }

  /// Refleja en el campo los cambios que vienen de fuera (abrir o crear uno nuevo).
  void _syncTitle() {
    final title = widget.controller.title;
    if (_title.text != title) {
      _title.value = TextEditingValue(
        text: title,
        selection: TextSelection.collapsed(offset: title.length),
      );
    }
  }

  Future<void> _save() async {
    final controller = widget.controller;
    if (controller.words.isEmpty) {
      showMessage(context, 'Agrega al menos una palabra antes de guardar.');
      return;
    }
    try {
      await controller.save();
      if (mounted) showMessage(context, 'Vocabulario guardado.');
    } on RepositoryException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _startNew() async {
    final controller = widget.controller;
    if (!await confirmDiscardChanges(context, controller, action: 'empezar uno nuevo')) return;
    controller.startNew();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _title,
          onChanged: controller.setTitle,
          maxLength: maxTitleLength,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Título del vocabulario (opcional)',
            counterText: '',
            prefixIcon: Icon(Icons.title, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: controller.saving ? null : _save,
              icon: controller.saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onOpenSaved,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Mis vocabularios'),
              style: _outlined,
            ),
            OutlinedButton.icon(
              onPressed: _startNew,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo'),
              style: _outlined,
            ),
            _SaveStatus(controller: controller),
          ],
        ),
      ],
    );
  }

  static final _outlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.slate700,
    side: const BorderSide(color: AppColors.slate300),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
  );
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.controller});

  final VocabController controller;

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    final Color color;
    if (controller.saving) {
      text = 'Guardando…';
      icon = Icons.sync;
      color = AppColors.slate500;
    } else if (controller.isSaved) {
      text = 'Guardado';
      icon = Icons.check_circle_outline;
      color = const Color(0xFF16A34A);
    } else if (controller.hasContent) {
      text = 'Sin guardar';
      icon = Icons.edit_note;
      color = const Color(0xFFB45309);
    } else {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
