// Helper utilities for testing BLoCs
//
// This file provides common patterns and utilities for BLoC testing
// using the bloc_test package.

// Example BLoC test helper - customize based on your BLoCs
//
// Example usage:
// ```dart
// group('AppManagementBloc', () {
//   test('initial state is correct', () {
//     final bloc = AppManagementBloc();
//     expect(bloc.state, equals(AppManagementInitial()));
//   });
//
//   blocTest<AppManagementBloc, AppManagementState>(
//     'emits [loading, success] when GetApps is added',
//     build: () => AppManagementBloc(
//       getAppsUseCase: mockGetAppsUseCase,
//     ),
//     act: (bloc) => bloc.add(GetAppsEvent()),
//     expect: () => [
//       AppManagementLoading(),
//       AppManagementSuccess(apps: mockApps),
//     ],
//   );
// });
// ```

// Helper function to create a mock BLoC for testing
//
// This can be used when you need to test widgets that depend on BLoCs
// class MockAppManagementBloc extends Mock implements AppManagementBloc {}
