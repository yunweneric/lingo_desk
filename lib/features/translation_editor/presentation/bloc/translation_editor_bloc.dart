import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/preferences/ai_settings_controller.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_toast.dart';
import '../../../ai_translation/data/datasources/ai_prompt.dart';
import '../../../ai_translation/domain/entities/ai_translation_item.dart';
import '../../../ai_translation/domain/usecases/translate_batch.dart';
import '../../../app_management/domain/entities/app.dart';
import '../../../app_management/domain/usecases/get_app_by_id.dart';
import '../../domain/entities/translation_entry.dart';
import '../../domain/usecases/add_translation_key.dart';
import '../../domain/usecases/delete_translation_key.dart';
import '../../domain/usecases/export_translations.dart';
import '../../domain/usecases/get_translations.dart';
import '../../domain/usecases/save_translations.dart';
import '../../domain/usecases/update_translation.dart';
import 'translation_editor_event.dart';
import 'translation_editor_state.dart';

class TranslationEditorBloc
    extends Bloc<TranslationEditorEvent, TranslationEditorState> {
  TranslationEditorBloc({
    required this.getAppById,
    required this.getTranslations,
    required this.updateTranslation,
    required this.addTranslationKey,
    required this.deleteTranslationKey,
    required this.exportToDownloads,
    required this.exportToFolder,
    required this.pickExportFolder,
    required this.revealExportLocation,
    required this.saveTranslations,
    required this.translateBatch,
    required this.aiSettings,
  }) : super(TranslationEditorInitial()) {
    on<LoadEditorEvent>(_onLoadEditor);
    on<UpdateCellEvent>(_onUpdateCell);
    on<AddKeyEvent>(_onAddKey);
    on<DeleteKeyEvent>(_onDeleteKey);
    on<ToggleMissingOnlyEvent>(_onToggleMissingOnly);
    on<SearchKeysEvent>(_onSearchKeys);
    on<ExportToDownloadsEvent>(_onExportToDownloads);
    on<ExportToProjectEvent>(_onExportToProject);
    on<ExportToFolderEvent>(_onExportToFolder);
    on<RevealExportLocationEvent>(_onRevealExportLocation);
    on<AiTranslateCellEvent>(_onAiTranslateCell);
    on<AiTranslateEvent>(_onAiTranslate);
    on<CancelAiTranslationEvent>(_onCancelAiTranslation);
  }

  final GetAppById getAppById;
  final GetTranslations getTranslations;
  final UpdateTranslation updateTranslation;
  final AddTranslationKey addTranslationKey;
  final DeleteTranslationKey deleteTranslationKey;
  final ExportTranslationsToDownloads exportToDownloads;
  final ExportTranslationsToFolder exportToFolder;
  final PickExportFolder pickExportFolder;
  final RevealExportLocation revealExportLocation;
  final SaveTranslations saveTranslations;
  final TranslateBatch translateBatch;
  final AiSettingsController aiSettings;

  String? _appId;

  /// Set by [CancelAiTranslationEvent] and read between batches, so a cancel
  /// never discards a request that is already in flight.
  bool _cancelAiRequested = false;

  Future<void> _onLoadEditor(
    LoadEditorEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    _appId = event.appId;
    final previous = state;
    if (previous is! TranslationEditorLoaded) {
      emit(TranslationEditorLoading());
    }

    final appResult = await getAppById(GetAppByIdParams(id: event.appId));
    await appResult.fold(
      (failure) async => emit(TranslationEditorError(failure.message)),
      (app) async {
        final translationsResult = await getTranslations(
          GetTranslationsParams(appId: event.appId),
        );
        translationsResult.fold(
          (failure) => emit(TranslationEditorError(failure.message)),
          (entries) {
            emit(
              TranslationEditorLoaded(
                app: app,
                entries: entries,
                showMissingOnly: previous is TranslationEditorLoaded
                    ? previous.showMissingOnly
                    : false,
                query: previous is TranslationEditorLoaded
                    ? previous.query
                    : '',
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onUpdateCell(
    UpdateCellEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }

    // Optimistic update so typing feels instant.
    final updatedEntries = [
      for (final entry in current.entries)
        if (entry.key == event.key)
          entry.copyWithValue(event.language, event.value)
        else
          entry,
    ];
    emit(current.copyWith(entries: updatedEntries, clearNotice: true));

    final result = await updateTranslation(
      UpdateTranslationParams(
        appId: appId,
        key: event.key,
        language: event.language,
        value: event.value,
      ),
    );
    result.fold((failure) {
      final latest = state;
      if (latest is TranslationEditorLoaded) {
        emit(latest.copyWith(notice: ToastNotice.error(failure.message)));
      }
      add(LoadEditorEvent(appId));
    }, (_) {});
  }

  Future<void> _onAddKey(
    AddKeyEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }

    final result = await addTranslationKey(
      AddTranslationKeyParams(
        appId: appId,
        key: event.key,
        values: event.values,
      ),
    );

    await result.fold(
      (failure) async =>
          emit(current.copyWith(notice: ToastNotice.error(failure.message))),
      (_) async {
        await _reloadEntries(
          emit,
          appId,
          notice: ToastNotice.success('Added key "${event.key.trim()}".'),
        );
      },
    );
  }

  Future<void> _onDeleteKey(
    DeleteKeyEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }

    final result = await deleteTranslationKey(
      DeleteTranslationKeyParams(appId: appId, key: event.key),
    );

    await result.fold(
      (failure) async =>
          emit(current.copyWith(notice: ToastNotice.error(failure.message))),
      (_) async {
        await _reloadEntries(
          emit,
          appId,
          notice: ToastNotice.success('Deleted key "${event.key}".'),
        );
      },
    );
  }

  void _onToggleMissingOnly(
    ToggleMissingOnlyEvent event,
    Emitter<TranslationEditorState> emit,
  ) {
    final current = state;
    if (current is TranslationEditorLoaded) {
      emit(
        current.copyWith(
          showMissingOnly: !current.showMissingOnly,
          clearNotice: true,
        ),
      );
    }
  }

  void _onSearchKeys(
    SearchKeysEvent event,
    Emitter<TranslationEditorState> emit,
  ) {
    final current = state;
    if (current is TranslationEditorLoaded) {
      emit(current.copyWith(query: event.query, clearNotice: true));
    }
  }

  Future<void> _onExportToDownloads(
    ExportToDownloadsEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    await _runExport(emit, (appId, app) async {
      final result = await exportToDownloads(
        ExportToDownloadsParams(
          appId: appId,
          languages: event.languages,
          archiveName: archiveNameFor(app.name),
        ),
      );
      return result.map(
        (outcome) => _exportedNotice(
          outcome.location,
          '${_fileCount(event.languages.length)} zipped to Downloads',
        ),
      );
    });
  }

  Future<void> _onExportToProject(
    ExportToProjectEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    await _runExport(emit, (appId, app) async {
      if (!app.hasProject) {
        return const Left(
          ValidationFailure(
            message:
                'This app was not imported from a project folder, so there '
                'is nowhere to save it back to.',
          ),
        );
      }

      final result = await exportToFolder(
        ExportToFolderParams(
          appId: appId,
          languages: event.languages,
          rootPath: app.projectPath!,
          languageFiles: app.languageFiles,
        ),
      );
      return result.map(
        (outcome) => _exportedNotice(
          outcome.location,
          '${_fileCount(outcome.fileCount)} saved to ${app.name}',
        ),
      );
    });
  }

  Future<void> _onExportToFolder(
    ExportToFolderEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    await _runExport(emit, (appId, app) async {
      final picked = await pickExportFolder(
        // Opening at the imported project saves the walk back to it,
        // and still lets the user go anywhere else.
        PickExportFolderParams(initialDirectory: app.projectPath),
      );

      return picked.fold<Future<Either<Failure, ToastNotice?>>>(
        (failure) async => Left(failure),
        (rootPath) async {
          if (rootPath == null) {
            // Dismissing the picker is a neutral note, not a green tick.
            return const Right(ToastNotice.info('Export canceled.'));
          }
          final result = await exportToFolder(
            ExportToFolderParams(
              appId: appId,
              languages: event.languages,
              rootPath: rootPath,
            ),
          );
          return result.map(
            (outcome) => _exportedNotice(
              outcome.location,
              '${_fileCount(outcome.fileCount)} exported',
            ),
          );
        },
      );
    });
  }

  /// Runs one export, holding [TranslationEditorLoaded.isExporting] for
  /// its duration so the menu cannot fire a second one on top of it.
  ///
  /// The state is re-read after the await because an export can outlive
  /// a cell edit or an AI batch landing in the grid.
  Future<void> _runExport(
    Emitter<TranslationEditorState> emit,
    Future<Either<Failure, ToastNotice?>> Function(String appId, App app) run,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded ||
        appId == null ||
        current.isExporting) {
      return;
    }

    emit(current.copyWith(isExporting: true, clearNotice: true));
    final result = await run(appId, current.app);

    final latest = state;
    if (latest is! TranslationEditorLoaded) {
      return;
    }
    emit(
      latest.copyWith(
        isExporting: false,
        notice: result.fold(
          (failure) => ToastNotice.error(failure.message),
          (notice) => notice,
        ),
      ),
    );
  }

  /// An export's toast: what it wrote, where, and a way straight to it.
  ///
  /// The path is the message rather than the title, so the action below
  /// it reads as being about that path.
  ToastNotice _exportedNotice(String location, String title) {
    return ToastNotice.success(
      location,
      title: title,
      actionLabel: 'Show in folder',
      onAction: () {
        // A toast outlives the editor that raised it when the user
        // navigates straight off the page, so a late tap goes to the use
        // case directly. Only a live bloc can also report a failure back
        // into the UI, which is the case worth routing through an event.
        if (isClosed) {
          revealExportLocation(location);
        } else {
          add(RevealExportLocationEvent(location));
        }
      },
    );
  }

  Future<void> _onRevealExportLocation(
    RevealExportLocationEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final result = await revealExportLocation(event.path);
    final current = state;
    // Only a failure is worth saying anything about; opening the folder
    // speaks for itself.
    if (current is TranslationEditorLoaded) {
      result.leftMap(
        (failure) =>
            emit(current.copyWith(notice: ToastNotice.error(failure.message))),
      );
    }
  }

  String _fileCount(int count) => count == 1 ? '1 file' : '$count files';

  Future<void> _onAiTranslateCell(
    AiTranslateCellEvent event,
    Emitter<TranslationEditorState> emit,
  ) {
    // One cell is just a one-entry pass, so the spinner, the persistence and
    // the error reporting are shared with a full run.
    return _runAiTranslation(
      emit,
      languages: [event.language],
      keys: {event.key},
      label: SupportedLanguages.nameOf(event.language),
    );
  }

  Future<void> _onAiTranslate(
    AiTranslateEvent event,
    Emitter<TranslationEditorState> emit,
  ) {
    final label = event.languages.length == 1
        ? SupportedLanguages.nameOf(event.languages.first)
        : '${event.languages.length} languages';
    return _runAiTranslation(
      emit,
      languages: event.languages,
      keys: event.keys,
      label: label,
    );
  }

  void _onCancelAiTranslation(
    CancelAiTranslationEvent event,
    Emitter<TranslationEditorState> emit,
  ) {
    final current = state;
    if (current is! TranslationEditorLoaded || current.aiJob == null) {
      return;
    }
    _cancelAiRequested = true;
    emit(current.copyWith(aiJob: current.aiJob!.copyWith(isCanceling: true)));
  }

  /// Translates every missing cell in [languages] (optionally narrowed to
  /// [keys]) one batch at a time.
  ///
  /// Each batch is written to storage as it lands rather than at the end, so
  /// a cancel, an error, or a closed window all leave the work done so far
  /// intact.
  Future<void> _runAiTranslation(
    Emitter<TranslationEditorState> emit, {
    required List<String> languages,
    required Set<String>? keys,
    required String label,
  }) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }
    if (current.aiJob != null) {
      emit(
        current.copyWith(
          notice: const ToastNotice.warning(
            'A translation pass is already running.',
          ),
        ),
      );
      return;
    }
    if (!aiSettings.isConfigured) {
      emit(
        current.copyWith(
          notice: const ToastNotice.warning(
            'Add an API key in Settings - AI first.',
            title: 'AI is not configured',
          ),
        ),
      );
      return;
    }

    final sourceLanguage = current.app.sourceLanguage;
    final work = _collectWork(
      entries: current.entries,
      sourceLanguage: sourceLanguage,
      languages: languages,
      keys: keys,
    );
    final total = work.values.fold(0, (sum, items) => sum + items.length);
    if (total == 0) {
      emit(
        current.copyWith(
          notice: const ToastNotice.info('Nothing left to translate here.'),
        ),
      );
      return;
    }

    _cancelAiRequested = false;
    final credentials = aiSettings.credentials;
    var job = AiJob(total: total, label: label);
    emit(current.copyWith(aiJob: job, clearNotice: true));

    for (final language in work.keys) {
      final items = work[language]!;
      for (var start = 0; start < items.length; start += AiPrompt.batchSize) {
        if (_cancelAiRequested || emit.isDone) {
          break;
        }
        final batch = items.sublist(
          start,
          math.min(start + AiPrompt.batchSize, items.length),
        );

        job = job.copyWith(
          pendingCells: {
            for (final item in batch) AiJob.cellId(item.key, language),
          },
        );
        _emitJob(emit, job);

        final result = await translateBatch(
          TranslateBatchParams(
            credentials: credentials,
            sourceLanguage: sourceLanguage,
            targetLanguage: language,
            items: batch,
          ),
        );

        job = await result.fold(
          (failure) async {
            // The run keeps going: one bad batch should not throw away the
            // languages still queued behind it.
            return job.copyWith(
              pendingCells: const {},
              failed: job.failed + batch.length,
              lastError: failure.message,
            );
          },
          (values) async {
            await _applyAiValues(emit, appId, language, values);
            // Keys the model skipped stay missing and count as failed, so
            // the tally always adds up to the total.
            final missed = batch.length - values.length;
            return job.copyWith(
              pendingCells: const {},
              completed: job.completed + values.length,
              failed: job.failed + missed,
            );
          },
        );
        _emitJob(emit, job);
      }
      if (_cancelAiRequested || emit.isDone) {
        break;
      }
    }

    if (emit.isDone) {
      return;
    }

    final latest = state;
    if (latest is TranslationEditorLoaded) {
      emit(
        latest.copyWith(
          clearAiJob: true,
          notice: ToastNotice(
            _summary(job, canceled: _cancelAiRequested),
            status: _summaryStatus(job, canceled: _cancelAiRequested),
          ),
        ),
      );
    }
    _cancelAiRequested = false;
  }

  /// Missing cells per language, in the app's target order.
  ///
  /// A key with no source text is skipped: there is nothing to translate
  /// from, and asking the model to invent one would quietly fabricate copy.
  Map<String, List<AiTranslationItem>> _collectWork({
    required List<TranslationEntry> entries,
    required String sourceLanguage,
    required List<String> languages,
    required Set<String>? keys,
  }) {
    final work = <String, List<AiTranslationItem>>{};
    for (final language in languages) {
      if (language == sourceLanguage) {
        continue;
      }
      final items = <AiTranslationItem>[];
      for (final entry in entries) {
        if (keys != null && !keys.contains(entry.key)) {
          continue;
        }
        if (!entry.isMissingFor(language)) {
          continue;
        }
        final source = entry.valueFor(sourceLanguage);
        if (source.trim().isEmpty) {
          continue;
        }
        items.add(AiTranslationItem(key: entry.key, sourceText: source));
      }
      if (items.isNotEmpty) {
        work[language] = items;
      }
    }
    return work;
  }

  /// Writes one batch's values into the grid and into storage.
  ///
  /// Persisting through [SaveTranslations] reuses the same union-merge the
  /// file import uses, so an AI batch and an uploaded file land identically.
  Future<void> _applyAiValues(
    Emitter<TranslationEditorState> emit,
    String appId,
    String language,
    Map<String, String> values,
  ) async {
    if (values.isEmpty) {
      return;
    }

    final result = await saveTranslations(
      SaveTranslationsParams(appId: appId, filesByLanguage: {language: values}),
    );

    if (emit.isDone) {
      return;
    }
    final latest = state;
    if (latest is! TranslationEditorLoaded) {
      return;
    }

    result.fold(
      (failure) =>
          emit(latest.copyWith(notice: ToastNotice.error(failure.message))),
      // The repository returns the merged entries, so the grid is refreshed
      // from storage rather than patched twice.
      (entries) => emit(latest.copyWith(entries: entries)),
    );
  }

  /// Re-emits the running job on whatever the latest state is, so progress
  /// survives an entries refresh landing between batches.
  void _emitJob(Emitter<TranslationEditorState> emit, AiJob job) {
    if (emit.isDone) {
      return;
    }
    final latest = state;
    if (latest is TranslationEditorLoaded) {
      emit(latest.copyWith(aiJob: job));
    }
  }

  /// How the closing summary reads: a clean pass is a success, a pass that
  /// lost cells or stopped early is a warning, and a pass that landed
  /// nothing at all is a failure — unless the user canceled it, in which
  /// case nothing went wrong.
  LingoDeskStatus _summaryStatus(AiJob job, {required bool canceled}) {
    if (job.completed == 0) {
      return canceled ? LingoDeskStatus.info : LingoDeskStatus.error;
    }
    if (job.failed > 0 || canceled) {
      return LingoDeskStatus.warning;
    }
    return LingoDeskStatus.success;
  }

  String _summary(AiJob job, {required bool canceled}) {
    final buffer = StringBuffer();
    if (job.completed == 0) {
      buffer.write(
        canceled
            ? 'Canceled before anything landed.'
            : 'Nothing was translated.',
      );
    } else {
      final strings = job.completed == 1 ? 'string' : 'strings';
      buffer.write('Translated ${job.completed} $strings');
      buffer.write(canceled ? ' before canceling.' : '.');
    }
    if (job.failed > 0) {
      buffer.write(' ${job.failed} could not be translated');
      final error = job.lastError;
      buffer.write(error == null ? '.' : ' ($error)');
    }
    return buffer.toString();
  }

  Future<void> _reloadEntries(
    Emitter<TranslationEditorState> emit,
    String appId, {
    ToastNotice? notice,
  }) async {
    final result = await getTranslations(GetTranslationsParams(appId: appId));
    result.fold((failure) => emit(TranslationEditorError(failure.message)), (
      entries,
    ) {
      final latest = state;
      if (latest is TranslationEditorLoaded) {
        emit(latest.copyWith(entries: entries, notice: notice));
      }
    });
  }
}
