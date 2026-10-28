import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';
import '../logic/grid_builder.dart';
import '../models/word.dart';
import '../services/auth/auth_service.dart';
import '../state/vocab_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/account_menu.dart';
import '../widgets/app_background.dart';
import '../widgets/bingo_grid.dart';
import '../widgets/dialogs.dart';
import '../widgets/export_menu.dart';
import '../widgets/header_bar.dart';
import '../widgets/game/game_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/vocabulary_bar.dart';
import '../widgets/word_form.dart';
import '../widgets/word_list.dart';
import 'saved_vocabularies_screen.dart';

/// Pantalla principal con tres diseños:
///
/// * **Móvil** (< 600 px): una columna con formulario, grilla y listado.
/// * **Tablet** (600–1023 px): una columna ancha, formulario en fila y
///   listado a dos columnas.
/// * **Web / escritorio** (≥ 1024 px): dos paneles; la grilla a la izquierda y
///   el formulario con el listado a la derecha, cada uno con su desplazamiento.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.auth,
    required this.user,
  });

  final VocabController controller;
  final AuthService auth;
  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  /// Identifica la grilla para capturarla al imprimir o exportar a PDF.
  final _gridKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _startEditing(Word word) {
    widget.controller.startEditing(word);
    // En móvil y tablet el formulario está arriba de todo.
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _openSaved(ScreenSize size) async {
    final action = await Navigator.of(context).push<SavedAction>(
      MaterialPageRoute(builder: (_) => SavedVocabulariesScreen(controller: widget.controller)),
    );
    if (!mounted || action == null) return;
    _scrollToTop();
    if (action == SavedAction.evaluate) _openQuiz(size);
  }

  Future<void> _signOut() async {
    final controller = widget.controller;
    if (!await confirmDiscardChanges(context, controller, action: 'cerrar sesión')) return;
    try {
      await widget.auth.signOut();
      // El borrador local no debe quedar en un equipo compartido.
      await controller.discardDraft();
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = ScreenSize.of(constraints.maxWidth);
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: ScreenSize.maxContentWidth),
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) =>
                        size.isExpanded ? _buildExpanded(context, size) : _buildStacked(context, size),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(ScreenSize size) {
    return HeaderBar(
      size: size,
      onStartQuiz: () => _openQuiz(size),
      account: AccountMenu(
        user: widget.user,
        requiresLogin: widget.auth.requiresLogin,
        onSignOut: _signOut,
        compact: size.isCompact,
      ),
    );
  }

  Widget _vocabularyBar(ScreenSize size) {
    return VocabularyBar(controller: widget.controller, onOpenSaved: () => _openSaved(size));
  }

  /// Móvil y tablet: todo en una sola columna con desplazamiento.
  Widget _buildStacked(BuildContext context, ScreenSize size) {
    final controller = widget.controller;
    final pad = size.pagePadding;
    return SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 56),
      child: Column(
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(size),
                const SizedBox(height: 16),
                _vocabularyBar(size),
                const SizedBox(height: 16),
                WordForm(controller: controller, horizontal: size.isMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(child: _gridSection(size)),
          const SizedBox(height: 16),
          SectionCard(
            child: SizedBox(
              width: double.infinity,
              child: WordList(
                words: controller.words.reversed.toList(),
                columns: size.isMedium ? 2 : 1,
                onEdit: _startEditing,
                onDelete: (w) => controller.removeWord(w.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Web / escritorio: grilla a la izquierda, formulario y listado a la derecha.
  Widget _buildExpanded(BuildContext context, ScreenSize size) {
    final controller = widget.controller;
    final pad = size.pagePadding;
    return Padding(
      padding: EdgeInsets.all(pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(size),
                        const SizedBox(height: 16),
                        _vocabularyBar(size),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(child: _gridSection(size)),
                ],
              ),
            ),
          ),
          SizedBox(width: pad),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SectionCard(child: WordForm(controller: controller)),
                const SizedBox(height: 16),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: SectionCard(
                      child: WordList(
                        words: controller.words.reversed.toList(),
                        scrollable: true,
                        onEdit: controller.startEditing,
                        onDelete: (w) => controller.removeWord(w.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridSection(ScreenSize size) {
    final count = widget.controller.words.length;
    final overflow = count > gridSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grilla 5 x 6', style: AppTheme.heading(20)),
                  Text(
                    overflow
                        ? '$count palabra(s) guardada(s) · $gridSize en la grilla'
                        : '$count palabra(s) guardada(s)',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ExportMenu(
              gridKey: _gridKey,
              enabled: count > 0,
              compact: size.isCompact,
            ),
          ],
        ),
        const SizedBox(height: 12),
        BingoGrid(controller: widget.controller, size: size, captureKey: _gridKey),
      ],
    );
  }

  void _openQuiz(ScreenSize size) {
    showQuiz(context, widget.controller.words, size);
  }
}
