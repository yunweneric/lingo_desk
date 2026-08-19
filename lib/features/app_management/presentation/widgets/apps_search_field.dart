import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../bloc/app_management_bloc.dart';
import '../bloc/app_management_event.dart';
import '../../../../core/localization/export.dart';

/// Filters the apps table by name through [SearchAppsEvent].
class AppsSearchField extends StatelessWidget {
  const AppsSearchField({super.key, this.width = 280, this.expand = false});

  final double width;

  /// Fills whatever width it is given instead of holding [width] — what a
  /// phone wants, where 280px of field is most of the screen anyway.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : width,
      child: LingoDeskTextField(
        hintText: LocaleKeys.appsSearchHint.tr(),
        prefixIcon: HugeIcons.strokeRoundedGlobalSearch,
        clearable: true,
        onChanged: (value) =>
            context.read<AppManagementBloc>().add(SearchAppsEvent(value)),
      ),
    );
  }
}
