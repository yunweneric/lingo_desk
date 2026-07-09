import '../../../../core/assets/lingo_desk_assets.dart';

class OnboardingStep {
  const OnboardingStep({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.code,
    required this.metricLabel,
    required this.metricValue,
    required this.illustrationAsset,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String code;
  final String metricLabel;
  final String metricValue;
  final String illustrationAsset;
}

const onboardingSteps = [
  OnboardingStep(
    eyebrow: 'Translation workspace',
    title: 'Translate every locale from one clean desk',
    body:
        'Load your locale files, review missing strings, and keep every target language moving without losing context.',
    code: 'home.hero.title  -  es.json  -  12 missing',
    metricLabel: 'Missing keys',
    metricValue: '12',
    illustrationAsset: LingoDeskAssets.onboardingWorkspace,
  ),
  OnboardingStep(
    eyebrow: 'Project setup',
    title: 'Keep each product organized by language',
    body:
        'Create a focused workspace per app, choose the source language, and track only the target locales that matter.',
    code: 'source en  -  targets fr, es, uk',
    metricLabel: 'Target locales',
    metricValue: '3',
    illustrationAsset: LingoDeskAssets.onboardingProjects,
  ),
  OnboardingStep(
    eyebrow: 'Export ready',
    title: 'Ship nested JSON files back to your app',
    body:
        'LingoDesk restores your key structure before export so translated files are ready for your codebase.',
    code: 'Downloaded es.json and uk.json',
    metricLabel: 'Ready files',
    metricValue: '2',
    illustrationAsset: LingoDeskAssets.onboardingExport,
  ),
];
