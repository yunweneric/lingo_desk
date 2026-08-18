import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../app_management/domain/entities/app.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import '../widgets/app_settings_form_fields.dart';

/// Edit an existing app's configuration (name, source language,
/// target languages). Creation happens in [CreateAppDialog].
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key, required this.app});

  final App app;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              getIt<AppSettingsBloc>()
                ..add(InitializeAppSettingsEvent(app: app)),
      child: _AppSettingsView(app: app),
    );
  }
}

class _AppSettingsView extends StatefulWidget {
  const _AppSettingsView({required this.app});

  final App app;

  @override
  State<_AppSettingsView> createState() => _AppSettingsViewState();
}

class _AppSettingsViewState extends State<_AppSettingsView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.app.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsBloc, AppSettingsState>(
      listener: (context, state) {
        if (state is AppSettingsSaveSuccess) {
          final router = GoRouter.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved "${state.app.name}".')));
          router.pop(true);
        }
      },
      builder: (context, state) {
        final ready = state is AppSettingsReady ? state : null;

        return WorkspaceScaffold(
          title: 'App settings',
          subtitle: widget.app.name,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child:
                    ready == null
                        ? const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: CircularProgressIndicator(),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            WorkspaceSurface(
                              child: AppSettingsFormFields(
                                state: ready,
                                nameController: _nameController,
                                onSubmitted: () => _save(context),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed:
                                      ready.isSaving
                                          ? null
                                          : () =>
                                              Navigator.of(context).maybePop(),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed:
                                      ready.isSaving
                                          ? null
                                          : () => _save(context),
                                  icon:
                                      ready.isSaving
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
                                  label: const Text('Save changes'),
                                ),
                              ],
                            ),
                          ],
                        ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _save(BuildContext context) {
    context.read<AppSettingsBloc>().add(
      SaveAppSettingsEvent(_nameController.text),
    );
  }
}
