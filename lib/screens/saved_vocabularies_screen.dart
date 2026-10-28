import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_repository.dart';
import '../state/vocab_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';

/// Qué eligió la persona al salir de "Mis vocabularios".
enum SavedAction { opened, evaluate }

/// Lista de vocabularios guardados para abrirlos, repasarlos (evaluación) o borrarlos.
class SavedVocabulariesScreen extends StatefulWidget {
  const SavedVocabulariesScreen({super.key, required this.controller});

  final VocabController controller;

  @override
  State<SavedVocabulariesScreen> createState() => _SavedVocabulariesScreenState();
}

class _SavedVocabulariesScreenState extends State<SavedVocabulariesScreen> {
  late Future<List<VocabularySummary>> _future = widget.controller.listSaved();
  bool _busy = false;

  void _reload() {
    final next = widget.controller.listSaved();
    setState(() {
      _future = next;
    });
  }

  Future<void> _open(VocabularySummary item, SavedAction action) async {
    final controller = widget.controller;
    if (_busy) return;
    if (controller.id != item.id &&
        !await confirmDiscardChanges(context, controller, action: 'abrir otro vocabulario')) {
      return;
    }
    setState(() => _busy = true);
    try {
      // Si ya está abierto y sin cambios no hace falta volver a cargarlo.
      if (controller.id != item.id || controller.hasUnsavedWork) {
        await controller.openSaved(item.id);
      }
      if (mounted) Navigator.of(context).pop(action);
    } on RepositoryException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, e.message);
      }
    }
  }

  Future<void> _delete(VocabularySummary item) async {
    final ok = await confirmDialog(
      context,
      title: 'Eliminar vocabulario',
      message: '¿Eliminar "${item.displayTitle}" (${item.wordCount} ${item.wordCount == 1 ? 'palabra' : 'palabras'})? '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await widget.controller.deleteSaved(item.id);
      if (mounted) {
        _reload();
        showMessage(context, 'Vocabulario eliminado.');
      }
    } on RepositoryException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Volver',
                        ),
                        const SizedBox(width: 4),
                        Text('Mis vocabularios', style: AppTheme.heading(26)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<List<VocabularySummary>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            final error = snapshot.error;
                            return _Message(
                              icon: Icons.error_outline,
                              text: error is RepositoryException
                                  ? error.message
                                  : 'No se pudieron cargar tus vocabularios.',
                              action: FilledButton(onPressed: _reload, child: const Text('Reintentar')),
                            );
                          }
                          final items = snapshot.data ?? const [];
                          if (items.isEmpty) {
                            return const _Message(
                              icon: Icons.folder_open_outlined,
                              text: 'Aún no guardaste ningún vocabulario.\n'
                                  'Crea uno y pulsa "Guardar" para verlo aquí.',
                            );
                          }
                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _SavedTile(
                              item: items[i],
                              isOpen: items[i].id == widget.controller.id,
                              busy: _busy,
                              onOpen: () => _open(items[i], SavedAction.opened),
                              onEvaluate: () => _open(items[i], SavedAction.evaluate),
                              onDelete: () => _delete(items[i]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({
    required this.item,
    required this.isOpen,
    required this.busy,
    required this.onOpen,
    required this.onEvaluate,
    required this.onDelete,
  });

  final VocabularySummary item;
  final bool isOpen;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEvaluate;
  final VoidCallback onDelete;

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final untitled = item.title.trim().isEmpty;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontStyle: untitled ? FontStyle.italic : FontStyle.normal,
                    color: untitled ? AppColors.slate500 : AppColors.slate900,
                  ),
                ),
              ),
              if (isOpen) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Abierto',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand700),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${item.wordCount} ${item.wordCount == 1 ? 'palabra' : 'palabras'} · '
            'Actualizado ${_date(item.updatedAt)}',
            style: const TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onOpen,
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('Abrir'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
                ),
              ),
              FilledButton.icon(
                onPressed: busy ? null : onEvaluate,
                icon: const Icon(Icons.emoji_events_outlined, size: 18),
                label: const Text('Evaluar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
                ),
              ),
              IconButton(
                onPressed: busy ? null : onDelete,
                tooltip: 'Eliminar vocabulario',
                icon: const Icon(Icons.delete_outline),
                color: AppColors.slate600,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.slate400),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate600)),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
