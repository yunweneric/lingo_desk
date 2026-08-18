import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../data/github_release.dart';
import '../state/landing_controller.dart';
import '../widgets/code_panel.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_pill.dart';
import '../widgets/reveal.dart';

/// Where a visitor actually gets the app.
///
/// Everything here is resolved from the newest GitHub *release*: Actions
/// artifacts need an authenticated token, so a public page cannot offer
/// them. When there is no release to resolve — which is the case until a
/// `v*` tag is pushed — the section falls through to the source build
/// rather than showing an empty table.
class DownloadSection extends StatelessWidget {
  const DownloadSection({super.key, required this.controller, this.anchor});

  final LandingController controller;
  final GlobalKey? anchor;

  @override
  Widget build(BuildContext context) {
    final state = controller.release;

    return LandingSection(
      anchor: anchor,
      tinted: true,
      child: Column(
        children: [
          const SectionHeading(
            eyebrow: 'Download',
            title: 'Get LingoDesk.',
            body:
                'Free and open source under the MIT licence. No account, no '
                'trial, no telemetry.',
          ),
          const SizedBox(height: 48),
          Reveal(
            child: switch (state) {
              ReleaseLoading() => const _LoadingCard(),
              ReleaseReady(:final release) => _ReleaseCard(release: release),
              ReleasePending() => _FallbackCard(
                title: 'No packaged build published yet',
                body:
                    'The macOS, Windows and Android installers are built by '
                    'GitHub Actions and attached to a release the moment a '
                    'version tag is pushed. Until then, running from source '
                    'takes about two minutes.',
                controller: controller,
              ),
              ReleaseUnavailable(:final reason) => _FallbackCard(
                title: 'Could not reach GitHub',
                body:
                    '$reason You can still browse the releases page directly, '
                    'or build from source.',
                controller: controller,
                showRetry: true,
              ),
            },
          ),
          const SizedBox(height: 20),
          const Reveal(child: _SourceCard()),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return LandingCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Container(
              height: 62,
              decoration: BoxDecoration(
                color: tokens.active,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Asking GitHub for the newest release…',
            style: TextStyle(fontSize: 13.5, color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

/// The resolved release: version, date, and one row per build.
class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.release});

  final GithubRelease release;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final published = release.publishedLabel;
    final narrow = context.windowSize.isBelow(WindowSizeClass.medium);

    return LandingCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Version ${release.version}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: tokens.foreground,
                ),
              ),
              const LandingPill(
                label: 'Latest',
                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                emphasis: true,
              ),
              if (published != null)
                Text(
                  'Published $published',
                  style: TextStyle(fontSize: 13.5, color: tokens.muted),
                ),
            ],
          ),
          const SizedBox(height: 22),
          for (final asset in release.assets) ...[
            _AssetRow(asset: asset, narrow: narrow),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedInformationCircle,
                size: 15,
                color: tokens.muted,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'The desktop builds are unsigned: on macOS right-click the '
                  'app and choose Open the first time, on Windows choose '
                  'More info then Run anyway.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: tokens.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LandingLink(
            label: 'All releases and changelogs on GitHub  →',
            url: release.htmlUrl,
          ),
        ],
      ),
    );
  }
}

class _AssetRow extends StatefulWidget {
  const _AssetRow({required this.asset, required this.narrow});

  final ReleaseAsset asset;
  final bool narrow;

  @override
  State<_AssetRow> createState() => _AssetRowState();
}

class _AssetRowState extends State<_AssetRow> {
  bool _hovered = false;

  List<List<dynamic>> get _icon => switch (widget.asset.target) {
    DownloadTarget.macos => HugeIcons.strokeRoundedApple,
    DownloadTarget.windowsInstaller ||
    DownloadTarget.windowsPortable => HugeIcons.strokeRoundedComputer,
    DownloadTarget.android => HugeIcons.strokeRoundedAndroid,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final asset = widget.asset;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => openLink(asset.downloadUrl),
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: _hovered ? tokens.active : tokens.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? tokens.brandFillBorder : tokens.border,
            ),
          ),
          child: Row(
            children: [
              LingoDeskIcon(_icon, size: 20, color: tokens.foreground),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${asset.target.label} · ${asset.target.detail}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.narrow
                          ? asset.readableSize
                          : '${asset.filename} · ${asset.readableSize}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kMonoFamily,
                        fontSize: 11.5,
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              LingoDeskIcon(
                HugeIcons.strokeRoundedDownload04,
                size: 19,
                color: _hovered ? tokens.accent : tokens.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when there is nothing to download yet, or GitHub could not be
/// reached. Never a dead end: both paths still lead somewhere useful.
class _FallbackCard extends StatelessWidget {
  const _FallbackCard({
    required this.title,
    required this.body,
    required this.controller,
    this.showRetry = false,
  });

  final String title;
  final String body;
  final LandingController controller;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return LandingCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedRocket01,
                size: 20,
                color: tokens.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: tokens.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(fontSize: 15, height: 1.62, color: tokens.muted),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              const LandingButton(
                label: 'Releases on GitHub',
                icon: HugeIcons.strokeRoundedGithub,
                url: GithubRepo.releases,
              ),
              const LandingButton(
                label: 'Latest build runs',
                icon: HugeIcons.strokeRoundedComputerActivity,
                kind: LandingButtonKind.secondary,
                url: GithubRepo.actions,
              ),
              if (showRetry)
                LandingButton(
                  label: 'Try again',
                  icon: HugeIcons.strokeRoundedFilterReset,
                  kind: LandingButtonKind.ghost,
                  onPressed: () => controller.load(refresh: true),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two commands, always true regardless of what GitHub has published.
class _SourceCard extends StatelessWidget {
  const _SourceCard();

  static const _commands =
      'git clone ${GithubRepo.url}.git\n'
      'cd lingo_desk && flutter run -d macos';

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return LandingCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedTerminal,
                size: 19,
                color: tokens.foreground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Or run it from source on any of the six platforms',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.foreground,
                  ),
                ),
              ),
              const _CopyButton(text: _commands),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                _commands,
                style: TextStyle(
                  fontFamily: kMonoFamily,
                  fontSize: 12.5,
                  height: 1.75,
                  color: tokens.foreground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Swap the device for windows, linux, chrome, or a connected '
            'phone. The project pins its Flutter version in .fvmrc.',
            style: TextStyle(fontSize: 13, height: 1.55, color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LandingButton(
      label: _copied ? 'Copied' : 'Copy',
      icon: _copied
          ? HugeIcons.strokeRoundedTick02
          : HugeIcons.strokeRoundedCopy01,
      kind: LandingButtonKind.ghost,
      onPressed: _copy,
    );
  }
}
