import 'package:hydrated_riverpod/hydrated_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorage extends Mock implements Storage {}

final myCallbackHydratedStateProvider = HydratedStateProvider((ref) {
  return 0;
}, name: 'myCallbackHydratedStateProvider');

final myCallbackFamilyHydratedStateProvider =
    HydratedStateProvider.family((ref, id) {
  return 0;
}, name: 'myCallbackFamilyHydratedStateProvider');

final myCallbackAutoDisposeHydratedStateProvider =
    HydratedStateProvider.autoDispose((ref) {
  return 0;
}, name: 'myCallbackAutoDisposeHydratedStateProvider');

final myCallbackFamilyAutoDisposeHydratedStateProvider =
    HydratedStateProvider.family.autoDispose((ref, id) {
  return 0;
}, name: 'myCallbackFamilyAutoDisposeHydratedStateProvider');

final myCallbackAutoDisposeFamilyHydratedStateProvider =
    HydratedStateProvider.autoDispose.family((ref, id) {
  return 0;
}, name: 'myCallbackAutoDisposeFamilyHydratedStateProvider');

void main() {
  group('HydratedState', () {
    late Storage storage;
    setUp(() {
      storage = MockStorage();
      when<dynamic>(() => storage.read(any())).thenReturn(<String, dynamic>{});
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      when(() => storage.delete(any())).thenAnswer((_) async {});
      when(() => storage.clear()).thenAnswer((_) async {});
    });

    test('storage getter returns correct storage instance', () {
      final storage = MockStorage();
      HydratedRiverpod.runZoned(() {
        expect(HydratedRiverpod.current!.storage, equals(storage));
      }, createStorage: () => storage);
    });

    test('reads from storage once upon initialization', () {
      HydratedRiverpod.runZoned(() {
        final container = ProviderContainer();
        // ignore: unused_local_variable
        final state = container.read(myCallbackHydratedStateProvider.notifier);

        verify<dynamic>(() => storage.read('myCallbackHydratedStateProvider'))
            .called(1);
      }, createStorage: () => storage);
    });

    test('writes to storage when onChange is called w/custom storagePrefix/id',
        () {
      HydratedRiverpod.runZoned(() {
        const expected = <String, int>{'value': 0};
        final container = ProviderContainer();
        container.read(myCallbackHydratedStateProvider.notifier).state = 0;
        verify(() => storage.write('myCallbackHydratedStateProvider', expected))
            .called(2);
      }, createStorage: () => storage);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache value exists', () async {
      await HydratedRiverpod.runZoned(() async {
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
        final container = ProviderContainer();
        final state = container.read(myCallbackHydratedStateProvider.notifier);
        expect(state.state, 42);
        state.state++;
        expect(state.state, 43);
        verify<dynamic>(() => storage.read('myCallbackHydratedStateProvider'))
            .called(1);
      }, createStorage: () => storage);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is empty', () {
      HydratedRiverpod.runZoned(() {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        final container = ProviderContainer();
        final state = container.read(myCallbackHydratedStateProvider.notifier);
        expect(state.state, 0);
        state.state++;
        expect(state.state, 1);
        verify<dynamic>(() => storage.read('myCallbackHydratedStateProvider'))
            .called(1);
      }, createStorage: () => storage);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is malformed', () {
      HydratedRiverpod.runZoned(() {
        when<dynamic>(() => storage.read(any())).thenReturn('{');
        final container = ProviderContainer();
        final state = container.read(myCallbackHydratedStateProvider.notifier);
        expect(state.state, 0);
        state.state++;
        expect(state.state, 1);
        verify<dynamic>(() => storage.read('myCallbackHydratedStateProvider'))
            .called(1);
      }, createStorage: () => storage);
    });

    group('FamilyHydratedState', () {
      test('reads from storage once upon initialization', () {
        HydratedRiverpod.runZoned(() {
          final container = ProviderContainer();
          // ignore: unused_local_variable
          final state = container
              .read(myCallbackFamilyHydratedStateProvider('').notifier);

          verify<dynamic>(
                  () => storage.read('myCallbackFamilyHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });

      test(
          'writes to storage when onChange is called w/custom storagePrefix/id',
          () {
        HydratedRiverpod.runZoned(() {
          const expected = <String, int>{'value': 0};
          final container = ProviderContainer();
          container
              .read(myCallbackFamilyHydratedStateProvider('').notifier)
              .state = 0;
          verify(() => storage.write(
              'myCallbackFamilyHydratedStateProvider', expected)).called(2);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache value exists', () async {
        await HydratedRiverpod.runZoned(() async {
          when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
          final container = ProviderContainer();
          final state = container
              .read(myCallbackFamilyHydratedStateProvider('').notifier);
          expect(state.state, 42);
          state.state++;
          expect(state.state, 43);
          verify<dynamic>(
                  () => storage.read('myCallbackFamilyHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is empty', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn(null);
          final container = ProviderContainer();
          final state = container
              .read(myCallbackFamilyHydratedStateProvider('').notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(
                  () => storage.read('myCallbackFamilyHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is malformed', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn('{');
          final container = ProviderContainer();
          final state = container
              .read(myCallbackFamilyHydratedStateProvider('').notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(
                  () => storage.read('myCallbackFamilyHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });
    });

    group('AutoDisposeHydratedState', () {
      test('reads from storage once upon initialization', () {
        HydratedRiverpod.runZoned(() {
          final container = ProviderContainer();
          // ignore: unused_local_variable
          final state = container
              .read(myCallbackAutoDisposeHydratedStateProvider.notifier);

          verify<dynamic>(() =>
                  storage.read('myCallbackAutoDisposeHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });

      test(
          'writes to storage when onChange is called w/custom storagePrefix/id',
          () {
        HydratedRiverpod.runZoned(() {
          const expected = <String, int>{'value': 0};
          final container = ProviderContainer();
          container
              .read(myCallbackAutoDisposeHydratedStateProvider.notifier)
              .state = 0;
          verify(() => storage.write(
                  'myCallbackAutoDisposeHydratedStateProvider', expected))
              .called(2);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache value exists', () async {
        await HydratedRiverpod.runZoned(() async {
          when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
          final container = ProviderContainer();
          final state = container
              .read(myCallbackAutoDisposeHydratedStateProvider.notifier);
          expect(state.state, 42);
          state.state++;
          expect(state.state, 43);
          verify<dynamic>(() =>
                  storage.read('myCallbackAutoDisposeHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is empty', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn(null);
          final container = ProviderContainer();
          final state = container
              .read(myCallbackAutoDisposeHydratedStateProvider.notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(() =>
                  storage.read('myCallbackAutoDisposeHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is malformed', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn('{');
          final container = ProviderContainer();
          final state = container
              .read(myCallbackAutoDisposeHydratedStateProvider.notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(() =>
                  storage.read('myCallbackAutoDisposeHydratedStateProvider'))
              .called(1);
        }, createStorage: () => storage);
      });
    });

    group('AutoDisposeFamilyHydratedState', () {
      test('reads from storage once upon initialization', () {
        HydratedRiverpod.runZoned(() {
          final container = ProviderContainer();
          // ignore: unused_local_variable
          final state = container.read(
              myCallbackAutoDisposeFamilyHydratedStateProvider('').notifier);

          verify<dynamic>(() => storage.read(
              'myCallbackAutoDisposeFamilyHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });

      test(
          'writes to storage when onChange is called w/custom storagePrefix/id',
          () {
        HydratedRiverpod.runZoned(() {
          const expected = <String, int>{'value': 0};
          final container = ProviderContainer();
          container
              .read(
                  myCallbackAutoDisposeFamilyHydratedStateProvider('').notifier)
              .state = 0;
          verify(() => storage.write(
                  'myCallbackAutoDisposeFamilyHydratedStateProvider', expected))
              .called(2);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache value exists', () async {
        await HydratedRiverpod.runZoned(() async {
          when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
          final container = ProviderContainer();
          final state = container.read(
              myCallbackAutoDisposeFamilyHydratedStateProvider('').notifier);
          expect(state.state, 42);
          state.state++;
          expect(state.state, 43);
          verify<dynamic>(() => storage.read(
              'myCallbackAutoDisposeFamilyHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is empty', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn(null);
          final container = ProviderContainer();
          final state = container.read(
              myCallbackAutoDisposeFamilyHydratedStateProvider('').notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(() => storage.read(
              'myCallbackAutoDisposeFamilyHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is malformed', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn('{');
          final container = ProviderContainer();
          final state = container.read(
              myCallbackAutoDisposeFamilyHydratedStateProvider('').notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(() => storage.read(
              'myCallbackAutoDisposeFamilyHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });
    });

    group('FamilyAutoDisposeHydratedState', () {
      test('reads from storage once upon initialization', () {
        HydratedRiverpod.runZoned(() {
          final container = ProviderContainer();
          // ignore: unused_local_variable
          final state = container.read(
              myCallbackFamilyAutoDisposeHydratedStateProvider('').notifier);

          verify<dynamic>(() => storage.read(
              'myCallbackFamilyAutoDisposeHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });

      test(
          'writes to storage when onChange is called w/custom storagePrefix/id',
          () {
        HydratedRiverpod.runZoned(() {
          const expected = <String, int>{'value': 0};
          final container = ProviderContainer();
          container
              .read(
                  myCallbackFamilyAutoDisposeHydratedStateProvider('').notifier)
              .state = 0;
          verify(() => storage.write(
                  'myCallbackFamilyAutoDisposeHydratedStateProvider', expected))
              .called(2);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache value exists', () async {
        await HydratedRiverpod.runZoned(() async {
          when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
          final container = ProviderContainer();
          final state = container.read(
              myCallbackFamilyAutoDisposeHydratedStateProvider('').notifier);
          expect(state.state, 42);
          state.state++;
          expect(state.state, 43);
          verify<dynamic>(() => storage.read(
              'myCallbackFamilyAutoDisposeHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is empty', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn(null);
          final container = ProviderContainer();
          final state = container.read(
              myCallbackFamilyAutoDisposeHydratedStateProvider('').notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(() => storage.read(
              'myCallbackFamilyAutoDisposeHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is malformed', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn('{');
          final container = ProviderContainer();
          final state = container.read(
              myCallbackFamilyAutoDisposeHydratedStateProvider('').notifier);
          expect(state.state, 0);
          state.state++;
          expect(state.state, 1);
          verify<dynamic>(() => storage.read(
              'myCallbackFamilyAutoDisposeHydratedStateProvider')).called(1);
        }, createStorage: () => storage);
      });
    });
  });
}
