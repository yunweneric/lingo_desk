import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/preferences/ai_settings_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../ai_translation/domain/entities/ai_provider.dart';
import '../../../ai_translation/presentation/widgets/ai_provider_logo.dart';

/// Where AI translation stands, and the way through to change it.
///
/// The keys themselves are edited on the AI providers screen — one place
/// owns them, so there is never a second copy of the same field to wonder
/// about.
class SettingsAiCard extends StatelessWidget {
  const SettingsAiCard({super.key, required this.settings});

  final AiSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final active = settings.activeKey;
    final configured = settings.isConfigured;
    final total = settings.keys.length;

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceCardHeader(
            title: 'AI translation',
            subtitle:
                'The provider the editor calls to fill missing translations.',
            icon: HugeIcons.strokeRoundedSparkles,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.active,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.border),
                ),
                child:
                    active == null
                        ? LingoDeskIcon(
                          HugeIcons.strokeRoundedKey01,
                          size: 20,
                          color: tokens.muted,
                        )
                        : AiProviderLogo(provider: active.provider, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active?.label ?? 'No API key yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      configured && active != null
                          ? '${active.provider.label} · ${active.model} · '
                              '$total saved key${total == 1 ? '' : 's'}'
                          : 'Add one to translate from the editor',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            configured
                                ? LingoDeskColors.complete
                                : tokens.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.aiProviders),
              icon: const LingoDeskIcon(
                HugeIcons.strokeRoundedKey01,
                color: Colors.white,
                size: 17,
              ),
              label: Text(configured ? 'Manage providers' : 'Add an API key'),
            ),
          ),
        ],
      ),
    );
  }
}
