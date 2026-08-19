import 'package:flutter/material.dart';
import '../../core/localization/export.dart';

/// Which screen the preview window is showing.
enum PreviewScreen {
  dashboard(LocaleKeys.navDashboard, LocaleKeys.navDashboard),
  editor(LocaleKeys.editorTitle, LocaleKeys.landingPreviewEditorWindow),
  projects(LocaleKeys.landingPreviewProjects, LocaleKeys.navApps),
  aiProviders(LocaleKeys.navAiProviders, LocaleKeys.navAiProviders),
  appearance(LocaleKeys.navAppearance, LocaleKeys.navAppearance);

  const PreviewScreen(this.label, this.windowTitle);

  /// Translation key for the name in the tour's tab strip and the
  /// preview's own sidebar.
  final String label;

  /// Translation key for the drawn window chrome.
  final String windowTitle;
}

/// One row of the translation table.
class PreviewEntry {
  PreviewEntry({
    required this.key,
    required this.source,
    required Map<String, String> values,
  }) : values = Map.of(values);

  final String key;
  final String source;

  /// Locale code to translation. An empty string is a missing string —
  /// the thing the whole product exists to surface.
  final Map<String, String> values;
}

/// One saved AI key.
class PreviewProvider {
  const PreviewProvider({
    required this.id,
    required this.name,
    required this.model,
    required this.added,
  });

  final String id;
  final String name;
  final String model;
  final String added;
}

/// One app in the workspace.
class PreviewApp {
  const PreviewApp({
    required this.name,
    required this.initials,
    required this.sourceFile,
    required this.keyCount,
    required this.locales,
    required this.progress,
    required this.updated,
  });

  final String name;
  final String initials;
  final String sourceFile;
  final int keyCount;
  final List<String> locales;
  final double progress;
  final String updated;

  int get filesComplete => (locales.length * progress).round();
}

/// The invented workspace behind the preview, and the mutable bits of it.
///
/// A [ChangeNotifier] rather than plain constants because the preview is
/// meant to be *used*: typing a translation, filtering to what is missing
/// and switching the active AI key all have to actually do something, and
/// the resulting numbers have to agree with each other. Coverage on the
/// dashboard is computed from the same cells the editor writes to, so
/// filling one in moves the bar.
///
/// Edits live only here — nothing is persisted, and the workspace is
/// rebuilt on reload.
class PreviewWorkspace extends ChangeNotifier {
  PreviewWorkspace() {
    for (final entry in entries) {
      for (final locale in locales) {
        _controllers['${entry.key}|$locale'] = TextEditingController(
          text: entry.values[locale] ?? '',
        );
      }
    }
  }

  /// Target locales of the app open in the editor.
  static const List<String> locales = ['fr', 'es', 'de'];

  static const String sourceLocale = 'en';

  final List<PreviewEntry> entries = [
    PreviewEntry(
      key: 'checkout.title',
      source: 'Checkout',
      values: {'fr': 'Paiement', 'es': 'Pago', 'de': 'Kasse'},
    ),
    PreviewEntry(
      key: 'checkout.pay_now',
      source: 'Pay now',
      values: {'fr': 'Payer maintenant', 'es': 'Pagar ahora', 'de': ''},
    ),
    PreviewEntry(
      key: 'checkout.promo_code',
      source: 'Promo code',
      values: {
        'fr': 'Code promo',
        'es': 'Código promocional',
        'de': 'Rabattcode',
      },
    ),
    PreviewEntry(
      key: 'cart.empty',
      source: 'Your cart is empty',
      values: {
        'fr': 'Votre panier est vide',
        'es': 'Tu carrito está vacío',
        'de': 'Ihr Warenkorb ist leer',
      },
    ),
    PreviewEntry(
      key: 'cart.remove_item',
      source: 'Remove item',
      values: {'fr': "Retirer l'article", 'es': '', 'de': 'Artikel entfernen'},
    ),
    PreviewEntry(
      key: 'account.sign_in',
      source: 'Sign in',
      values: {'fr': 'Se connecter', 'es': 'Iniciar sesión', 'de': 'Anmelden'},
    ),
    PreviewEntry(
      key: 'account.sign_out',
      source: 'Sign out',
      values: {'fr': 'Se déconnecter', 'es': 'Cerrar sesión', 'de': 'Abmelden'},
    ),
    PreviewEntry(
      key: 'account.reset_password',
      source: 'Reset password',
      values: {
        'fr': 'Réinitialiser le mot de passe',
        'es': 'Restablecer contraseña',
        'de': '',
      },
    ),
  ];

