import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_toast.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../../../app_management/domain/entities/app.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import '../widgets/app_settings_cards.dart';

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
    final tokens = LingoDeskTokens.of(context);

    return BlocConsumer<AppSettingsBloc, AppSettingsState>(
      listener: (context, state) {
        if (state is AppSettingsSaveSuccess) {
          final router = GoRouter.of(context);
          context.showSuccessToast('Saved "${state.app.name}".');
          router.pop(true);
        }
      },
      builder: (context, state) {
        final ready = state is AppSettingsReady ? state : null;

        // Same chassis as the other shell pages: the header spans the
        // pane and the body owns the full width beneath it, rather than
        // a centred column inside its own scaffold.
        return ColoredBox(
          color: tokens.background,
          child: SafeArea(
            child: Column(
              children: [
                WorkspacePageHeader(
                  breadcrumb: [
                    Crumb.workspace,
                    const Crumb('Apps', route: AppRoutes.apps),
                    Crumb(widget.app.name),
                    const Crumb('Settings'),
                  ],
                  actions: [
                    OutlinedButton(
                      onPressed:
                          ready == null || ready.isSaving
                              ? null
                              : () => Navigator.of(context).maybePop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          ready == null || ready.isSaving
                              ? null
                              : () => _save(context),
                      icon:
                          ready != null && ready.isSaving
                              ? const SizedBox.square(
                                dimension: 16,
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
                  child:
                      ready == null
                          ? null
                          : AppSettingsMetaStrip(
                            state: ready,
                            updatedAt: widget.app.updatedAt,
                          ),
                ),
                Expanded(
                  child:
                      ready == null
                          ? const Center(child: CircularProgressIndicator())
                          : _AppSettingsBody(
                            state: ready,
                            nameController: _nameController,
                            onSubmitted: () => _save(context),
                          ),
                ),
              ],
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

/// Two columns on a wide pane — general settings beside the language
/// grid — collapsing to a single stack once there is no room for both.
class _AppSettingsBody extends StatelessWidget {
  const _AppSettingsBody({
    required this.state,
    required this.nameController,
    required this.onSubmitted,
  });

  final AppSettingsReady state;
  final TextEditingController nameController;
  final VoidCallback onSubmitted;

  /// Below this the general card would be too narrow to sit beside the
  /// language grid.
  static const _twoColumnBreakpoint = 1040.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 780 ? 16.0 : 24.0;
        final isWide = constraints.maxWidth >= _twoColumnBreakpoint;

        final general = FadeSlideIn(
          child: AppSettingsGeneralCard(
            state: state,
            nameController: nameController,
            onSubmitted: onSubmitted,
          ),
        );
        final languages = FadeSlideIn.staggered(
          index: 1,
          child: AppSettingsLanguagesCard(state: state),
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 28),
          child:
              isWide
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: general),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: languages),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [general, const SizedBox(height: 16), languages],
                  ),
        );
      },
    );
  }
}
