import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../app_management/domain/entities/app.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import '../../../../core/localization/export.dart';

/// The app's icon, with the controls to set or drop it.
///
/// The badge is a live preview: with no icon picked it shows the
/// initials of whatever is currently typed in the name field, which is
/// exactly what the apps list will show for this app.
class AppIconField extends StatelessWidget {
  const AppIconField({
    super.key,
    required this.state,
    required this.nameController,
    this.size = 64,
  });

  final AppSettingsReady state;

  /// Watched so the initials track the name as it is typed.
  final TextEditingController nameController;

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final bloc = context.read<AppSettingsBloc>();
    final hasIcon = state.iconImage != null;
    final busy = state.isSaving || state.isPickingIcon;

    return LingoDeskFieldScaffold(
      label: LocaleKeys.appSettingsAppIcon.tr(),
      description: LocaleKeys.appSettingsAppIconHelp.tr(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: nameController,
            builder: (context, value, _) {
              return AppAvatar(
                name: value.text.trim().isEmpty
                    ? LocaleKeys.appsNewApp.tr()
                    : value.text,
                initials: appInitialsFor(value.text),
                iconImage: state.iconImage,
                size: size,
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => bloc.add(AppIconPickRequestedEvent()),
                      icon: state.isPickingIcon
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const LingoDeskIcon(
                              HugeIcons.strokeRoundedImageAdd01,
                              size: 18,
                            ),
                      label: Text(
                        hasIcon
                            ? LocaleKeys.appSettingsReplaceIcon.tr()
                            : LocaleKeys.appSettingsUploadIcon.tr(),
                      ),
                    ),
                    if (hasIcon)
                      TextButton.icon(
                        onPressed: busy
                            ? null
                            : () => bloc.add(AppIconClearedEvent()),
                        icon: const LingoDeskIcon(
                          HugeIcons.strokeRoundedDelete02,
                          size: 17,
                        ),
                        label: Text(LocaleKeys.commonRemove.tr()),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.appSettingsAppIconNote.tr(
                    namedArgs: {'size': '$iconPreviewSize'},
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Longest edge a stored icon keeps, quoted in the field's helper text.
///
/// Mirrors `iconMaxSize` in the data layer; the presentation layer does
/// not import data-layer constants.
const int iconPreviewSize = 256;
