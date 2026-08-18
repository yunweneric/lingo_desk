import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/app_icon_repository.dart';

/// Opens the image picker for an app icon.
///
/// Succeeds with the encoded icon, or with null when the user cancels —
/// canceling a picker is not a failure.
class PickAppIcon implements UseCase<String?, NoParams> {
  PickAppIcon(this.repository);

  final AppIconRepository repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) {
    return repository.pickIcon();
  }
}
