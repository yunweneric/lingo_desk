import 'package:flutter/material.dart';

import '../constants/languages.dart';
import 'lingo_desk_dropdown.dart';
import 'lingo_desk_field.dart';
import '../localization/export.dart';

/// Language picker used wherever a source locale is chosen.
///
/// Wraps [LingoDeskDropdown] with flag + name + code rows so the settings
/// form and the upload review step present languages identically.
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.languageCodes,
    this.label,
    this.description,
    this.helperText,
    this.errorText,
    this.hintText,
    this.size = LingoDeskFieldSize.large,
    this.enabled = true,
    this.isRequired = false,
  });

  final String? value;
  final ValueChanged<String>? onChanged;

  /// Codes to offer; defaults to every supported language.
  final Iterable<String>? languageCodes;

  final String? label;
  final String? description;
  final String? helperText;
  final String? errorText;

  /// Defaults to the translated "Select a language" placeholder.
  final String? hintText;
  final LingoDeskFieldSize size;
  final bool enabled;
  final bool isRequired;

  /// Flag/name/code options for [codes], usable with a raw
  /// [LingoDeskDropdown] when this widget's shell is not wanted.
  static List<LingoDeskDropdownItem<String>> itemsFor(Iterable<String> codes) {
    return [
      for (final code in codes)
        LingoDeskDropdownItem(
          value: code,
          label: SupportedLanguages.nameOf(code),
          leadingText: SupportedLanguages.flagOf(code),
          trailingText: code,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final codes =
        languageCodes ?? SupportedLanguages.all.map((option) => option.code);

    return LingoDeskDropdown<String>(
      items: itemsFor(codes),
      value: value,
      onChanged: onChanged,
      label: label,
      description: description,
      helperText: helperText,
      errorText: errorText,
      hintText: hintText ?? LocaleKeys.commonSelectLanguage.tr(),
      size: size,
      enabled: enabled,
      isRequired: isRequired,
    );
  }
}
