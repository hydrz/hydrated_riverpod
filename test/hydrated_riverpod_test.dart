import 'dart:async';
import 'dart:io';

import 'package:hydrated_riverpod/hydrated_riverpod.dart';

// We create a "provider", which will store a value (here "Hello world").
// By using a provider, this allows us to mock/override the value exposed.
class CounterStateNotifier extends HydratedStateNotifier<int> {
  CounterStateNotifier() : super(0);

  void increment() => state++;
  void decrement() => state++;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => {'value': state};
}

final testProvider = StateNotifierProvider<CounterStateNotifier, int>(
  (ref) => CounterStateNotifier(),
);

final cityProvider = StateProvider((ref) => 0);

final helloWorldProvider = Provider((ref) => ref.watch(testProvider));

void main() {
  HydratedRiverpodOverride.runZoned(
    () {
      // This object is where the state of our providers will be stored.
      final ref = ProviderContainer(overrides: []);

      // Thanks to "container", we can read our provider.

      print('helloWorldProvider: ' + ref.read(helloWorldProvider).toString());

      // ignore: cascade_invocations
      ref.listen(helloWorldProvider, (previous, next) {
        print('previous: $previous');
        print('next: $next');
      });

      Timer.periodic(Duration(seconds: 1), (timer) {
        ref.read(testProvider.notifier).increment();
      });
    },
    createStorage: () => HydratedStorage.build(
      storageDirectory: Directory('./hive'),
    ),
  );

  // print(ref.read(testProvider));

  // ref.read(cityProvider.state).state++;
}
