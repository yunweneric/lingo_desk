import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../widgets/onboarding_content_pane.dart';
import '../widgets/onboarding_stage.dart';
import '../widgets/onboarding_step.dart';

/// First-launch introduction: a persistent photographic stage on wide
/// windows, a single scrolling column everywhere else.
///
/// Arrow keys, enter and escape all drive it, because this is a desktop
/// app and reaching for the trackpad to read three screens is a tax.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FocusScope(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): _handleNext,
            const SingleActivator(LogicalKeyboardKey.arrowLeft): _handleBack,
            const SingleActivator(LogicalKeyboardKey.enter): _handleNext,
            const SingleActivator(LogicalKeyboardKey.escape): _handleSkip,
          },
          child: ResponsiveBuilder(
            builder: (context, size, constraints) {
              // Two panes need room for a 3:2 stage *and* readable copy;
              // below that the stage becomes a banner inside the slide.
              final isWide = size.atLeast(WindowSizeClass.expanded);
              final isTablet = size.atLeast(WindowSizeClass.medium);

              final contentPane = OnboardingContentPane(
                pages: onboardingSteps,
                controller: _controller,
                currentIndex: _currentIndex,
                isWide: isWide,
                isTablet: isTablet,
                onPageChanged: _handlePageChanged,
                onBack: _handleBack,
                onNext: _handleNext,
                onSkip: _handleSkip,
                onSelect: _handleSelect,
              );

              if (!isWide) {
                return SafeArea(child: contentPane);
              }

              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: OnboardingStage(
                      step: onboardingSteps[_currentIndex],
                    ),
                  ),
                  Expanded(flex: 6, child: SafeArea(child: contentPane)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleSelect(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBack() {
    if (_currentIndex == 0) {
      return;
    }

    _controller.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleNext() {
    if (_currentIndex == onboardingSteps.length - 1) {
      _handleSkip();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleSkip() {
    widget.onComplete();
  }
}
