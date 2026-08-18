import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/ai_credential_store.dart';
import '../../../../core/preferences/ai_settings_controller.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_toast.dart';
import '../../../../core/widgets/app_shell_scope.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../../../settings/presentation/pages/settings_pane.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../domain/entities/ai_key.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/usecases/verify_ai_credentials.dart';
import '../widgets/ai_key_dialog.dart';
import '../widgets/ai_keys_table.dart';
import '../widgets/ai_provider_logo.dart';

/// Manages the API keys the translation editor calls with.
///
/// Its own screen rather than a settings tab because it is where you go
/// mid-task when a run reports a bad key, and because a list of keys is
/// something you scan and manage rather than a preference you set once.
class AiProvidersPage extends StatefulWidget {
  const AiProvidersPage({super.key});

  @override
  State<AiProvidersPage> createState() => _AiProvidersPageState();
}

class _AiProvidersPageState extends State<AiProvidersPage> {
  final AiSettingsController _settings = getIt<AiSettingsController>();
  final AiCredentialStore _store = getIt<AiCredentialStore>();

  String? _testingKeyId;

  Future<void> _addKey() async {
    final draft = await AiKeyDialog.show(context);
    if (draft == null) {
      return;
    }
    await _settings.addKey(
      provider: draft.provider,
      label: draft.label,
      apiKey: draft.apiKey,
      model: draft.model,
    );
    if (mounted) {
      context.showSuccessToast(
        '${draft.provider.label} is ready to translate with.',
        title: 'Key added',
      );
    }
  }

  Future<void> _editKey(AiKey entry) async {
    final draft = await AiKeyDialog.show(context, existing: entry);
    if (draft == null) {
      return;
    }
    await _settings.updateKey(
      entry.id,
      label: draft.label,
      apiKey: draft.apiKey,
      model: draft.model,
    );
    if (mounted) {
      context.showSuccessToast(
        'Saved changes to ${entry.label}.',
        title: 'Key updated',
      );
    }
  }

  Future<void> _deleteKey(AiKey entry) async {
    final wasActive = entry.id == _settings.activeKeyId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete API key?'),
        content: Text(
          wasActive
              ? 'This removes "${entry.label}", the key translations '
                    'currently run on. Another saved key takes over, or AI '
                    'translation stops until you add one.'
              : 'This removes "${entry.label}" from this device. '
                    'The key itself stays valid at '
                    '${entry.provider.consoleLabel}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LingoDeskColors.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      return;
    }
    await _settings.deleteKey(entry.id);
    if (!mounted) {
      return;
    }
    final promoted = _settings.activeKey;
    // Deleting the live key silently reroutes spend to another one, so the
    // toast says which — the one thing you would want to know afterwards.
    if (wasActive && promoted != null) {
      context.showWarningToast(
        'Translations now use ${promoted.label}.',
        title: 'Deleted ${entry.label}',
      );
    } else {
      context.showSuccessToast(
        '${entry.label} was removed from this device.',
        title: 'Key deleted',
      );
    }
  }

  Future<void> _testKey(AiKey entry) async {
    setState(() => _testingKeyId = entry.id);
    final outcome = await getIt<VerifyAiCredentials>()(
      VerifyAiCredentialsParams(credentials: entry.credentials),
    );
    if (!mounted) {
      return;
    }
    setState(() => _testingKeyId = null);
    outcome.fold(
      (failure) => context.showErrorToast(
        failure.message,
        title: '${entry.label} failed',
      ),
      (_) => context.showSuccessToast(
        '${entry.provider.label} accepted the key.',
        title: '${entry.label} connected',
      ),
    );
  }

  void _handleAction(AiKeyAction action, AiKey entry) {
    switch (action) {
      case AiKeyAction.use:
        _settings.setActive(entry.id);
        context.showSuccessToast(
          '${entry.provider.label} · ${entry.model}',
          title: 'Translations now use ${entry.label}',
        );
      case AiKeyAction.test:
        _testKey(entry);
      case AiKeyAction.edit:
        _editKey(entry);
      case AiKeyAction.delete:
        _deleteKey(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) {
            return Column(
              children: [
                WorkspacePageHeader(
                  breadcrumb: const [
                    Crumb.workspace,
                    Crumb('Settings'),
                    Crumb('AI providers'),
                  ],
                  actions: [
                    FilledButton.icon(
                      onPressed: _addKey,
                      icon: const LingoDeskIcon(
                        HugeIcons.strokeRoundedAdd01,
                        color: Colors.white,
                        size: 17,
                      ),
                      label: const Text('Add API key'),
                    ),
                  ],
                ),
                // This screen belongs to the settings group, so on a phone
                // it carries the same pane switcher its siblings do.
                if (AppShellScope.maybeOf(context)?.sizeClass.isCompact ??
                    false)
                  const SettingsPaneSwitcher(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontal = constraints.maxWidth < 780
                          ? 16.0
                          : 24.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          20,
                          horizontal,
                          28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeSlideIn(child: _Summary(settings: _settings)),
                            const SizedBox(height: 16),
                            FadeSlideIn.staggered(
                              index: 1,
                              child: AiKeysTable(
                                settings: _settings,
                                testingKeyId: _testingKeyId,
                                onAction: _handleAction,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _StorageNote(store: _store),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Which key a translation run will actually use.
class _Summary extends StatelessWidget {
  const _Summary({required this.settings});

  final AiSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final active = settings.activeKey;
    final configured = settings.isConfigured;

    return WorkspaceSurface(
      child: Row(
        children: [
          if (active != null) ...[
            AiProviderLogo(provider: active.provider, size: 26),
            const SizedBox(width: 16),
          ] else ...[
            LingoDeskIcon(
              HugeIcons.strokeRoundedKey01,
              size: 24,
              color: tokens.muted,
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  configured && active != null
                      ? 'Translating with ${active.label}'
                      : 'No key is ready yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  configured && active != null
                      ? '${active.provider.label} · ${active.model} · used by '
                            'every AI action in the editor.'
                      : 'Add an API key, then the editor can fill missing '
                            'translations for you.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Says plainly where the keys ended up.
///
/// The keychain is not always reachable — on macOS it needs an entitlement
/// that an ad-hoc signed build cannot carry — and a security claim that
/// might be false is worse than no claim at all.
class _StorageNote extends StatelessWidget {
  const _StorageNote({required this.store});

  final AiCredentialStore store;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final isSecure = store.storage == AiKeyStorage.secure;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: LingoDeskIcon(
            isSecure
                ? HugeIcons.strokeRoundedLockKey
                : HugeIcons.strokeRoundedInformationCircle,
            size: 15,
            color: tokens.muted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isSecure
                ? 'Keys are stored in this device’s keychain and are only '
                      'ever sent to the provider they belong to.'
                : 'This build cannot reach the system keychain, so keys are '
                      'stored with your other local settings in plain text. '
                      'They stay on this device and are only ever sent to the '
                      'provider they belong to.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
