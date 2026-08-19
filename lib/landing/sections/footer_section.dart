import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/lingo_desk_mark.dart';
import '../data/github_release.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_layout.dart';
import '../../core/localization/export.dart';

/// Colophon: who made it, under what licence, and with what.
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final narrow = context.windowSize.isBelow(WindowSizeClass.expanded);

    final links = Wrap(
      spacing: 26,
      runSpacing: 12,
      children: [
        const LandingLink(label: 'GitHub', url: GithubRepo.url),
        LandingLink(
          label: LocaleKeys.landingFooterReleases.tr(),
          url: GithubRepo.releases,
        ),
        LandingLink(
          label: LocaleKeys.landingFooterIssues.tr(),
          url: GithubRepo.issues,
        ),
        LandingLink(
          label: LocaleKeys.landingFooterLicence.tr(),
          url: GithubRepo.license,
        ),
        LandingLink(
          label: LocaleKeys.landingFooterReadme.tr(),
          url: GithubRepo.readme,
        ),
      ],
    );

    return Container(
      width: double.infinity,
      color: tokens.sidebar,
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: LandingContainer(
        child: Column(
          children: [
            Flex(
              direction: narrow ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: narrow
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.center,
              children: [
                const LingoDeskMark(size: 26, showWordmark: true),
                if (narrow) const SizedBox(height: 22) else const Spacer(),
                links,
              ],
            ),
            const SizedBox(height: 32),
            Divider(color: tokens.border, height: 1),
            const SizedBox(height: 24),
            Flex(
              direction: narrow ? Axis.vertical : Axis.horizontal,
              children: [
                Text(
                  '© 2026 Yunweneric · MIT licensed',
                  style: TextStyle(fontSize: 13, color: tokens.muted),
                ),
                if (narrow) const SizedBox(height: 14) else const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LingoDeskIcon(
                      HugeIcons.strokeRoundedCodeSquare,
                      size: 15,
                      color: tokens.muted,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        LocaleKeys.landingFooterNote.tr(),
                        style: TextStyle(fontSize: 13, color: tokens.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
