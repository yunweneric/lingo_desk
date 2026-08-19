import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_dialog.dart';
import '../../../../core/widgets/lingo_desk_dropdown.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../domain/entities/ai_key.dart';
import '../../domain/entities/ai_provider.dart';
import 'ai_provider_logo.dart';
import '../../../../core/localization/export.dart';

/// What the dialog collected.
class AiKeyDraft {
  const AiKeyDraft({
    required this.provider,
    required this.label,
    required this.apiKey,
    required this.model,
  });

  final AiProvider provider;
  final String label;
  final String apiKey;
  final String model;
}

/// Adds or edits one API key.
///
/// Adding starts on a provider picker, because the provider decides the key
/// format, the model list and the console you fetch the key from — asking
/// for it first means the form can then speak in that provider's terms
/// instead of hedging. Editing skips the step: a key cannot change provider,
/// only be replaced.
class AiKeyDialog extends StatefulWidget {
  const AiKeyDialog({super.key, this.existing});

  /// The key being edited, or null when adding.
  final AiKey? existing;

  static Future<AiKeyDraft?> show(BuildContext context, {AiKey? existing}) {
    return showDialog<AiKeyDraft>(
      context: context,
      builder: (_) => AiKeyDialog(existing: existing),
    );
  }

  @override
  State<AiKeyDialog> createState() => _AiKeyDialogState();
}

class _AiKeyDialogState extends State<AiKeyDialog> {
  late AiProvider? _provider = widget.existing?.provider;

  late final TextEditingController _labelController = TextEditingController(
    text: widget.existing?.label ?? '',
  );
  late final TextEditingController _keyController = TextEditingController(
    text: widget.existing?.apiKey ?? '',
  );
  late final TextEditingController _modelController = TextEditingController(
    text: widget.existing?.model ?? '',
  );

  bool _showKey = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _labelController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _chooseProvider(AiProvider provider) {
    setState(() {
      _provider = provider;
      // Prefill the model so the common case is one paste and done.
      if (_modelController.text.trim().isEmpty) {
        _modelController.text = provider.defaultModel;
      }
    });
  }

  void _submit() {
    final provider = _provider;
    if (provider == null) {
      return;
    }
    if (_keyController.text.trim().isEmpty) {
      setState(() => _error = LocaleKeys.aiKeyRequired.tr());
      return;
    }
    Navigator.of(context).pop(
      AiKeyDraft(
        provider: provider,
        label: _labelController.text,
        apiKey: _keyController.text,
        model: _modelController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;

    return LingoDeskDialog(
      title: Text(
        _isEditing
            ? LocaleKeys.aiEditKey.tr()
            : (provider == null
                  ? LocaleKeys.aiAddKey.tr()
                  : LocaleKeys.aiAddProviderKey.tr(
                      namedArgs: {'provider': provider.label},
                    )),
      ),
      preferredWidth: 460,
      // The picker is a plain list of providers; the form brings its own
      // scroll view and must not be wrapped in a second one.
      scrollable: provider == null,
      content: provider == null
          ? _ProviderPicker(onSelected: _chooseProvider)
          : _KeyForm(
              provider: provider,
              isEditing: _isEditing,
              labelController: _labelController,
              keyController: _keyController,
              modelController: _modelController,
              showKey: _showKey,
              error: _error,
              onToggleShowKey: () => setState(() => _showKey = !_showKey),
              onModelPicked: (model) {
                _modelController.text = model;
                setState(() {});
              },
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.commonCancel.tr()),
        ),
        // Back is only meaningful while adding, where a step preceded this.
        if (provider != null && !_isEditing)
          TextButton(
            onPressed: () => setState(() => _provider = null),
            child: Text(LocaleKeys.commonBack.tr()),
          ),
        if (provider != null)
          FilledButton(
            onPressed: _submit,
            child: Text(
              _isEditing
                  ? LocaleKeys.appSettingsSaveChanges.tr()
                  : LocaleKeys.aiSaveKey.tr(),
            ),
          ),
      ],
    );
  }
}

/// Step one: which provider this key belongs to.
class _ProviderPicker extends StatelessWidget {
  const _ProviderPicker({required this.onSelected});

  final ValueChanged<AiProvider> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            LocaleKeys.aiPickProvider.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          ),
        ),
        for (final provider in AiProvider.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProviderOption(
              provider: provider,
              tokens: tokens,
              onTap: () => onSelected(provider),
            ),
          ),
      ],
    );
  }
}

class _ProviderOption extends StatelessWidget {
  const _ProviderOption({
    required this.provider,
    required this.tokens,
    required this.onTap,
  });

  final AiProvider provider;
  final LingoDeskTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.active,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              AiProviderLogo(provider: provider, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: tokens.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.consoleLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              LingoDeskIcon(
                HugeIcons.strokeRoundedArrowRight01,
                size: 17,
                color: tokens.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step two: the key itself.
class _KeyForm extends StatelessWidget {
  const _KeyForm({
    required this.provider,
    required this.isEditing,
    required this.labelController,
    required this.keyController,
    required this.modelController,
    required this.showKey,
    required this.error,
    required this.onToggleShowKey,
    required this.onModelPicked,
  });

  final AiProvider provider;
  final bool isEditing;
  final TextEditingController labelController;
  final TextEditingController keyController;
  final TextEditingController modelController;
  final bool showKey;
  final String? error;
  final VoidCallback onToggleShowKey;
  final ValueChanged<String> onModelPicked;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AiProviderLogo(provider: provider, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocaleKeys.aiCreateKeyAt.tr(
                    namedArgs: {'console': provider.consoleLabel},
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LingoDeskTextField(
            controller: labelController,
            label: LocaleKeys.aiFieldName.tr(),
            description: LocaleKeys.aiFieldNameHelp.tr(),
            hintText: provider.label,
            prefixIcon: HugeIcons.strokeRoundedTag01,
            size: LingoDeskFieldSize.large,
          ),
          const SizedBox(height: 16),
          LingoDeskTextField(
            controller: keyController,
            label: LocaleKeys.aiColApiKey.tr(),
            hintText: provider.keyHint,
            prefixIcon: HugeIcons.strokeRoundedKey01,
            size: LingoDeskFieldSize.large,
            obscureText: !showKey,
            monospace: showKey,
            isRequired: true,
            autofocus: true,
            errorText: error,
            suffix: IconButton(
              tooltip: showKey
                  ? LocaleKeys.aiHideKey.tr()
                  : LocaleKeys.aiShowKey.tr(),
              onPressed: onToggleShowKey,
              icon: LingoDeskIcon(
                showKey
                    ? HugeIcons.strokeRoundedViewOff
                    : HugeIcons.strokeRoundedView,
                size: 17,
                color: tokens.muted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LingoDeskTextField(
            controller: modelController,
            label: LocaleKeys.aiColModel.tr(),
            hintText: provider.defaultModel,
            prefixIcon: HugeIcons.strokeRoundedAiBrain01,
            size: LingoDeskFieldSize.large,
            monospace: true,
          ),
          const SizedBox(height: 12),
          // Free text above, suggestions here: a model released after this
          // build ships can still just be typed in.
          LingoDeskDropdown<String>(
            value: null,
            hintText: LocaleKeys.aiPickModel.tr(),
            items: [
              for (final model in provider.suggestedModels)
                LingoDeskDropdownItem(
                  value: model,
                  label: model,
                  trailingText: model == provider.defaultModel
                      ? LocaleKeys.aiDefaultModel.tr()
                      : null,
                ),
            ],
            onChanged: onModelPicked,
          ),
        ],
      ),
    );
  }
}
