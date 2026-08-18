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
}
