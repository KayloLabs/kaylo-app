# Riverpod Conventions for Kaylo

To keep state management consistent across all feature teams, follow these rules when creating Riverpod providers.

## 1. Naming Conventions

- **Providers**: Suffix with `Provider`. (e.g., `homeRepositoryProvider`, `userProfileProvider`).
- **Controllers**: Suffix UI state controllers with `ControllerProvider`. (e.g., `DashboardControllerProvider`, `LoginControllerProvider`).
- **State Classes**: Name the state class after the feature/screen. (e.g., `DashboardState`).

## 2. Choosing the Right Provider

- **`Provider`**: Use for injecting dependencies, interfaces, and repositories.
  ```dart
  final myRepositoryProvider = Provider<MyRepository>((ref) => MyRepositoryImpl());
  ```
- **`Notifier` / `NotifierProvider`**: Use for synchronous, mutable state (e.g., UI toggles, simple counters).
- **`AsyncNotifier` / `AsyncNotifierProvider`**: Use for asynchronous state (fetching data from Firestore, submitting forms).
  ```dart
  class BookingController extends AsyncNotifier<BookingState> { ... }
  ```

## 3. Dependency Injection (Repositories & Services)

- **Do NOT** instantiate repositories directly in your UI or Controllers.
- **Always** inject them via `ref.watch` inside the provider definition or within the `Notifier` body.

```dart
// ✅ Correct
class DashboardController extends AsyncNotifier<DashboardState> {
  late final HomeRepository _homeRepo;

  @override
  FutureOr<DashboardState> build() {
    _homeRepo = ref.watch(homeRepositoryProvider);
    return _fetchData();
  }
}
```

## 4. The `--dart-define=USE_MOCK=true` Toggle

When `USE_MOCK=true` is passed during build/run, the repository providers will return in-memory fakes so you can build UI without waiting for Firebase to be fully wired.

```bash
flutter run --dart-define=USE_MOCK=true
```

Make sure your repository provider looks like this:
```dart
final someRepositoryProvider = Provider<SomeRepository>((ref) {
  if (useMock) return MockSomeRepository();
  return RealSomeRepository(); // TODO: M2 wires real firebase here
});
```
