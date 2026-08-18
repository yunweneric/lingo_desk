/// Utilities to convert between nested localization JSON and the
/// dot-notation format used by the translation editor.
///
/// ```json
/// {"nav": {"home": "Home"}}  <->  {"nav.home": "Home"}
/// ```
class JsonFlattener {
  const JsonFlattener._();

  /// Flattens a nested JSON map into dot-notation keys.
  ///
  /// Non-string leaf values are stringified. Lists are indexed
  /// (`items.0`, `items.1`, ...).
  static Map<String, String> flatten(
    Map<String, dynamic> json, {
    String prefix = '',
  }) {
    final result = <String, String>{};

    json.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        result.addAll(flatten(value, prefix: fullKey));
      } else if (value is Map) {
        result.addAll(
          flatten(Map<String, dynamic>.from(value), prefix: fullKey),
        );
      } else if (value is List) {
        for (var index = 0; index < value.length; index++) {
          final item = value[index];
          if (item is Map) {
            result.addAll(
              flatten(
                Map<String, dynamic>.from(item),
                prefix: '$fullKey.$index',
              ),
            );
          } else {
            result['$fullKey.$index'] = item?.toString() ?? '';
          }
        }
      } else {
        result[fullKey] = value?.toString() ?? '';
      }
    });

    return result;
  }

  /// Reconstructs a nested JSON map from dot-notation keys.
  ///
  /// Keys are inserted in sorted order so exported files are stable.
  static Map<String, dynamic> unflatten(Map<String, String> flat) {
    final result = <String, dynamic>{};
    final sortedKeys = flat.keys.toList()..sort();

    for (final flatKey in sortedKeys) {
      final segments = flatKey.split('.');
      var node = result;

      for (var index = 0; index < segments.length - 1; index++) {
        final segment = segments[index];
        final child = node[segment];
        if (child is Map<String, dynamic>) {
          node = child;
        } else {
          // Overwrites conflicting scalar values with a nested object.
          final created = <String, dynamic>{};
          node[segment] = created;
          node = created;
        }
      }

      final leaf = segments.last;
      if (node[leaf] is! Map) {
        node[leaf] = flat[flatKey];
      }
    }

    return result;
  }

  /// Whether [key] is a valid dot-notation translation key.
  ///
  /// Segments must be non-empty and contain letters, digits, `_` or `-`.
  static bool isValidKey(String key) {
    if (key.isEmpty) {
      return false;
    }
    final segmentPattern = RegExp(r'^[A-Za-z0-9_-]+$');
    return key.split('.').every(segmentPattern.hasMatch);
  }
}
