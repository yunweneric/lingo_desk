import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/app_icon_repository.dart';
import '../datasources/app_icon_data_source.dart';

class AppIconRepositoryImpl implements AppIconRepository {
  const AppIconRepositoryImpl({required this.dataSource});

  final AppIconDataSource dataSource;

  @override
  Future<Either<Failure, String?>> pickIcon() async {
    try {
      return Right(await dataSource.pickIcon());
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on Exception catch (e) {
      return Left(FileFailure(message: e.toString()));
    }
  }
}
