import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../../domain/usecases/export_translations.dart';
import '../bloc/translation_editor_bloc.dart';
import '../bloc/translation_editor_event.dart';
import '../bloc/translation_editor_state.dart';
import '../widgets/add_key_dialog.dart';
import '../widgets/export_languages_dialog.dart';
import '../widgets/language_progress_header.dart';
import '../widgets/translation_table.dart';

/// The translation workspace: flattened key grid, progress bars,
/// missing-only filter, key CRUD, and JSON export.
class TranslationEditorPage extends StatelessWidget {
  const TranslationEditorPage({super.key, required this.appId});

  final String appId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => getIt<TranslationEditorBloc>()..add(LoadEditorEvent(appId)),
      child: _EditorView(appId: appId),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView({required this.appId});

  final String appId;

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TranslationEditorBloc, TranslationEditorState>(
      listenWhen:
          (previous, current) =>
              current is TranslationEditorLoaded &&
              current.notice != null &&
              (previous is! TranslationEditorLoaded ||
                  previous.notice != current.notice),
      listener: (context, state) {
        final notice = (state as TranslationEditorLoaded).notice!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(notice.message),
              backgroundColor: notice.isError ? LingoDeskColors.error : null,
            ),
          );
      },
      builder: (context, state) {
        final Widget view;
        if (state is TranslationEditorLoaded) {
          view = _buildLoaded(context, state);
        } else if (state is TranslationEditorError) {
          view = _buildError(context, state);
        } else {
          view = const _EditorChrome(
            breadcrumb: [Crumb.workspace, Crumb('Editor')],
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AnimatedSwitcher(
          duration: LingoDeskMotion.standard,
          switchInCurve: LingoDeskMotion.curve,
          switchOutCurve: LingoDeskMotion.curve,
          child: KeyedSubtree(
            key: ValueKey<String>(state.runtimeType.toString()),
            child: view,
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, TranslationEditorError state) {
    return _EditorChrome(
      breadcrumb: const [Crumb.workspace, Crumb('Editor')],
      body: WorkspaceErrorState(
        message: state.message,
        onRetry:
            () => context.read<TranslationEditorBloc>().add(
              LoadEditorEvent(widget.appId),
            ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, TranslationEditorLoaded state) {
    return _EditorChrome(
      breadcrumb: [
        Crumb.workspace,
        const Crumb('Apps', route: AppRoutes.apps),
        Crumb(state.app.name),
        const Crumb('Editor'),
      ],
      // Page-level actions live in the header; the body toolbar keeps only
      // the controls that change what the grid *shows*.
      actions: [
        Tooltip(
          message: 'App settings',
          child: OutlinedButton(
            onPressed: () => _openAppSettings(context, state),
            // Icon-only: the header is already crowded, and the gear is
            // the one action that leaves the editor.
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              fixedSize: const Size.square(48),
            ),
            child: const LingoDeskIcon(
              HugeIcons.strokeRoundedSettings01,
              size: 19,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _addKey(context, state),
          icon: const LingoDeskIcon(HugeIcons.strokeRoundedAdd01, size: 17),
          label: const Text('Add key'),
        ),
        OutlinedButton.icon(
          onPressed: () => _uploadFiles(context, state),
          icon: const LingoDeskIcon(
            HugeIcons.strokeRoundedFileUpload,
            size: 17,
          ),
          label: const Text('Upload'),
        ),
        FilledButton.icon(
          onPressed:
              state.entries.isEmpty ? null : () => _exportFiles(context, state),
          icon: const LingoDeskIcon(
            HugeIcons.strokeRoundedDownload04,
            color: Colors.white,
            size: 17,
          ),
          label: const Text('Export ZIP'),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(20),
        // The grid is the point of this page, so the blocks above it
        // arrive first and it settles in last.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(child: _EditorSummary(state: state)),
            const SizedBox(height: 14),
            LanguageProgressHeader(state: state),
            const SizedBox(height: 14),
            FadeSlideIn.staggered(
              index: 2,
              child: _buildToolbar(context, state),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FadeSlideIn.staggered(
                index: 3,
                child: TranslationTableWidget(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, TranslationEditorLoaded state) {
    final bloc = context.read<TranslationEditorBloc>();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: LingoDeskTextField(
            controller: _searchController,
            hintText: 'Search keys and values',
            prefixIcon: HugeIcons.strokeRoundedSearch01,
            clearable: true,
            onChanged: (value) => bloc.add(SearchKeysEvent(value)),
          ),
        ),
        FilterChip(
          label: Text(
            state.showMissingOnly
                ? 'Missing only (${state.filteredEntries.length})'
                : 'Missing only',
          ),
          selected: state.showMissingOnly,
          onSelected: (_) => bloc.add(ToggleMissingOnlyEvent()),
        ),
      ],
    );
  }

  Future<void> _addKey(
    BuildContext context,
    TranslationEditorLoaded state,
  ) async {
    final bloc = context.read<TranslationEditorBloc>();
    final request = await AddKeyDialog.show(
      context,
      existingKeys: state.entries.map((entry) => entry.key).toSet(),
      languages: state.app.allLanguages,
      sourceLanguage: state.app.sourceLanguage,
    );
    if (request != null) {
      bloc.add(AddKeyEvent(key: request.key, values: request.values));
    }
  }

  /// Opens the app's settings, then reloads so a changed name or new
  /// target language shows up in the grid on return.
  Future<void> _openAppSettings(
    BuildContext context,
    TranslationEditorLoaded state,
  ) async {
    final bloc = context.read<TranslationEditorBloc>();
    await context.push(AppRoutes.appSettings(state.app.id), extra: state.app);
    bloc.add(LoadEditorEvent(widget.appId));
  }

  Future<void> _uploadFiles(
    BuildContext context,
    TranslationEditorLoaded state,
  ) async {
    final bloc = context.read<TranslationEditorBloc>();
    await context.push(
      AppRoutes.fileUpload(state.app.id, popOnImport: true),
      extra: state.app,
    );
    bloc.add(LoadEditorEvent(widget.appId));
  }

  Future<void> _exportFiles(
    BuildContext context,
    TranslationEditorLoaded state,
  ) async {
    final bloc = context.read<TranslationEditorBloc>();
    final languages = await ExportLanguagesDialog.show(
      context,
      languages: state.app.allLanguages,
      sourceLanguage: state.app.sourceLanguage,
      archiveName: archiveNameFor(state.app.name),
    );
    if (languages != null && languages.isNotEmpty) {
      bloc.add(ExportTranslationsEvent(languages));
    }
  }
}

/// Shared frame for every editor state: the shell's breadcrumb header
/// above the page body, so loading, error and loaded all sit in the same
/// chrome instead of each inventing its own.
class _EditorChrome extends StatelessWidget {
  const _EditorChrome({
    required this.breadcrumb,
    required this.body,
    this.actions = const [],
  });

  final List<Crumb> breadcrumb;
  final List<Widget> actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: Column(
          children: [
            WorkspacePageHeader(breadcrumb: breadcrumb, actions: actions),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// The totals the old header subtitle used to carry.
class _EditorSummary extends StatelessWidget {
  const _EditorSummary({required this.state});

  final TranslationEditorLoaded state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        WorkspaceMetaTile(
          label: 'Keys',
          value: '${state.entries.length}',
          icon: HugeIcons.strokeRoundedKey01,
        ),
        WorkspaceMetaTile(
          label: 'Missing',
          value: '${state.totalMissing}',
          icon: HugeIcons.strokeRoundedAlertCircle,
        ),
        WorkspaceMetaTile(
          label: 'Languages',
          value: '${state.app.allLanguages.length}',
          icon: HugeIcons.strokeRoundedLanguageSquare,
        ),
      ],
    );
  }
}
