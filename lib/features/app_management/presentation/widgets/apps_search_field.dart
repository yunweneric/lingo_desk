import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../bloc/app_management_bloc.dart';
import '../bloc/app_management_event.dart';

/// Filters the apps table by name through [SearchAppsEvent].
class AppsSearchField extends StatefulWidget {
  const AppsSearchField({super.key, this.width = 280});

  final double width;

  @override
  State<AppsSearchField> createState() => _AppsSearchFieldState();
}

class _AppsSearchFieldState extends State<AppsSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return SizedBox(
      width: widget.width,
      height: 42,
      child: TextField(
        controller: _controller,
        onChanged:
            (value) =>
                context.read<AppManagementBloc>().add(SearchAppsEvent(value)),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: tokens.foreground),
        decoration: InputDecoration(
          hintText: 'Search apps',
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: LingoDeskIcon(
              HugeIcons.strokeRoundedGlobalSearch,
              color: tokens.muted,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  _controller.clear();
                  context.read<AppManagementBloc>().add(SearchAppsEvent(''));
                },
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedCancel01,
                  color: tokens.muted,
                  size: 16,
                ),
              );
            },
          ),
          filled: true,
          fillColor: tokens.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.border),
          ),
        ),
      ),
    );
  }
}
