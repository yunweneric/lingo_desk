import 'package:flutter/material.dart';

import 'onboarding_footer.dart';
import 'onboarding_header.dart';
import 'onboarding_slide.dart';
import 'onboarding_step.dart';

class OnboardingContentPane extends StatelessWidget {
  const OnboardingContentPane({
    super.key,
    required this.pages,
    required this.controller,
    required this.currentIndex,
    required this.isWide,
    required this.onPageChanged,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    this.isTablet = false,
  });

  final List<OnboardingStep> pages;
  final PageController controller;
  final int currentIndex;
  final bool isWide;
  final bool isTablet;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isWide ? 72.0 : (isTablet ? 44.0 : 24.0);
    final topPadding = isWide ? 44.0 : 18.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        isWide ? 44 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingHeader(onSkip: onSkip),
          Expanded(
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return OnboardingSlide(
                  step: pages[index],
                  isWide: isWide,
                  isTablet: isTablet,
                );
              },
            ),
          ),
          OnboardingFooter(
            currentIndex: currentIndex,
            length: pages.length,
            onBack: onBack,
            onNext: onNext,
          ),
        ],
      ),
    );
  }
}
