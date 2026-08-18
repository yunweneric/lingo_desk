import 'package:hugeicons/hugeicons.dart';

import '../../../../core/assets/lingo_desk_assets.dart';

/// One proof row under a step's body copy: an icon, a plain-language
/// claim, and the machine string that backs it up (Space Mono, per the
/// design system's "machine strings" rule).
class OnboardingHighlight {
  const OnboardingHighlight({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final List<List<dynamic>> icon;
  final String label;
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

  final String eyebrow;
  final String title;
  final String body;

  /// Stage photography. 3:2, shown framed rather than full-bleed so the
  /// original composition survives every window size.
  final String photoAsset;
  final String photoCaption;
  final String photoCredit;

  final List<OnboardingHighlight> highlights;
}

/// The three-beat story: the grid, the project, the hand-off. Each step
/// is paired with a photograph of the same idea in the physical world —
/// a stack, an index, a departures board.
const onboardingSteps = [
  OnboardingStep(
    eyebrow: 'Translation workspace',
    title: 'Translate every locale from one clean desk',
    body:
        'Every key is a row and every language a column. Missing strings '
        'stay highlighted while you work, so nothing ships half-translated.',
    photoAsset: LingoDeskAssets.onboardingWorkspace,
    photoCaption: 'Every volume, one room',
    photoCredit: 'Gerard GRIFFAY / Unsplash',
    highlights: [
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedTableRowsSplit,
        label: 'Keys and languages in a single grid',
        detail: 'home.hero.title -> es.json',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedSearch01,
        label: 'Filter down to what is still missing',
        detail: '12 missing',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedClock03,
        label: 'Edits save to this machine as you type',
        detail: 'autosave 400ms',
      ),
    ],
  ),
  OnboardingStep(
    eyebrow: 'Project setup',
    title: 'Keep each product organized by language',
    body:
        'One workspace per app: pick the source language once, track only '
        'the target locales that matter, and let coverage speak for itself.',
    photoAsset: LingoDeskAssets.onboardingProjects,
    photoCaption: 'Indexed, labelled, findable',
    photoCredit: 'Daniel Forsman / Unsplash',
    highlights: [
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedFolderAdd,
        label: 'A focused workspace for every app',
        detail: 'source en',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedLanguageSquare,
        label: 'Pick targets from 20 supported locales',
        detail: 'targets fr, es, uk',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedChartBarIncreasing,
        label: 'Coverage per app and per language',
        detail: '84% complete',
      ),
    ],
  ),
  OnboardingStep(
    eyebrow: 'Export ready',
    title: 'Ship nested JSON files back to your app',
    body:
        'LingoDesk rebuilds your original key structure before export, so '
        'the files that land in your repo are the files your app expects.',
    photoAsset: LingoDeskAssets.onboardingExport,
    photoCaption: 'Every destination on the board',
    photoCredit: 'JESHOOTS.COM / Unsplash',
    highlights: [
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedFolderLibrary,
        label: 'Dot keys expand back into nested objects',
        detail: 'nav.home -> {"nav":{"home"}}',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedDownload04,
        label: 'Choose the locales, save where you like',
        detail: 'es.json, uk.json',
      ),
      OnboardingHighlight(
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        label: 'Pretty-printed with a stable key order',
        detail: 'git diff stays clean',
      ),
    ],
  ),
];
