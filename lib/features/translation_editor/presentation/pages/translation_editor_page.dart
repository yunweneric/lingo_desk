import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/ai_settings_controller.dart';
import '../../../../core/responsive/breakpoints.dart';
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
import '../../../../core/localization/export.dart';

/// The translation workspace: flattened key grid, progress bars,
/// missing-only filter, key CRUD, and JSON export.
class TranslationEditorPage extends StatelessWidget {
  const TranslationEditorPage({super.key, required this.appId});

  final String appId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<TranslationEditorBloc>()..add(LoadEditorEvent(appId)),
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
      listenWhen: (previous, current) =>
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
          view = _EditorChrome(
            breadcrumb: [Crumb.workspace, Crumb(LocaleKeys.editorTitle.tr())],
            body: const Center(child: CircularProgressIndicator()),
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
      breadcrumb: [Crumb.workspace, Crumb(LocaleKeys.editorTitle.tr())],
      body: WorkspaceErrorState(
        message: state.message,
        onRetry: () => context.read<TranslationEditorBloc>().add(
          LoadEditorEvent(widget.appId),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, TranslationEditorLoaded state) {
    return _EditorChrome(
      breadcrumb: [
        Crumb.workspace,
        Crumb(LocaleKeys.navApps.tr(), route: AppRoutes.apps),
        Crumb(state.app.name),
        Crumb(LocaleKeys.editorTitle.tr()),
      ],
      // Page-level actions live in the header, each naming itself: three
      // fit the band once importing moved out to the apps list, where it
      // sits beside the app it fills. Adding a key is not one of them —
      // it changes what is in the grid, so it sits with the grid's own
      // controls.
      actions: _headerActions(context, state, compact: false),
      // Three named buttons will not share a phone's width; the same three
      // glyphs will, on one line, each keeping its name in a tooltip.
      compactActions: [
        Row(
          children: [
            for (final action in _headerActions(
              context,
              state,
              compact: true,
            )) ...[action, const SizedBox(width: 8)],
            const Spacer(),
          ],
        ),
      ],
      body: ResponsiveBuilder(
        builder: (context, size, _) {
          return Padding(
            padding: EdgeInsets.all(size.isCompact ? 12 : 20),
            // The grid is the point of this page, so the blocks above it
            // arrive first and it settles in last.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LanguageProgressHeader(state: state),
                const SizedBox(height: 14),
                FadeSlideIn.staggered(
                  index: 2,
                  child: _buildToolbar(context, state, size),
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
          );
        },
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    TranslationEditorLoaded state,
    WindowSizeClass size,
  ) {
    final bloc = context.read<TranslationEditorBloc>();
    final isCompact = size.isCompact;

    final search = SizedBox(
      height: _barHeight,
      child: LingoDeskTextField(
        controller: _searchController,
        hintText: LocaleKeys.editorSearchHint.tr(),
        prefixIcon: HugeIcons.strokeRoundedSearch01,
        clearable: true,
        onChanged: (value) => bloc.add(SearchKeysEvent(value)),
      ),
    );

    final missingOnly = SizedBox(
      height: _barHeight,
      child: FilterChip(
        label: Text(
          state.showMissingOnly
              ? LocaleKeys.editorMissingOnlyCount.tr(
                  namedArgs: {'count': '${state.filteredEntries.length}'},
                )
              : LocaleKeys.editorMissingOnly.tr(),
        ),
        selected: state.showMissingOnly,
        onSelected: (_) => bloc.add(ToggleMissingOnlyEvent()),
      ),
    );

    final addKey = FilledButton.icon(
      onPressed: () => _addKey(context, state),
      icon: const LingoDeskIcon(
        HugeIcons.strokeRoundedAdd01,
        color: Colors.white,
        size: 17,
      ),
      label: Text(LocaleKeys.editorAddKey.tr()),
    );

    if (isCompact) {
      // A 260px field, three readouts and a button will not share a phone's
      // width, and a Wrap cannot shrink the field to make them. Search gets
      // the full width it needs to be typed into; the rest lines up under it.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: missingOnly),
              const SizedBox(width: 10),
              addKey,
            ],
          ),
        ],
      );
    }

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
              SizedBox(width: 260, child: search),
              missingOnly,
            ],
          ),
        ),
        const SizedBox(width: 10),
        addKey,
      ],
    );
  }

  List<Widget> _headerActions(
    BuildContext context,
    TranslationEditorLoaded state, {
    required bool compact,
  }) {
    return [
      EditorHeaderAction(
        icon: HugeIcons.strokeRoundedSettings01,
        label: LocaleKeys.navSettings.tr(),
        compact: compact,
        onPressed: () => _openAppSettings(context, state),
      ),
      EditorHeaderAction(
        icon: HugeIcons.strokeRoundedSparkles,
        label: LocaleKeys.editorAiTranslate.tr(),
        compact: compact,
        // The label says what it does; the tooltip is left to say why
        // it cannot right now.
        tooltip: switch (state) {
          _ when state.aiJob != null => LocaleKeys.editorAiRunning.tr(),
          _ when state.translatableMissing == 0 =>
            LocaleKeys.editorAiNothingLeft.tr(),
          _ => '',
        },
        onPressed: state.aiJob != null || state.translatableMissing == 0
            ? null
            : () => _aiTranslate(context, state),
      ),
      _ExportMenuButton(state: state, compact: compact, onSelected: _export),
    ];
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
      providerLabel:
          aiSettings.activeKey?.provider.label ??
          LocaleKeys.editorNoProvider.tr(),
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
        _ExportDestination.downloads => LocaleKeys.editorExportZip.tr(),
        _ExportDestination.project => LocaleKeys.editorExportSaveTo.tr(
          namedArgs: {'name': app.name},
        ),
        _ExportDestination.folder => LocaleKeys.editorExportToFolder.tr(),
      },
      summary: switch (destination) {
        _ExportDestination.downloads =>
          LocaleKeys.editorExportZipSummary.tr(
            namedArgs: {'file': archiveNameFor(app.name)},
          ),
        _ExportDestination.project => LocaleKeys.editorExportProjectSummary.tr(
          namedArgs: {'path': app.projectPath ?? ''},
        ),
        _ExportDestination.folder =>
          LocaleKeys.editorExportFolderSummary.tr(),
      },
      confirmLabel: switch (destination) {
        _ExportDestination.downloads => LocaleKeys.editorExportDownload.tr(),
        _ExportDestination.project => LocaleKeys.editorExportOverwrite.tr(),
        _ExportDestination.folder => LocaleKeys.uploadChooseFolder.tr(),
      },
      // Only a save back to the project follows the imported layout;
      // the other two write flat <lang>.json files.
      fileNameFor: destination == _ExportDestination.project
          ? app.projectFileFor
          : null,
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
  const _ExportMenuButton({
    required this.state,
    required this.onSelected,
    this.compact = false,
  });

  final TranslationEditorLoaded state;
  final bool compact;
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
      tooltip: LocaleKeys.editorExport.tr(),
      menuWidth: 280,
      enabled: enabled,
      onSelected: (destination) => onSelected(context, state, destination),
      items: [
        LingoDeskMenuItem(
          value: _ExportDestination.downloads,
          label: LocaleKeys.editorExportZip.tr(),
          icon: HugeIcons.strokeRoundedDownload04,
          description: LocaleKeys.editorExportZipHint.tr(),
        ),
        LingoDeskMenuItem(
          value: _ExportDestination.project,
          label: LocaleKeys.editorExportSaveToProject.tr(),
          icon: HugeIcons.strokeRoundedFolderSync,
          // Naming the folder is the whole reassurance here: this is the
          // one destination that overwrites files the user already has.
          description: app.hasProject
              ? app.projectPath
              : LocaleKeys.editorExportNoProject.tr(),
          enabled: app.hasProject,
        ),
        LingoDeskMenuItem(
          value: _ExportDestination.folder,
          label: LocaleKeys.editorExportToFolderEllipsis.tr(),
          icon: HugeIcons.strokeRoundedFolderOpen,
          description: LocaleKeys.editorExportChooseDestination.tr(),
        ),
      ],
      // The menu owns the tap, so the button is here for its looks only.
      child: IgnorePointer(
        child: EditorHeaderAction(
          icon: HugeIcons.strokeRoundedDownload04,
          label: LocaleKeys.editorExport.tr(),
          // The menu trigger above already carries the tooltip.
          tooltip: '',
          primary: true,
          compact: compact,
          onPressed: enabled ? () {} : null,
          child: state.isExporting
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

/// One header action: an icon beside its name, so the band reads at a
/// glance instead of asking the pointer to name each glyph.
///
/// The tooltip is reserved for what the label cannot say — why an action
/// is disabled — and is empty the rest of the time.
class EditorHeaderAction extends StatelessWidget {
  const EditorHeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip = '',
    this.primary = false,
    this.compact = false,
    this.child,
  });

  final List<List<dynamic>> icon;

  final String label;

  /// Empty when the label already says it, or when something above
  /// carries the tooltip — two nested tooltips both fire on hover.
  final String tooltip;

  final VoidCallback? onPressed;

  /// Draws the action filled, for the page's main way out of the editor.
  final bool primary;

  /// Drops the label and keeps the glyph, so three actions still share
  /// one line on a phone. The name moves into the tooltip rather than
  /// being lost.
  final bool compact;

  /// Replaces the icon while something is running, for a spinner.
  final Widget? child;

  /// The height of the header's other controls.
  static const height = 44.0;

  @override
  Widget build(BuildContext context) {
    final glyph =
        child ??
        LingoDeskIcon(
          icon,
          size: 19,
          color: primary && onPressed != null ? Colors.white : null,
        );
    final text = Text(label);

    // Only the metrics are overridden; the rest of each button's look
    // still comes from the theme.
    final style = ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
      ),
      minimumSize: WidgetStatePropertyAll(Size(compact ? height : 0, height)),
      fixedSize: const WidgetStatePropertyAll(Size.fromHeight(height)),
    );

    final Widget button;
    if (compact) {
      button = primary
          ? FilledButton(onPressed: onPressed, style: style, child: glyph)
          : OutlinedButton(onPressed: onPressed, style: style, child: glyph);
    } else {
      button = primary
          ? FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: glyph,
              label: text,
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: glyph,
              label: text,
            );
    }

    // Compact drops the label, so the name has to live in the tooltip;
    // wide already says it on the button itself.
    final message = tooltip.isNotEmpty ? tooltip : (compact ? label : '');

    return message.isEmpty ? button : Tooltip(message: message, child: button);
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
    this.compactActions,
  });

  final List<Crumb> breadcrumb;
  final List<Widget> actions;
  final List<Widget>? compactActions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: Column(
          children: [
            WorkspacePageHeader(
              breadcrumb: breadcrumb,
              actions: actions,
              compactActions: compactActions,
            ),
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
      label: LocaleKeys.dashboardStatKeys.tr(),
      value: '${state.entries.length}',
      icon: HugeIcons.strokeRoundedKey01,
      height: _barHeight,
    ),
    WorkspaceMetaTile(
      label: LocaleKeys.dashboardMetricMissing.tr(),
      value: '${state.totalMissing}',
      icon: HugeIcons.strokeRoundedAlertCircle,
      height: _barHeight,
    ),
    WorkspaceMetaTile(
      label: LocaleKeys.appsTableColLanguages.tr(),
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
        border: Border.all(color: tokens.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.isCanceling
                      ? LocaleKeys.editorAiFinishing.tr()
                      : LocaleKeys.editorAiProgress.tr(
                          namedArgs: {
                            'label': job.label,
                            'done': '${job.settled}',
                            'total': '${job.total}',
                          },
                        ),
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
            onPressed: job.isCanceling
                ? null
                : () => context.read<TranslationEditorBloc>().add(
                    CancelAiTranslationEvent(),
                  ),
            child: Text(LocaleKeys.commonCancel.tr()),
          ),
        ],
      ),
    );
  }
}
