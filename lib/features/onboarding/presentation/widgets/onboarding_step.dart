import 'package:hugeicons/hugeicons.dart';

import '../../../../core/assets/lingo_desk_assets.dart';
import '../../../../core/localization/export.dart';

/// One proof row under a step's body copy: an icon, a plain-language
/// claim, and the machine string that backs it up (codeStyle, per the
/// design system's "machine strings" rule).
class OnboardingHighlight {
  const OnboardingHighlight({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final List<List<dynamic>> icon;

  /// Translation key for the claim; call `.tr()` where it is drawn.
  final String label;

  /// The machine string backing the claim — a key path, a file name, a
  /// timing. Deliberately not translated: it is sample output, not copy.
  final String detail;
}

class OnboardingStep {
  const OnboardingStep({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.photoAsset,
    required this.photoCaption,
    required this.photoCredit,
    required this.highlights,
  });

  /// Translation keys, resolved where each is drawn.
  final String eyebrow;
  final String title;
  final String body;

  /// Stage photography. 3:2, shown framed rather than full-bleed so the
  /// original composition survives every window size.
  final String photoAsset;

  /// Translation key for the caption. The credit is a person's name and
  /// stays as written.
  final String photoCaption;
  final String photoCredit;

  final List<OnboardingHighlight> highlights;
}

/// The three-beat story: the grid, the project, the hand-off. Each step
/// is paired with a photograph of the same idea in the physical world —
/// a stack, an index, a departures board.
const onboardingSteps = [
  OnboardingStep(
    eyebrow: LocaleKeys.onboardingStep1Eyebrow,
    title: LocaleKeys.onboardingStep1Title,
    body: LocaleKeys.onboardingStep1Body,
    photoAsset: LingoDeskAssets.onboardingWorkspace,
    photoCaption: LocaleKeys.onboardingStep1Caption,
    photoCredit: 'Gerard GRIFFAY / Unsplash',
    highlights: [
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedTableRowsSplit,
        label: LocaleKeys.onboardingStep1Highlight1,
        detail: 'home.hero.title -> es.json',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedSearch01,
        label: LocaleKeys.onboardingStep1Highlight2,
        detail: '12 missing',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedClock03,
        label: LocaleKeys.onboardingStep1Highlight3,
        detail: 'autosave 400ms',
      ),
    ],
  ),
  OnboardingStep(
    eyebrow: LocaleKeys.onboardingStep2Eyebrow,
    title: LocaleKeys.onboardingStep2Title,
    body: LocaleKeys.onboardingStep2Body,
    photoAsset: LingoDeskAssets.onboardingProjects,
    photoCaption: LocaleKeys.onboardingStep2Caption,
    photoCredit: 'Daniel Forsman / Unsplash',
    highlights: [
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedFolderAdd,
        label: LocaleKeys.onboardingStep2Highlight1,
        detail: 'source en',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedLanguageSquare,
        label: LocaleKeys.onboardingStep2Highlight2,
        detail: 'targets fr, es, uk',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedChartBarIncreasing,
        label: LocaleKeys.onboardingStep2Highlight3,
        detail: '84% complete',
      ),
    ],
  ),
  OnboardingStep(
    eyebrow: LocaleKeys.onboardingStep3Eyebrow,
    title: LocaleKeys.onboardingStep3Title,
    body: LocaleKeys.onboardingStep3Body,
    photoAsset: LingoDeskAssets.onboardingExport,
    photoCaption: LocaleKeys.onboardingStep3Caption,
    photoCredit: 'JESHOOTS.COM / Unsplash',
    highlights: [
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedFolderLibrary,
        label: LocaleKeys.onboardingStep3Highlight1,
        detail: 'nav.home -> {"nav":{"home"}}',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedDownload04,
        label: LocaleKeys.onboardingStep3Highlight2,
        detail: 'es.json, uk.json',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        label: LocaleKeys.onboardingStep3Highlight3,
        detail: 'git diff stays clean',
      ),
    ],
  ),
];
