import 'package:flutter/material.dart';

import '../core/theme/lingo_desk_motion.dart';
import '../core/theme/lingo_desk_tokens.dart';
import 'sections/download_section.dart';
import 'sections/features_section.dart';
import 'sections/flutter_section.dart';
import 'sections/footer_section.dart';
import 'sections/hero_section.dart';
import 'sections/landing_nav.dart';
import 'sections/locale_strip.dart';
import 'sections/open_source_section.dart';
import 'sections/problem_section.dart';
import 'sections/steps_section.dart';
import 'sections/tour_section.dart';
import 'state/landing_controller.dart';
import 'widgets/landing_layout.dart';
import 'widgets/reveal.dart';
import '../core/localization/export.dart';

/// The whole site: one scrolling column under a sticky bar.
///
/// There is no router. Every destination is a section on this page, which
/// is also why the GitHub Pages deploy needs no 404 rewrite — there is
/// only ever one URL.
class LandingPage extends StatefulWidget {
  const LandingPage({
    super.key,
    required this.controller,
    this.initialAnchor = '',
  });

  final LandingController controller;

  /// Section named in the URL fragment when the page was opened.
  final String initialAnchor;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scroll = ScrollController();

  final GlobalKey _problem = GlobalKey();
  final GlobalKey _features = GlobalKey();
  final GlobalKey _tour = GlobalKey();
  final GlobalKey _steps = GlobalKey();
  final GlobalKey _flutter = GlobalKey();
  final GlobalKey _download = GlobalKey();

  bool _scrolled = false;

  /// Anchor id of the section currently under the reading line, or null
  /// while the hero still owns the screen.
  String? _activeId;

  /// Anchor names accepted in the URL fragment, so a link can point at a
  /// section: `…/lingo_desk/#download`.
  late final Map<String, GlobalKey> _anchors = {
    'why': _problem,
    'features': _features,
    'screens': _tour,
    'how-it-works': _steps,
    'flutter': _flutter,
    'download': _download,
  };

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFragment());
    // Fonts resolve over the network and can reflow the page after the
    // first frame, which moves every section below the fold; re-apply the
    // anchor once things have settled.
    Future<void>.delayed(const Duration(milliseconds: 600), _openFragment);
  }

  /// Jumps straight to the section named in the URL fragment, if any.
  ///
  /// Runs after the first frame so the sections have been laid out and
  /// their offsets are real.
  void _openFragment() {
    final target = _anchors[widget.initialAnchor.toLowerCase()];
    if (target != null) {
      _jumpTo(target, animate: false);
    }
  }

  void _onScroll() {
    final scrolled = _scroll.offset > 12;
    final active = _sectionInView();
    if (scrolled != _scrolled || active != _activeId) {
      setState(() {
        _scrolled = scrolled;
        _activeId = active;
      });
    }
  }

  /// Scroll spy: the last section whose top has passed the reading line.
  ///
  /// The line sits a third of the way down the viewport rather than at
  /// the very top, so a section counts as "the one you are reading" once
  /// it genuinely dominates the screen — measuring at the top edge makes
  /// the highlight flip a whole section early.
  ///
  /// Positions come from the render tree instead of a table of cached
  /// offsets, because section heights change with width, with the fonts
  /// arriving, and with images loading.
  String? _sectionInView() {
    if (!_scroll.hasClients) {
      return null;
    }
    final line = MediaQuery.sizeOf(context).height * 0.34;

    String? found;
    for (final entry in _anchors.entries) {
      final target = entry.value.currentContext;
      if (target == null) {
        continue;
      }
      final box = target.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        continue;
      }
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= line) {
        // _anchors is in page order, so the last match wins.
        found = entry.key;
      }
    }

    // The final section can be shorter than the space below the line, so
    // it would never win on its own; at the bottom of the page it is
    // unambiguously what you are looking at.
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 4) {
      return _anchors.keys.last;
    }
    return found;
  }

  /// Scrolls [key]'s section under the nav rather than behind it.
  void _jumpTo(GlobalKey key, {bool animate = true}) {
    final target = key.currentContext;
    if (target == null || !_scroll.hasClients) {
      return;
    }
    final box = target.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final offset =
        (_scroll.offset + box.localToGlobal(Offset.zero).dy - kLandingNavHeight)
            .clamp(0.0, _scroll.position.maxScrollExtent);

    if (!animate || !LingoDeskMotion.enabled(context)) {
      _scroll.jumpTo(offset);
      return;
    }
    _scroll.animateTo(
      offset,
      duration: LingoDeskMotion.slow,
      curve: LingoDeskMotion.curve,
    );
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: tokens.background,
      body: LandingScroll(
        controller: _scroll,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  children: [
                    HeroSection(
                      controller: controller,
                      onSeeDownloads: () => _jumpTo(_download),
                    ),
                    const LocaleStrip(),
                    ProblemSection(anchor: _problem),
                    FeaturesSection(anchor: _features),
                    TourSection(anchor: _tour, controller: controller),
                    StepsSection(anchor: _steps),
                    FlutterSection(
                      anchor: _flutter,
                      controller: controller,
                      onSeeDownloads: () => _jumpTo(_download),
                    ),
                    DownloadSection(anchor: _download, controller: controller),
                    OpenSourceSection(controller: controller),
                    const FooterSection(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LandingNav(
                controller: controller,
                scrolled: _scrolled,
                activeId: _activeId,
                onDownload: () => _jumpTo(_download),
                targets: [
                  NavTarget(
                    'why',
                    LocaleKeys.landingNavWhy.tr(),
                    () => _jumpTo(_problem),
                  ),
                  NavTarget(
                    'features',
                    LocaleKeys.landingNavFeatures.tr(),
                    () => _jumpTo(_features),
                  ),
                  NavTarget(
                    'screens',
                    LocaleKeys.landingNavScreens.tr(),
                    () => _jumpTo(_tour),
                  ),
                  NavTarget(
                    'how-it-works',
                    LocaleKeys.landingNavHowItWorks.tr(),
                    () => _jumpTo(_steps),
                  ),
                  NavTarget(
                    'flutter',
                    LocaleKeys.landingNavFlutter.tr(),
                    () => _jumpTo(_flutter),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
