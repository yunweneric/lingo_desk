import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../data/github_release.dart';
import '../state/landing_controller.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_layout.dart';
import '../widgets/reveal.dart';

/// The closing ask: it is free, it is MIT, and the repository is open.
class OpenSourceSection extends StatelessWidget {
  const OpenSourceSection({super.key, required this.controller, this.anchor});

  final LandingController controller;
  final GlobalKey? anchor;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final narrow = context.windowSize.isBelow(WindowSizeClass.expanded);
    final stars = controller.stars;

    return LandingSection(
      anchor: anchor,
      child: Reveal(
        child: LandingCard(
          padding: EdgeInsets.all(narrow ? 28 : 48),
          color: tokens.brandFill,
          borderColor: tokens.brandFillBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                HugeIcons.strokeRoundedSourceCodeCircle,
                size: 30,
                color: tokens.onBrandFill,
              ),
              const SizedBox(height: 20),
              Text(
                'Free forever, and the source is right there.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: narrow ? 24 : 32,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: tokens.foreground,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'MIT licensed. Fork it, ship it inside your team, or open '
                  'an issue about the workflow that annoys you most — the '
                  'roadmap is driven by the people using it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.62,
                    color: tokens.onBrandFill,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  LandingButton(
                    label: stars == null
                        ? 'Star on GitHub'
                        : 'Star on GitHub · $stars',
                    icon: HugeIcons.strokeRoundedStar,
                    large: true,
                    url: GithubRepo.url,
                  ),
                  LandingButton(
                    label: 'Open an issue',
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    kind: LandingButtonKind.secondary,
                    large: true,
                    url: GithubRepo.issues,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
