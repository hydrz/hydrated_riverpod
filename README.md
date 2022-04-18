# hydrated_riverpod

---

## Overview

`hydrated_riverpod` extension to the riverpod state management library which automatically persists and restores riverpod states.

Like [`hydrated_bloc`](https://github.com/felangel/bloc/blob/master/packages/hydrated_bloc)

`hydrated_riverpod` exports a `Storage` interface which means it can work with any storage provider. Out of the box, it comes with its own implementation: `HydratedStorage`.

`HydratedStorage` is built on top of [hive](https://pub.dev/packages/hive) for a platform-agnostic, performant storage layer.

## Usage

### Setup `HydratedRiverpod`

```dart
void main() async {
  HydratedRiverpod.runZoned(
    () => runApp(ProviderScope(child: MyApp())),
    createStorage: async () {
      return HydratedStorage.build(storageDirectory: ...);
    },
  );
}
```

### Create a HydratedStateNotifier

```dart
class Counter extends HydratedStateNotifier<int> {
  Counter() : super(0);

  void increment() => state++;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => { 'value': state };
}
```

Now the `Counter` will automatically persist/restore their state. We can increment the counter value, hot restart, kill the app, etc... and the previous state will be retained.

### HydratedMixin

```dart
class Counter extends StateNotifier<int> with HydratedMixin {
  CounterCubit() : super(0) {
    hydrate();
  }

  void increment() => state++;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => { 'value': state };
}
```

## Custom Storage Directory

Any `storageDirectory` can be used when creating an instance of `HydratedStorage`:

```dart
final storage = await HydratedStorage.build(
  storageDirectory: await getApplicationDocumentsDirectory(),
);
```

## Custom Hydrated Storage

If the default `HydratedStorage` doesn't meet your needs, you can always implement a custom `Storage` by simply implementing the `Storage` interface and initializing `HydratedRiverpod` with the custom `Storage`.

```dart
// my_hydrated_storage.dart

class MyHydratedStorage implements Storage {
  @override
  dynamic read(String key) {
    // TODO: implement read
  }

  @override
  Future<void> write(String key, dynamic value) async {
    // TODO: implement write
  }

  @override
  Future<void> delete(String key) async {
    // TODO: implement delete
  }

  @override
  Future<void> clear() async {
    // TODO: implement clear
  }
}
```

```dart
// main.dart

HydratedRiverpod.runZoned(
  () => runApp(ProviderScope(child: MyApp())),
  createStorage: () => MyHydratedStorage(),
);
```

## Dart Versions

- Dart 2: >= 2.12