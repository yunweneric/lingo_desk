import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/widgets.dart';

/// Translation helpers used everywhere in the app.
///
/// These delegate to `easy_localization` but are declared here so no feature
/// file imports the package: `import '../../core/localization/export.dart';`
/// is the only import a call site needs.
extension TranslateExtension on String {
  /// Looks this key up in the active locale.
  ///
  /// ```dart
  /// Text(LocaleKeys.appsTitle.tr())
  /// Text(LocaleKeys.appsCount.tr(namedArgs: {'count': '4'}))
  /// ```
  String tr({
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
    String? gender,
  }) => easy.tr(
    this,
    context: context,
    args: args,
    namedArgs: namedArgs,
    gender: gender,
  );

  /// Plural form for [value], picking `zero`/`one`/`other` from the JSON.
  ///
  /// ```dart
  /// LocaleKeys.editorKeyCount.plural(count)
  /// ```
  String plural(
    num value, {
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
    String? name,
  }) => easy.plural(
    this,
    value,
    context: context,
    args: args,
    namedArgs: namedArgs,
    name: name,
  );

  /// Whether the key exists in the active (or fallback) locale. Useful for
  /// optional copy such as provider-specific hints.
  bool get hasTranslation => easy.trExists(this);
}

/// `context.tr(...)` for call sites that already hold a [BuildContext] and
/// want the lookup to rebuild with it.
extension TranslateContextExtension on BuildContext {
  String tr(
    String key, {
    List<String>? args,
    Map<String, String>? namedArgs,
    String? gender,
  }) => easy.tr(
    key,
    context: this,
    args: args,
    namedArgs: namedArgs,
    gender: gender,
  );

  String trPlural(
    String key,
    num value, {
    List<String>? args,
    Map<String, String>? namedArgs,
  }) => easy.plural(
    key,
    value,
    context: this,
    args: args,
    namedArgs: namedArgs,
  );
}
