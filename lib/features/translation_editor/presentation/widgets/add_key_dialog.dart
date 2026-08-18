import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/utils/json_flattener.dart';

/// The values collected by [AddKeyDialog].
class AddKeyRequest {
  const AddKeyRequest({required this.key, required this.sourceValue});

  final String key;
  final String sourceValue;
}

/// Dialog to add a translation key with an optional source value.
///
/// Validates dot-notation format and uniqueness before submitting.
class AddKeyDialog extends StatefulWidget {
  const AddKeyDialog({
    super.key,
    required this.existingKeys,
    required this.sourceLanguage,
  });

  final Set<String> existingKeys;
  final String sourceLanguage;

  /// Shows the dialog and returns the request, or null when canceled.
  static Future<AddKeyRequest?> show(
    BuildContext context, {
    required Set<String> existingKeys,
    required String sourceLanguage,
  }) {
    return showDialog<AddKeyRequest>(
      context: context,
      builder:
          (_) => AddKeyDialog(
            existingKeys: existingKeys,
            sourceLanguage: sourceLanguage,
          ),
    );
  }

  @override
  State<AddKeyDialog> createState() => _AddKeyDialogState();
}

class _AddKeyDialogState extends State<AddKeyDialog> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final key = _keyController.text.trim();
    if (!JsonFlattener.isValidKey(key)) {
      setState(() {
        _error =
            'Use dot notation with letters, digits, "_" or "-" (e.g. nav.home).';
      });
      return;
    }
    if (widget.existingKeys.contains(key)) {
      setState(() => _error = 'The key "$key" already exists.');
      return;
    }
    Navigator.of(
      context,
    ).pop(AddKeyRequest(key: key, sourceValue: _valueController.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add key'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _keyController,
              autofocus: true,
              style: LingoDeskTheme.codeStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Key',
                hintText: 'nav.home',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value (${widget.sourceLanguage})',
                hintText: 'Source text - optional',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add key')),
      ],
    );
  }
}
