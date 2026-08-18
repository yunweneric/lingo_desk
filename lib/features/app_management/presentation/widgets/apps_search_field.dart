import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../bloc/app_management_bloc.dart';
import '../bloc/app_management_event.dart';

/// Filters the apps table by name through [SearchAppsEvent].
class AppsSearchField extends StatelessWidget {
  const AppsSearchField({super.key, this.width = 280});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: LingoDeskTextField(
        hintText: 'Search apps',
        prefixIcon: HugeIcons.strokeRoundedGlobalSearch,
        clearable: true,
        onChanged:
            (value) =>
                context.read<AppManagementBloc>().add(SearchAppsEvent(value)),
      ),
    );
  }
}
