// Mock factory functions for creating test data
//
// Use these factories to create consistent test data across tests.
// This helps maintain test data consistency and makes tests more readable.

// Example mock factories - customize based on your entities
//
// class MockAppFactory {
//   static App create({
//     String? id,
//     String? name,
//     String? sourceLanguage,
//     List<String>? targetLanguages,
//   }) {
//     return App(
//       id: id ?? 'test-id-1',
//       name: name ?? 'Test App',
//       sourceLanguage: sourceLanguage ?? 'en',
//       targetLanguages: targetLanguages ?? ['es', 'fr'],
//     );
//   }
//
//   static List<App> createList({int count = 3}) {
//     return List.generate(
//       count,
//       (index) => create(
//         id: 'test-id-$index',
//         name: 'Test App $index',
//       ),
//     );
//   }
// }
