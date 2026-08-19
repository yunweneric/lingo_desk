import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/widgets/lingo_desk_dialog.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../app_management/domain/entities/app.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import 'app_settings_form_fields.dart';
import '../../../../core/localization/export.dart';

/// Modal dialog to create a new app.
///
/// Returns the created [App], or null when canceled.
class CreateAppDialog extends StatelessWidget {
  const CreateAppDialog({super.key});

  static Future<App?> show(BuildContext context) {
    return showDialog<App>(
      context: context,
      builder: (_) => const CreateAppDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AppSettingsBloc>()
        ..add(
          InitializeAppSettingsEvent(
            defaultTargetLanguages:
                getIt<AppSettingsController>().defaultTargetLanguages,
          ),
        ),
      child: const _CreateAppDialogView(),
    );
  }
}

class _CreateAppDialogView extends StatefulWidget {
  const _CreateAppDialogView();

  @override
  State<_CreateAppDialogView> createState() => _CreateAppDialogViewState();
}

class _CreateAppDialogViewState extends State<_CreateAppDialogView> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    context.read<AppSettingsBloc>().add(
      SaveAppSettingsEvent(_nameController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsBloc, AppSettingsState>(
      listener: (context, state) {
        if (state is AppSettingsSaveSuccess) {
          Navigator.of(context).pop(state.app);
        }
      },
      builder: (context, state) {
        final ready = state is AppSettingsReady ? state : null;

        return LingoDeskDialog(
          title: Text(LocaleKeys.appsNewApp.tr()),
          preferredWidth: 560,
          content: ready == null
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: AppSettingsFormFields(
                    state: ready,
                    nameController: _nameController,
                    autofocusName: true,
                    onSubmitted: () => _save(context),
                  ),
                ),
          actions: [
            OutlinedButton(
              onPressed: (ready?.isSaving ?? false)
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(LocaleKeys.commonCancel.tr()),
            ),
            FilledButton.icon(
              onPressed: ready == null || ready.isSaving
                  ? null
                  : () => _save(context),
              icon: (ready?.isSaving ?? false)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const LingoDeskIcon(
                      HugeIcons.strokeRoundedTick02,
                      color: Colors.white,
                      size: 18,
                    ),
              label: Text(LocaleKeys.appSettingsCreateApp.tr()),
            ),
          ],
        );
      },
    );
  }
}
