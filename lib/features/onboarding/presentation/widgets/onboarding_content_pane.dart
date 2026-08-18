import 'package:flutter/material.dart';

import 'onboarding_footer.dart';
import 'onboarding_header.dart';
import 'onboarding_slide.dart';
import 'onboarding_step.dart';

/// The reading half of the screen: header rail, the swipeable copy, and
/// the navigation footer. Shared by both layouts so the two never drift.
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
    required this.onSelect,
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
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isWide ? 64.0 : (isTablet ? 44.0 : 24.0);
    final verticalPadding = isWide ? 40.0 : 20.0;
    final isNarrow = !isWide && !isTablet;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingHeader(
            currentIndex: currentIndex,
            length: pages.length,
            onSkip: onSkip,
            showMark: !isWide,
          ),
          SizedBox(height: isWide ? 24 : 20),
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
          SizedBox(height: isWide ? 24 : 12),
          OnboardingFooter(
            currentIndex: currentIndex,
            length: pages.length,
            onBack: onBack,
            onNext: onNext,
            onSelect: onSelect,
            compact: isNarrow,
          ),
        ],
      ),
    );
  }
}
