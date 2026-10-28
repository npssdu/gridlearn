import 'package:flutter/material.dart';

import '../models/word.dart';
import '../theme/app_theme.dart';

/// Listado de palabras con acciones de editar y eliminar.
///
/// Con [scrollable] ocupa el alto disponible y desplaza su contenido (panel
/// lateral de escritorio); si no, crece con su contenido y [columns] reparte
/// las palabras en varias columnas (tablet).
class WordList extends StatelessWidget {
  const WordList({
    super.key,
    required this.words,
    required this.onEdit,
    required this.onDelete,
    this.columns = 1,
    this.scrollable = false,
  });

  final List<Word> words;
  final ValueChanged<Word> onEdit;
  final ValueChanged<Word> onDelete;
  final int columns;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final title = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text('Listado de Palabras', style: AppTheme.heading(20)),
    );

    if (words.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          title,
          const Text(
            'Aún no agregaste palabras.',
            style: TextStyle(fontSize: 14, color: AppColors.slate500),
          ),
        ],
      );
    }

    if (scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          Expanded(
            child: ListView.separated(
              itemCount: words.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _WordTile(
                word: words[i],
                onEdit: () => onEdit(words[i]),
                onDelete: () => onDelete(words[i]),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final word in words)
                  SizedBox(
                    width: width,
                    child: _WordTile(
                      word: word,
                      onEdit: () => onEdit(word),
                      onDelete: () => onDelete(word),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.onEdit,
    required this.onDelete,
  });

  final Word word;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.english,
                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2),
                ),
                Text(
                  word.phonetic.isEmpty ? 'sin fonética' : word.phonetic,
                  style: const TextStyle(fontSize: 14, color: AppColors.brand700),
                ),
                Text(
                  word.spanish,
                  style: const TextStyle(fontSize: 14, color: AppColors.slate600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Editar palabra',
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.slate600,
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Eliminar palabra',
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.slate600,
          ),
        ],
      ),
    );
  }
}