  static const List<PreviewApp> apps = [
    PreviewApp(
      name: 'Storefront',
      initials: 'SF',
      sourceFile: 'en.json',
      keyCount: 10,
      locales: ['fr', 'es', 'de'],
      progress: 0.9,
      updated: '4 min ago',
    ),
    PreviewApp(
      name: 'Flutter Widget Hub',
      initials: 'WH',
      sourceFile: 'en.json',
      keyCount: 145,
      locales: ['fr', 'es', 'it'],
      progress: 1,
      updated: '2 hours ago',
    ),
    PreviewApp(
      name: 'Ops Console',
      initials: 'OC',
      sourceFile: 'en.arb',
      keyCount: 86,
      locales: ['fr', 'de', 'ja', 'pt'],
      progress: 0.78,
      updated: 'Yesterday',
    ),
    PreviewApp(
      name: 'Docs Site',
      initials: 'DS',
      sourceFile: 'en.json',
      keyCount: 132,
      locales: ['es', 'de'],
      progress: 0.96,
      updated: '3 days ago',
    ),
    PreviewApp(
      name: 'Checkout Flow',
      initials: 'CF',
      sourceFile: 'en.json',
      keyCount: 55,
      locales: ['fr', 'es', 'de', 'ja'],
      progress: 0.64,
      updated: 'Last week',
    ),
  ];

  static const List<PreviewProvider> providers = [
    PreviewProvider(
      id: 'anthropic',
      name: 'Anthropic',
      model: 'claude-opus-5',
      added: '3 days ago',
    ),
    PreviewProvider(
      id: 'openai',
      name: 'OpenAI',
      model: 'gpt-5.1',
      added: '3 days ago',
    ),
    PreviewProvider(
      id: 'gemini',
      name: 'Gemini',
      model: 'gemini-3.5-flash-lite',
      added: '1 week ago',
    ),
  ];

  final Map<String, TextEditingController> _controllers = {};

  String _activeProviderId = 'anthropic';
  String _query = '';
  bool _missingOnly = false;

  /// Keys that were incomplete when missing-only was switched on.
  ///
  /// The filter runs against this snapshot rather than live state: without
  /// it, typing the last word of a translation would delete the row you
  /// are typing into — taking the caret with it.
  Set<String> _missingWhenFiltered = const {};

  String? _revealedKeyId;

  String get activeProviderId => _activeProviderId;
  String get query => _query;
  bool get missingOnly => _missingOnly;
  String? get revealedKeyId => _revealedKeyId;

  PreviewProvider get activeProvider =>
      providers.firstWhere((provider) => provider.id == _activeProviderId);

  /// The controller behind one editable cell. Owned here so an edit
  /// survives a trip to another screen and back.
  TextEditingController controllerFor(String key, String locale) =>
      _controllers['$key|$locale']!;

  // -- Editor -------------------------------------------------------------

  void setValue(PreviewEntry entry, String locale, String value) {
    if (entry.values[locale] == value) {
      return;
    }
    entry.values[locale] = value;
    notifyListeners();
  }

  void setQuery(String query) {
    if (query == _query) {
      return;
    }
    _query = query;
    notifyListeners();
  }

  void toggleMissingOnly() {
    _missingOnly = !_missingOnly;
    _missingWhenFiltered = _missingOnly
        ? entries
              .where((entry) => missingFor(entry) > 0)
              .map((entry) => entry.key)
              .toSet()
        : const {};
    notifyListeners();
  }

  /// Fills every empty cell, the way the editor's "AI translate" action
  /// does — the one button on the page that visibly finishes the job.
  void translateEverything() {
    for (final entry in entries) {
      for (final locale in locales) {
        if ((entry.values[locale] ?? '').isEmpty) {
          final value = _machineTranslation(entry, locale);
          entry.values[locale] = value;
          controllerFor(entry.key, locale).text = value;
        }
      }
    }
    notifyListeners();
  }

  /// Canned "translations" for the three cells that ship empty. Invented,
  /// and only ever needed for those three.
  String _machineTranslation(PreviewEntry entry, String locale) {
    const filled = {
      'checkout.pay_now|de': 'Jetzt bezahlen',
      'cart.remove_item|es': 'Eliminar artículo',
      'account.reset_password|de': 'Passwort zurücksetzen',
    };
    return filled['${entry.key}|$locale'] ?? entry.source;
  }

  /// Rows left after the search box and the missing-only toggle.
  List<PreviewEntry> get visibleEntries {
    final needle = _query.trim().toLowerCase();
    return entries.where((entry) {
      if (_missingOnly && !_missingWhenFiltered.contains(entry.key)) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      if (entry.key.toLowerCase().contains(needle) ||
          entry.source.toLowerCase().contains(needle)) {
        return true;
      }
      return entry.values.values.any(
        (value) => value.toLowerCase().contains(needle),
      );
    }).toList();
  }

  int missingFor(PreviewEntry entry) =>
      locales.where((locale) => (entry.values[locale] ?? '').isEmpty).length;

  int get totalCells => entries.length * locales.length;

  int get totalMissing =>
      entries.fold(0, (sum, entry) => sum + missingFor(entry));

  int get totalTranslated => totalCells - totalMissing;

  double get coverage => totalCells == 0 ? 1 : totalTranslated / totalCells;

  int missingIn(String locale) =>
      entries.where((entry) => (entry.values[locale] ?? '').isEmpty).length;

  double progressIn(String locale) => entries.isEmpty
      ? 1
      : (entries.length - missingIn(locale)) / entries.length;

  // -- AI providers -------------------------------------------------------

  void setActiveProvider(String id) {
    if (id == _activeProviderId) {
      return;
    }
    _activeProviderId = id;
    notifyListeners();
  }

  void toggleReveal(String id) {
    _revealedKeyId = _revealedKeyId == id ? null : id;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
