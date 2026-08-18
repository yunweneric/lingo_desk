class LingoDeskAssets {
  const LingoDeskAssets._();

  // The brand mark itself is drawn natively by LingoDeskMark; the SVGs
  // in assets/brand are the reference artwork from the design system.
  static const appIcon = 'assets/brand/lingodesk_app_icon.png';

  // Onboarding stage photography (Unsplash — see assets/onboarding/CREDITS.md).
  // All three are 3:2 so the stage frame never re-crops the photographer's
  // composition.
  static const onboardingWorkspace =
      'assets/onboarding/onboarding_workspace.jpg';
  static const onboardingProjects = 'assets/onboarding/onboarding_projects.jpg';
  static const onboardingExport = 'assets/onboarding/onboarding_export.jpg';

  // Provider marks shown on the AI providers screen. Trademarks of their
  // owners, included only to identify each service — see
  // assets/brand/providers/CREDITS.md.
  static const anthropicMark = 'assets/brand/providers/anthropic.svg';
  static const openAiMark = 'assets/brand/providers/openai.svg';
  static const geminiMark = 'assets/brand/providers/gemini.svg';
}
