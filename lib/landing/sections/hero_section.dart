import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../data/github_release.dart';
import '../state/landing_controller.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_pill.dart';
import '../widgets/landing_shot.dart';
import '../widgets/reveal.dart';

/// The opening screen: what it is, who it's for, and one button that
/// resolves the right build for the browser asking.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.controller,
    required this.onSeeDownloads,
  });

  final LandingController controller;
  final VoidCallback onSeeDownloads;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final size = context.windowSize;
    final narrow = size.isBelow(WindowSizeClass.expanded);

    return Container(
      width: double.infinity,
      color: tokens.background,
      child: Stack(
        children: [
          // A single soft brand bloom behind the headline. The app's
          // chassis is deliberately flat, so this is the one place the
          // page allows itself a gradient.
          Positioned(
            top: -260,
            left: 0,
            right: 0,
            height: 760,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    tokens.brand.withValues(alpha: tokens.isDark ? 0.30 : 0.16),
                    tokens.background.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: kLandingNavHeight + (narrow ? 48 : 76),
              bottom: narrow ? 64 : 96,
            ),
            child: LandingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Reveal(
                    child: Column(
                      children: [
                        const LandingPill(
                          label: 'Open source · MIT · No account, no backend',
                          icon: HugeIcons.strokeRoundedSourceCodeCircle,
                          emphasis: true,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Translate every locale\nfrom one clean desk.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.resolve<double>(
                              compact: 36,
                              medium: 44,
                              expanded: 58,
                              large: 66,
                            ),
                            height: 1.03,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.6,
                            color: tokens.foreground,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 660),
                          child: Text(
                            'LingoDesk turns a folder of en.json, fr.json and es.json '
                            'into one workspace: every key a row, every language a '
                            'column, every missing string impossible to miss.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: narrow ? 16.5 : 18.5,
                              height: 1.62,
                              color: tokens.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Reveal(
                    child: Column(
                      children: [
                        _HeroActions(
                          controller: controller,
                          onSeeDownloads: onSeeDownloads,
                        ),
                        const SizedBox(height: 16),
                        _ReleaseCaption(controller: controller),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                  const Reveal(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        LandingPill(
                          label: 'macOS',
                          icon: HugeIcons.strokeRoundedApple,
                        ),
                        LandingPill(
                          label: 'Windows',
                          icon: HugeIcons.strokeRoundedComputer,
                        ),
                        LandingPill(
                          label: 'Linux',
                          icon: HugeIcons.strokeRoundedTerminal,
                        ),
                        LandingPill(
                          label: 'Android',
                          icon: HugeIcons.strokeRoundedAndroid,
                        ),
                        LandingPill(
                          label: 'iOS',
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                        ),
                        LandingPill(
                          label: 'Web',
                          icon: HugeIcons.strokeRoundedBrowser,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: narrow ? 48 : 72),
                  const Reveal(
                    child: LandingShot(
                      name: 'dashboard.png',
                      semanticLabel:
                          'The LingoDesk dashboard showing translation '
                          'coverage across apps and locales.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The primary call to action, which changes shape with what GitHub says.
class _HeroActions extends StatelessWidget {
  const _HeroActions({required this.controller, required this.onSeeDownloads});

  final LandingController controller;
  final VoidCallback onSeeDownloads;

  @override
  Widget build(BuildContext context) {
    final state = controller.release;
    final asset = controller.suggestedAsset;
    final target = LandingController.visitorTarget;

    final (
      String label,
      String? url,
      VoidCallback? onPressed,
    ) = switch (state) {
      ReleaseLoading() => ('Checking for builds…', null, null),
      ReleaseReady() when asset != null => (
        target?.cta ?? 'Download the latest build',
        asset.downloadUrl,
        null,
      ),
      // A release exists but not for this visitor's platform — send them
      // to the table rather than handing over the wrong binary.
      ReleaseReady() => ('See all downloads', null, onSeeDownloads),
      ReleasePending() => ('Get started', null, onSeeDownloads),
      ReleaseUnavailable() => ('Get started', null, onSeeDownloads),
    };

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        LandingButton(
          label: label,
          icon: HugeIcons.strokeRoundedDownload04,
          large: true,
          busy: state is ReleaseLoading,
          url: url,
          onPressed: onPressed,
        ),
        const LandingButton(
          label: 'View on GitHub',
          icon: HugeIcons.strokeRoundedGithub,
          kind: LandingButtonKind.secondary,
          large: true,
          url: GithubRepo.url,
        ),
      ],
    );
  }
}

/// The one line under the buttons that says what the button will actually
/// give you.
class _ReleaseCaption extends StatelessWidget {
  const _ReleaseCaption({required this.controller});

  final LandingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final state = controller.release;
    final asset = controller.suggestedAsset;

    final text = switch (state) {
      ReleaseLoading() => 'Asking GitHub for the newest release…',
      ReleaseReady(:final release) when asset != null =>
        'v${release.version} · ${asset.readableSize} · '
            '${asset.target.detail} · free forever',
      ReleaseReady(:final release) =>
        'v${release.version} is out — pick a build below.',
      ReleasePending() =>
        'No packaged build published yet — run it from source in two commands.',
      ReleaseUnavailable(:final reason) => '$reason Browse the releases page.',
    };

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13.5, color: tokens.muted),
    );
  }
}
