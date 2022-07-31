import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydrated_riverpod/hydrated_riverpod.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageDirectory = kIsWeb
      ? HydratedStorage.webStorageDirectory
      : await getApplicationDocumentsDirectory();
  final storage =
      await HydratedStorage.build(storageDirectory: storageDirectory);
  HydratedRiverpod.initialize(storage: storage);

  runApp(const ProviderScope(child: MyApp()));
}

final counterProvider = HydratedStateProvider((_) => 0, name: '_counter');

final brightnessProvider =
    StateNotifierProvider<BrightnessNotifier, Brightness>(
        (_) => BrightnessNotifier());

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(brightness: brightness),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider.state).state;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            child: const Icon(Icons.brightness_6),
            onPressed: () =>
                ref.read(brightnessProvider.notifier).toggleBrightness(),
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              ref.read(counterProvider.notifier).state++;
            },
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.remove),
            onPressed: () {
              ref.read(counterProvider.notifier).state--;
            },
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.delete_forever),
            onPressed: () {
              HydratedRiverpod.instance?.storage.clear();
            },
          ),
        ],
      ),
    );
  }
}

class BrightnessNotifier extends HydratedStateNotifier<Brightness> {
  BrightnessNotifier() : super(Brightness.light);

  void toggleBrightness() {
    state = state == Brightness.light ? Brightness.dark : Brightness.light;
  }

  @override
  Brightness fromJson(Map<String, dynamic> json) {
    return json['brightness'] == null
        ? Brightness.light
        : Brightness.values[json['brightness'] as int];
  }

  @override
  Map<String, dynamic> toJson(Brightness state) {
    return <String, int>{'brightness': state.index};
  }
}
