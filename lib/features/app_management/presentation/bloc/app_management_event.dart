abstract class AppManagementEvent {}

/// Loads (or reloads) the app list with stats.
class LoadAppsEvent extends AppManagementEvent {}

/// Filters the app list by name.
class SearchAppsEvent extends AppManagementEvent {
  SearchAppsEvent(this.query);

  final String query;
}

/// Deletes an app and its translations.
class DeleteAppEvent extends AppManagementEvent {
  DeleteAppEvent(this.appId);

  final String appId;
}
