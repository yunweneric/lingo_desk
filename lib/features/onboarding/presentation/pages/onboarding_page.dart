import 'package:flutter/material.dart';

import '../widgets/onboarding_content_pane.dart';
import '../widgets/onboarding_step.dart';
import '../widgets/onboarding_visual_pane.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          final isTablet = constraints.maxWidth >= 640;

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 11,
                  child: OnboardingVisualPane(
                    step: onboardingSteps[_currentIndex],
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: SafeArea(
                    child: OnboardingContentPane(
                      pages: onboardingSteps,
                      controller: _controller,
                      currentIndex: _currentIndex,
                      isWide: true,
                      onPageChanged: _handlePageChanged,
                      onBack: _handleBack,
                      onNext: _handleNext,
                      onSkip: _handleSkip,
                    ),
                  ),
                ),
              ],
            );
          }

          return SafeArea(
            child: OnboardingContentPane(
              pages: onboardingSteps,
              controller: _controller,
              currentIndex: _currentIndex,
              isWide: false,
              isTablet: isTablet,
              onPageChanged: _handlePageChanged,
              onBack: _handleBack,
              onNext: _handleNext,
              onSkip: _handleSkip,
            ),
          );
        },
      ),
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _currentIndex = index);
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
