import '../../../core/constants/languages.dart';

/// Resolves a translation file to a supported language code.
///
/// Tries the file name first (`fr.json` -> `fr`, `en.intl.json` -> `en`,
/// `pt-BR.json` -> `pt`), then falls back to the folder the file sits in
/// so locale directories work too (`translations/en/common.json` -> `en`).
///
/// Returns `null` when neither resolves to a locale the app supports.
String? resolveLanguage({
  required String fileName,
  required String parentDirName,
}) {
  return _codeFrom(languageStemOf(fileName)) ?? _codeFrom(parentDirName);
}

/// The part of [fileName] before its first dot, lowercased.
///
/// Any leading directories are stripped first, so both `/` and `\` paths
/// are accepted.
String languageStemOf(String fileName) {
  final base = fileName.split('/').last.split(r'\').last;
  final dotIndex = base.indexOf('.');
  final stem = dotIndex == -1 ? base : base.substring(0, dotIndex);
  return stem.toLowerCase();
}

/// Matches [candidate] against the supported locales, retrying without a
/// region or script suffix (`pt_BR` -> `pt`, `zh-hans` -> `zh`).
String? _codeFrom(String candidate) {
  final normalized = candidate.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (SupportedLanguages.supports(normalized)) {
    return normalized;
  }
  final base = normalized.split(RegExp('[-_]')).first;
  return SupportedLanguages.supports(base) ? base : null;
}
