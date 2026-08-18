import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';

/// Local identity shown in the sidebar footer. Nothing leaves the device.
class SettingsProfileCard extends StatefulWidget {
  const SettingsProfileCard({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  State<SettingsProfileCard> createState() => _SettingsProfileCardState();
}

class _SettingsProfileCardState extends State<SettingsProfileCard> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.settings.profileName,
  );
  late final TextEditingController _emailController = TextEditingController(
    text: widget.settings.profileEmail,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _commitName() {
    widget.settings.setProfileName(_nameController.text);
    // The controller normalises an empty name back to the default.
    _nameController.text = widget.settings.profileName;
  }

  void _commitEmail() => widget.settings.setProfileEmail(_emailController.text);

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceCardHeader(
            title: 'Profile',
            subtitle: 'Shown in the sidebar. Stored on this device only.',
            icon: HugeIcons.strokeRoundedUser,
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final avatar = Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.settings.profileInitials,
                  style: TextStyle(
                    color: tokens.onBrand,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );

              final fields = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LingoDeskTextField(
                    controller: _nameController,
                    label: 'Display name',
                    hintText: 'Local workspace',
                    prefixIcon: HugeIcons.strokeRoundedUser,
                    size: LingoDeskFieldSize.large,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _commitName(),
                    onFocusLost: (_) => _commitName(),
                  ),
                  const SizedBox(height: 16),
                  LingoDeskTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'optional',
                    prefixIcon: HugeIcons.strokeRoundedMail01,
                    size: LingoDeskFieldSize.large,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _commitEmail(),
                    onFocusLost: (_) => _commitEmail(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'LingoDesk has no accounts. This only labels your local '
                    'workspace.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              );

              // The avatar beside the fields needs a phone's full width
              // and then some; below that it sits above them.
              if (WindowSizeClass.fromWidth(constraints.maxWidth).isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [avatar, const SizedBox(height: 18), fields],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 18),
                  Expanded(child: fields),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
