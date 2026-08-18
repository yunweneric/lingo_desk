import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/ai_settings_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_menu.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../../../core/widgets/lingo_desk_toast.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../../../ai_translation/domain/entities/ai_provider.dart';
import '../../domain/usecases/export_translations.dart';
import '../bloc/translation_editor_bloc.dart';
import '../bloc/translation_editor_event.dart';
import '../bloc/translation_editor_state.dart';
import '../widgets/add_key_dialog.dart';
import '../widgets/ai_translate_dialog.dart';
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
        context.showToast((state as TranslationEditorLoaded).notice!);
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
      // Page-level actions live in the header, as icons: four labelled
      // buttons plus the breadcrumb left the band with nothing to spare.
      // Adding a key is not one of them — it changes what is in the grid,
      // so it sits with the grid's own controls.
      actions: [
        EditorHeaderAction(
          icon: HugeIcons.strokeRoundedSettings01,
          tooltip: 'App settings',
          onPressed: () => _openAppSettings(context, state),
        ),
        EditorHeaderAction(
          icon: HugeIcons.strokeRoundedSparkles,
          tooltip: switch (state) {
            _ when state.aiJob != null => 'AI translation running',
            _ when state.translatableMissing == 0 =>
              'Nothing left to translate',
            _ => 'AI translate',
          },
          onPressed:
              state.aiJob != null || state.translatableMissing == 0
                  ? null
                  : () => _aiTranslate(context, state),
        ),
        EditorHeaderAction(
          icon: HugeIcons.strokeRoundedFileUpload,
          tooltip: 'Upload files',
          onPressed: () => _uploadFiles(context, state),
        ),
        _ExportMenuButton(state: state, onSelected: _export),
      ],
      body: Padding(
        padding: const EdgeInsets.all(20),
        // The grid is the point of this page, so the blocks above it
        // arrive first and it settles in last.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LanguageProgressHeader(state: state),
            const SizedBox(height: 14),
            FadeSlideIn.staggered(
              index: 2,
              child: _buildToolbar(context, state),
            ),
            const SizedBox(height: 14),
            if (state.aiJob != null) ...[
              _AiJobBanner(job: state.aiJob!),
              const SizedBox(height: 14),
            ],
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

    // One bar over the grid: what is in it, what of it is shown, and the
    // way to add to it — pinned right, the only action among readouts.
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._summaryTiles(state),
              SizedBox(
                width: 260,
                height: _barHeight,
                child: LingoDeskTextField(
                  controller: _searchController,
                  hintText: 'Search keys and values',
                  prefixIcon: HugeIcons.strokeRoundedSearch01,
                  clearable: true,
                  onChanged: (value) => bloc.add(SearchKeysEvent(value)),
                ),
              ),
              SizedBox(
                height: _barHeight,
                child: FilterChip(
                  label: Text(
                    state.showMissingOnly
                        ? 'Missing only (${state.filteredEntries.length})'
                        : 'Missing only',
                  ),
                  selected: state.showMissingOnly,
                  onSelected: (_) => bloc.add(ToggleMissingOnlyEvent()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () => _addKey(context, state),
          icon: const LingoDeskIcon(
            HugeIcons.strokeRoundedAdd01,
            color: Colors.white,
            size: 17,
          ),
          label: const Text('Add key'),
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

  /// Opens the language picker, then hands the selection to the bloc.
  ///
  /// The provider is named in the dialog rather than checked here — the bloc
  /// owns the "no key configured" case so every entry point reports it the
  /// same way.
  Future<void> _aiTranslate(
    BuildContext context,
    TranslationEditorLoaded state,
  ) async {
    final bloc = context.read<TranslationEditorBloc>();
    final aiSettings = getIt<AiSettingsController>();
    final languages = await AiTranslateDialog.show(
      context,
      state: state,
      providerLabel: aiSettings.activeKey?.provider.label ?? 'No provider',
      model: aiSettings.activeKey?.model ?? '',
    );
    if (languages != null && languages.isNotEmpty) {
      bloc.add(AiTranslateEvent(languages));
    }
  }

  /// Confirms which languages an export covers, then fires it.
  ///
  /// The three destinations share the dialog and differ only in the copy
  /// and in the file each language is written as, so the user always
  /// sees the real paths before anything is overwritten.
  Future<void> _export(
    BuildContext context,
    TranslationEditorLoaded state,
    _ExportDestination destination,
  ) async {
    final bloc = context.read<TranslationEditorBloc>();
    final app = state.app;

    final languages = await ExportLanguagesDialog.show(
      context,
      languages: app.allLanguages,
      sourceLanguage: app.sourceLanguage,
      title: switch (destination) {
        _ExportDestination.downloads => 'Download ZIP',
        _ExportDestination.project => 'Save to ${app.name}',
        _ExportDestination.folder => 'Export to folder',
      },
      summary: switch (destination) {
        _ExportDestination.downloads =>
          'Bundled into ${archiveNameFor(app.name)} in your Downloads '
              'folder.',
        _ExportDestination.project =>
          'Written into ${app.projectPath}, replacing these files.',
        _ExportDestination.folder =>
          'You pick the folder next; one file per language lands in it.',
      },
      confirmLabel: switch (destination) {
        _ExportDestination.downloads => 'Download',
        _ExportDestination.project => 'Overwrite files',
        _ExportDestination.folder => 'Choose folder',
      },
      // Only a save back to the project follows the imported layout;
      // the other two write flat <lang>.json files.
      fileNameFor:
          destination == _ExportDestination.project ? app.projectFileFor : null,
    );

    if (languages == null || languages.isEmpty) {
      return;
    }
    bloc.add(switch (destination) {
      _ExportDestination.downloads => ExportToDownloadsEvent(languages),
      _ExportDestination.project => ExportToProjectEvent(languages),
      _ExportDestination.folder => ExportToFolderEvent(languages),
    });
  }
}

/// Where an export writes.
enum _ExportDestination { downloads, project, folder }

/// The editor's single export trigger.
///
/// Three destinations behind one button rather than three across the
/// header: the header already carries the app settings, add-key and
/// upload actions, and the choice of destination is a detail of one
/// action rather than three separate ones.
class _ExportMenuButton extends StatelessWidget {
  const _ExportMenuButton({required this.state, required this.onSelected});

  final TranslationEditorLoaded state;
  final void Function(
    BuildContext context,
    TranslationEditorLoaded state,
    _ExportDestination destination,
  )
  onSelected;

  @override
  Widget build(BuildContext context) {
    final app = state.app;
    final enabled = state.entries.isNotEmpty && !state.isExporting;

    return LingoDeskMenuButton<_ExportDestination>(
      tooltip: 'Export',
      menuWidth: 280,
      enabled: enabled,
      onSelected: (destination) => onSelected(context, state, destination),
      items: [
        const LingoDeskMenuItem(
          value: _ExportDestination.downloads,
          label: 'Download ZIP',
          icon: HugeIcons.strokeRoundedDownload04,
          description: 'Zipped into your Downloads folder',
        ),
        LingoDeskMenuItem(
          value: _ExportDestination.project,
          label: 'Save to project',
          icon: HugeIcons.strokeRoundedFolderSync,
          // Naming the folder is the whole reassurance here: this is the
          // one destination that overwrites files the user already has.
          description:
              app.hasProject
                  ? app.projectPath
                  : 'Import a project folder first',
          enabled: app.hasProject,
        ),
        const LingoDeskMenuItem(
          value: _ExportDestination.folder,
          label: 'Export to folder\u2026',
          icon: HugeIcons.strokeRoundedFolderOpen,
          description: 'Choose a destination',
        ),
      ],
      // The menu owns the tap, so the button is here for its looks only.
      child: IgnorePointer(
        child: EditorHeaderAction(
          icon: HugeIcons.strokeRoundedDownload04,
          // The menu trigger above already carries the tooltip.
          tooltip: '',
          primary: true,
          onPressed: enabled ? () {} : null,
          child:
              state.isExporting
                  ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}

/// One header action: a square icon button carrying its name in a
/// tooltip, so a band of them reads as a toolbar rather than a sentence.
///
/// A disabled action keeps its tooltip and says why it is disabled —
/// with no label there is nothing else left to explain it.
class EditorHeaderAction extends StatelessWidget {
  const EditorHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
    this.child,
  });

  final List<List<dynamic>> icon;

  /// Empty when something above already carries the tooltip — a menu
  /// trigger, say. Two nested tooltips both fire on hover.
  final String tooltip;

  final VoidCallback? onPressed;

  /// Draws the action filled, for the page's main way out of the editor.
  final bool primary;

  /// Replaces the icon while something is running, for a spinner.
  final Widget? child;

  /// Square, and the height of the header's other controls.
  static const size = Size.square(44);

  @override
  Widget build(BuildContext context) {
    final glyph =
        child ??
        LingoDeskIcon(
          icon,
          size: 19,
          color: primary && onPressed != null ? Colors.white : null,
        );

    final button =
        primary
            ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                fixedSize: size,
              ),
              child: glyph,
            )
            : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                fixedSize: size,
              ),
              child: glyph,
            );

    return tooltip.isEmpty ? button : Tooltip(message: tooltip, child: button);
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

/// Height every control in the toolbar over the grid is cut to — the
/// height a themed button already has, so the readouts, the field and
/// the chip line up with it rather than each finding its own.
const double _barHeight = 48;

/// The totals the old header subtitle used to carry.
///
/// Spread into the toolbar rather than grouped in a widget of their own,
/// so on a narrow pane a single tile drops to the next line instead of
/// all three moving together.
List<Widget> _summaryTiles(TranslationEditorLoaded state) {
  return [
    WorkspaceMetaTile(
      label: 'Keys',
      value: '${state.entries.length}',
      icon: HugeIcons.strokeRoundedKey01,
      height: _barHeight,
    ),
    WorkspaceMetaTile(
      label: 'Missing',
      value: '${state.totalMissing}',
      icon: HugeIcons.strokeRoundedAlertCircle,
      height: _barHeight,
    ),
    WorkspaceMetaTile(
      label: 'Languages',
      value: '${state.app.allLanguages.length}',
      icon: HugeIcons.strokeRoundedLanguageSquare,
      height: _barHeight,
    ),
  ];
}

/// Live progress for the running AI pass.
///
/// Sits above the grid rather than in a snackbar because a pass over several
/// languages runs for minutes: it has to stay visible, keep counting, and
/// keep a cancel within reach the whole time.
class _AiJobBanner extends StatelessWidget {
  const _AiJobBanner({required this.job});

  final AiJob job;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(
          color: LingoDeskColors.brandTeal.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: LingoDeskColors.brandTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.isCanceling
                      ? 'Finishing the current batch…'
                      : 'Translating ${job.label} · '
                          '${job.settled} of ${job.total}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                WorkspaceProgressBar(
                  value: job.progress,
                  isComplete: false,
                  minHeight: 6,
                  backgroundColor: tokens.active,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed:
                job.isCanceling
                    ? null
                    : () => context.read<TranslationEditorBloc>().add(
                      CancelAiTranslationEvent(),
                    ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
