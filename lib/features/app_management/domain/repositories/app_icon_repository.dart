import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

/// Source of app icons picked from disk, already normalized for storage.
abstract class AppIconRepository {
  /// Picks an image and returns it base64-encoded, or null when the user
  /// cancels the picker.
  Future<Either<Failure, String?>> pickIcon();
}
