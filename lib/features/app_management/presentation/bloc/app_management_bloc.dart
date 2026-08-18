import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/delete_app.dart';
import '../../domain/usecases/get_app_overviews.dart';
import 'app_management_event.dart';
import 'app_management_state.dart';

class AppManagementBloc extends Bloc<AppManagementEvent, AppManagementState> {
  AppManagementBloc({required this.getAppOverviews, required this.deleteApp})
    : super(AppManagementInitial()) {
    on<LoadAppsEvent>(_onLoadApps);
    on<SearchAppsEvent>(_onSearchApps);
    on<DeleteAppEvent>(_onDeleteApp);
  }

  final GetAppOverviews getAppOverviews;
  final DeleteApp deleteApp;

  Future<void> _onLoadApps(
    LoadAppsEvent event,
    Emitter<AppManagementState> emit,
  ) async {
    final previous = state;
    // Keep the current list on screen while refreshing.
    if (previous is! AppManagementLoaded) {
      emit(AppManagementLoading());
    }
    final result = await getAppOverviews(const NoParams());
    result.fold((failure) => emit(AppManagementError(failure.message)), (
      overviews,
    ) {
      final query = previous is AppManagementLoaded ? previous.query : '';
      emit(AppManagementLoaded(overviews: overviews, query: query));
    });
  }

  void _onSearchApps(SearchAppsEvent event, Emitter<AppManagementState> emit) {
    final current = state;
    if (current is AppManagementLoaded) {
      emit(current.copyWith(query: event.query));
    }
  }

  Future<void> _onDeleteApp(
    DeleteAppEvent event,
    Emitter<AppManagementState> emit,
  ) async {
    final result = await deleteApp(DeleteAppParams(appId: event.appId));
    await result.fold(
      (failure) async => emit(AppManagementError(failure.message)),
      (_) async {
        // Reload stats after the delete.
        final refreshed = await getAppOverviews(const NoParams());
        refreshed.fold((failure) => emit(AppManagementError(failure.message)), (
          overviews,
        ) {
          final query =
              state is AppManagementLoaded
                  ? (state as AppManagementLoaded).query
                  : '';
          emit(AppManagementLoaded(overviews: overviews, query: query));
        });
      },
    );
  }
}
