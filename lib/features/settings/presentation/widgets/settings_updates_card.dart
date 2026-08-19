import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/github_repo.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/updates/export.dart';
import '../../../../core/utils/external_link.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../../core/localization/export.dart';

/// Whether a newer LingoDesk has been published, and the way to get it.
///
/// The check reads the repository's newest *release*, which is what the
/// release workflow attaches builds to. Nothing installs itself: the build
/// lands in the Downloads folder and the user opens it, which is the only
/// honest option while the builds ship unsigned.
class SettingsUpdatesCard extends StatelessWidget {
  const SettingsUpdatesCard({super.key, required this.controller});

  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final version = controller.installedVersion;

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkspaceCardHeader(
            title: LocaleKeys.navUpdates.tr(),
            subtitle: LocaleKeys.settingsUpdatesSubtitle.tr(),
            icon: HugeIcons.strokeRoundedCloudDownload,
          ),
          const SizedBox(height: 22),
          _StatusBlock(controller: controller),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: controller.isChecking ? null : controller.check,
                icon: const LingoDeskIcon(
                  HugeIcons.strokeRoundedRefresh,
                  color: Colors.white,
                  size: 17,
                ),
                label: Text(LocaleKeys.settingsUpdatesCheck.tr()),
              ),
              TextButton.icon(
                onPressed: () => openExternalUrl(GithubRepo.releases),
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedGithub,
                  color: tokens.muted,
                  size: 17,
                ),
                label: Text(LocaleKeys.landingReleasesOnGithub.tr()),
              ),
            ],
          ),
          if (version.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              LocaleKeys.settingsUpdatesCurrent.tr(
                namedArgs: {'version': version},
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.muted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The part that changes with the check: a line of prose, and — when
/// there is something to install — the download beside it.
class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.controller});

  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.status) {
      UpdateIdle() || UpdateChecking() => _Line(
        icon: HugeIcons.strokeRoundedCloudDownload,
        message: LocaleKeys.settingsUpdatesChecking.tr(),
      ),
      UpdateUpToDate() => _Line(
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        message: LocaleKeys.settingsUpdatesUpToDate.tr(),
        tone: _Tone.good,
      ),
      UpdateAvailable(:final update) => _AvailableBlock(
        update: update,
        controller: controller,
      ),
      UpdateNoBuild(:final update) => _Line(
        icon: HugeIcons.strokeRoundedAlert02,
        message: LocaleKeys.settingsUpdatesNoBuild.tr(
          namedArgs: {'platform': UpdatePlatform.current.label},
        ),
        link: (LocaleKeys.settingsUpdatesNotes.tr(), update.notesUrl),
      ),
      UpdateCheckFailed(:final failure) => _Line(
        icon: HugeIcons.strokeRoundedAlert02,
        message: switch (failure) {
          UpdateFailure.offline => LocaleKeys.settingsUpdatesFailedOffline.tr(),
          UpdateFailure.rateLimited =>
            LocaleKeys.settingsUpdatesFailedRateLimited.tr(),
          UpdateFailure.unexpected =>
            LocaleKeys.settingsUpdatesFailedUnexpected.tr(),
        },
        tone: _Tone.bad,
      ),
    };
  }
}

/// A newer release with a build this platform can run.
class _AvailableBlock extends StatelessWidget {
  const _AvailableBlock({required this.update, required this.controller});

  final AppUpdate update;
  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final asset = update.asset!;
    final savedPath = controller.savedPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LingoDeskIcon(
              HugeIcons.strokeRoundedRocket01,
              color: tokens.accent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.settingsUpdatesAvailable.tr(
                      namedArgs: {'version': update.version},
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    asset.filename,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.isDownloading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: controller.progress,
              minHeight: 6,
              backgroundColor: tokens.active,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            LocaleKeys.settingsUpdatesDownloading.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
          ),
        ] else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: controller.download,
                icon: const LingoDeskIcon(
                  HugeIcons.strokeRoundedDownload04,
                  color: Colors.white,
                  size: 17,
                ),
                label: Text(
                  LocaleKeys.settingsUpdatesDownload.tr(
                    namedArgs: {'size': asset.readableSize},
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => openExternalUrl(asset.downloadUrl),
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedGlobe02,
                  color: tokens.muted,
                  size: 17,
                ),
                label: Text(LocaleKeys.settingsUpdatesBrowser.tr()),
              ),
              TextButton.icon(
                onPressed: () => openExternalUrl(update.notesUrl),
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedNote01,
                  color: tokens.muted,
                  size: 17,
                ),
                label: Text(LocaleKeys.settingsUpdatesNotes.tr()),
              ),
            ],
          ),
        if (savedPath != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const LingoDeskIcon(
                HugeIcons.strokeRoundedCheckmarkCircle02,
                color: LingoDeskColors.complete,
                size: 17,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  LocaleKeys.settingsUpdatesSaved.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.foreground,
                    fontSize: 12.5,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: controller.revealDownload,
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedFolderOpen,
                  color: tokens.muted,
                  size: 17,
                ),
                label: Text(LocaleKeys.settingsUpdatesReveal.tr()),
              ),
            ],
          ),
        ],
        if (controller.downloadFailed) ...[
          const SizedBox(height: 14),
          _Line(
            icon: HugeIcons.strokeRoundedAlert02,
            message: LocaleKeys.settingsUpdatesDownloadFailed.tr(),
            tone: _Tone.bad,
          ),
        ],
        const SizedBox(height: 14),
        Text(
          LocaleKeys.settingsUpdatesUnsigned.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
      ],
    );
  }
}

enum _Tone { neutral, good, bad }

/// One icon and one sentence, optionally followed by a link.
class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.message,
    this.tone = _Tone.neutral,
    this.link,
  });

  final List<List<dynamic>> icon;
  final String message;
  final _Tone tone;

  /// Label and URL of a link shown under the message.
  final (String, String)? link;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final color = switch (tone) {
      _Tone.neutral => tokens.muted,
      _Tone.good => LingoDeskColors.complete,
      _Tone.bad => LingoDeskColors.error,
    };
    final target = link;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LingoDeskIcon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.foreground,
                  fontSize: 13.5,
                ),
              ),
              if (target != null)
                TextButton(
                  onPressed: () => openExternalUrl(target.$2),
                  child: Text(target.$1),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
