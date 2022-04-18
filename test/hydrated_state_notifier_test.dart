import 'dart:async';

import 'package:hydrated_riverpod/hydrated_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class MockStorage extends Mock implements Storage {}

class MyUuidHydratedStateNotifier extends HydratedStateNotifier<String> {
  MyUuidHydratedStateNotifier() : super(const Uuid().v4());

  @override
  Map<String, String> toJson(String state) => {'value': state};

  @override
  String? fromJson(Map<String, dynamic> json) => json['value'] as String?;
}

class MyCallbackHydratedStateNotifier extends HydratedStateNotifier<int> {
  MyCallbackHydratedStateNotifier({this.onFromJsonCalled}) : super(0);

  final void Function(dynamic)? onFromJsonCalled;

  void increment() => state++;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(dynamic json) {
    onFromJsonCalled?.call(json);
    return json['value'] as int?;
  }

  @override
  ErrorListener get onError => (Object error, StackTrace? stackTrace) {};
}

class MyHydratedStateNotifier extends HydratedStateNotifier<int> {
  MyHydratedStateNotifier([
    this._id,
    this._callSuper = true,
    this._storagePrefix,
  ]) : super(0);

  final String? _id;
  final bool _callSuper;
  final String? _storagePrefix;

  @override
  String get id => _id ?? '';

  @override
  String get storagePrefix => _storagePrefix ?? super.storagePrefix;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(dynamic json) => json['value'] as int?;

  @override
  ErrorListener get onError => (Object error, StackTrace? stackTrace) {
        if (_callSuper) super.onError(error, stackTrace);
      };
}

class MyMultiHydratedStateNotifier extends HydratedStateNotifier<int> {
  MyMultiHydratedStateNotifier(String id)
      : _id = id,
        super(0);

  final String _id;

  @override
  String get id => _id;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(dynamic json) => json['value'] as int?;
}

void main() {
  group('HydratedStateNotifier', () {
    late Storage storage;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      when<dynamic>(() => storage.read(any())).thenReturn(<String, dynamic>{});
      when(() => storage.delete(any())).thenAnswer((_) async {});
      when(() => storage.clear()).thenAnswer((_) async {});
    });

    test('reads from storage once upon initialization', () {
      HydratedRiverpod.runZoned(() {
        MyCallbackHydratedStateNotifier();
        verify<dynamic>(
          () => storage.read('MyCallbackHydratedStateNotifier'),
        ).called(1);
      }, createStorage: () => storage);
    });

    test(
        'reads from storage once upon initialization w/custom storagePrefix/id',
        () {
      HydratedRiverpod.runZoned(() {
        const storagePrefix = '__storagePrefix__';
        const id = '__id__';
        MyHydratedStateNotifier(id, true, storagePrefix);
        verify<dynamic>(() => storage.read('$storagePrefix$id')).called(1);
      }, createStorage: () => storage);
    });

    test('writes to storage when onChange is called w/custom storagePrefix/id',
        () {
      HydratedRiverpod.runZoned(() {
        const expected = <String, int>{'value': 0};
        const storagePrefix = '__storagePrefix__';
        const id = '__id__';
        MyHydratedStateNotifier(id, true, storagePrefix).state = 0;
        verify(() => storage.write('$storagePrefix$id', expected)).called(2);
      }, createStorage: () => storage);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache value exists', () {
      HydratedRiverpod.runZoned(() {
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
        final stateNotifier = MyCallbackHydratedStateNotifier();
        expect(stateNotifier.state, 42);
        stateNotifier.increment();
        expect(stateNotifier.state, 43);
        verify<dynamic>(() => storage.read('MyCallbackHydratedStateNotifier'))
            .called(1);
      }, createStorage: () => storage);
    });

    test(
        'does not deserialize state on subsequent state changes '
        'when cache value exists', () {
      HydratedRiverpod.runZoned(() {
        final fromJsonCalls = <dynamic>[];
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
        final stateNotifier = MyCallbackHydratedStateNotifier(
          onFromJsonCalled: fromJsonCalls.add,
        );
        expect(stateNotifier.state, 42);
        stateNotifier.increment();
        expect(stateNotifier.state, 43);
        expect(fromJsonCalls, [
          {'value': 42}
        ]);
      }, createStorage: () => storage);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is empty', () {
      HydratedRiverpod.runZoned(() {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        final stateNotifier = MyCallbackHydratedStateNotifier();
        expect(stateNotifier.state, 0);
        stateNotifier.increment();
        expect(stateNotifier.state, 1);
        verify<dynamic>(() => storage.read('MyCallbackHydratedStateNotifier'))
            .called(1);
      }, createStorage: () => storage);
    });

    test('does not deserialize state when cache is empty', () {
      HydratedRiverpod.runZoned(() {
        final fromJsonCalls = <dynamic>[];
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        final stateNotifier = MyCallbackHydratedStateNotifier(
          onFromJsonCalled: fromJsonCalls.add,
        );
        expect(stateNotifier.state, 0);
        stateNotifier.increment();
        expect(stateNotifier.state, 1);
        expect(fromJsonCalls, isEmpty);
      }, createStorage: () => storage);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is malformed', () {
      HydratedRiverpod.runZoned(() {
        when<dynamic>(() => storage.read(any())).thenReturn('{');
        final stateNotifier = MyCallbackHydratedStateNotifier();
        expect(stateNotifier.state, 0);
        stateNotifier.increment();
        expect(stateNotifier.state, 1);
        verify<dynamic>(() => storage.read('MyCallbackHydratedStateNotifier'))
            .called(1);
      }, createStorage: () => storage);
    });

    test('does not deserialize state when cache is malformed', () {
      HydratedRiverpod.runZoned(() {
        final fromJsonCalls = <dynamic>[];
        runZonedGuarded(
          () {
            when<dynamic>(() => storage.read(any())).thenReturn('{');
            MyCallbackHydratedStateNotifier(
                onFromJsonCalled: fromJsonCalls.add);
          },
          (_, __) {
            expect(fromJsonCalls, isEmpty);
          },
        );
      }, createStorage: () => storage);
    });

    group('SingleHydratedNotifier', () {
      test('should throw StorageNotFound when storage is null', () {
        expect(
          () => MyHydratedStateNotifier(),
          throwsA(isA<StorageNotFound>()),
        );
      });

      test('should throw StorageNotFound when storage is default', () {
        HydratedRiverpod.runZoned(() {
          expect(
            () => MyHydratedStateNotifier(),
            throwsA(isA<StorageNotFound>()),
          );
        });
      });

      test('StorageNotFound overrides toString', () {
        expect(
          // ignore: prefer_const_constructors
          StorageNotFound().toString(),
          'Storage was accessed before it was initialized.\n'
          'Please ensure that storage has been initialized.\n'
          '\n'
          'For example:\n'
          '\n'
          'HydratedRiverpod.runZoned(\n'
          '  () => runApp(MyApp()),\n'
          '  createStorage: () => HydratedStorage.build(...),\n'
          ');',
        );
      });

      test('storage getter returns correct storage instance', () {
        final storage = MockStorage();
        HydratedRiverpod.runZoned(() {
          expect(HydratedRiverpod.current!.storage, equals(storage));
        }, createStorage: () => storage);
      });

      test('should call storage.write when onChange is called', () {
        HydratedRiverpod.runZoned(() {
          final expected = <String, int>{'value': 0};
          MyHydratedStateNotifier().state = 0;
          verify(() => storage.write('MyHydratedStateNotifier', expected))
              .called(2);
        }, createStorage: () => storage);
      });

      test(
          'should call storage.write when onChange is called with stateNotifier id',
          () {
        HydratedRiverpod.runZoned(() {
          final stateNotifier = MyHydratedStateNotifier('A');
          final expected = <String, int>{'value': 0};
          stateNotifier.state = 0;
          verify(() => storage.write('MyHydratedStateNotifierA', expected))
              .called(2);
        }, createStorage: () => storage);
      });

      test('should throw BlocUnhandledErrorException when storage.write throws',
          () {
        HydratedRiverpod.runZoned(() {
          runZonedGuarded(
            () async {
              final expectedError = Exception('oops');

              when(
                () => storage.write(any(), any<dynamic>()),
              ).thenThrow(expectedError);
              MyHydratedStateNotifier().state = 0;
              await Future<void>.delayed(const Duration(seconds: 300));
              fail('should throw');
            },
            (error, _) {
              expect(error.toString(), 'Exception: oops');
            },
          );
        }, createStorage: () => storage);
      });

      test('stores initial state when instantiated', () {
        HydratedRiverpod.runZoned(() {
          MyHydratedStateNotifier();
          verify(
            () => storage.write('MyHydratedStateNotifier', {'value': 0}),
          ).called(1);
        }, createStorage: () => storage);
      });

      test('initial state should return 0 when fromJson returns null', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn(null);
          expect(MyHydratedStateNotifier().state, 0);
          verify<dynamic>(() => storage.read('MyHydratedStateNotifier'))
              .called(1);
        }, createStorage: () => storage);
      });

      test('initial state should return 0 when deserialization fails', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenThrow(Exception('oops'));
          expect(MyHydratedStateNotifier('', false).state, 0);
        }, createStorage: () => storage);
      });

      test('initial state should return 101 when fromJson returns 101', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn({'value': 101});
          expect(MyHydratedStateNotifier().state, 101);
          verify<dynamic>(() => storage.read('MyHydratedStateNotifier'))
              .called(1);
        }, createStorage: () => storage);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await HydratedRiverpod.runZoned(() async {
            await MyHydratedStateNotifier().clear();
            verify(() => storage.delete('MyHydratedStateNotifier')).called(1);
          }, createStorage: () => storage);
        });
      });
    });

    group('MultiHydratedNotifier', () {
      test('initial state should return 0 when fromJson returns null', () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(() => storage.read(any())).thenReturn(null);
          expect(MyMultiHydratedStateNotifier('A').state, 0);
          verify<dynamic>(
            () => storage.read('MyMultiHydratedStateNotifierA'),
          ).called(1);

          expect(MyMultiHydratedStateNotifier('B').state, 0);
          verify<dynamic>(
            () => storage.read('MyMultiHydratedStateNotifierB'),
          ).called(1);
        }, createStorage: () => storage);
      });

      test('initial state should return 101/102 when fromJson returns 101/102',
          () {
        HydratedRiverpod.runZoned(() {
          when<dynamic>(
            () => storage.read('MyMultiHydratedStateNotifierA'),
          ).thenReturn({'value': 101});
          expect(MyMultiHydratedStateNotifier('A').state, 101);
          verify<dynamic>(
            () => storage.read('MyMultiHydratedStateNotifierA'),
          ).called(1);

          when<dynamic>(
            () => storage.read('MyMultiHydratedStateNotifierB'),
          ).thenReturn({'value': 102});
          expect(MyMultiHydratedStateNotifier('B').state, 102);
          verify<dynamic>(
            () => storage.read('MyMultiHydratedStateNotifierB'),
          ).called(1);
        }, createStorage: () => storage);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await HydratedRiverpod.runZoned(() async {
            await MyMultiHydratedStateNotifier('A').clear();
            verify(() => storage.delete('MyMultiHydratedStateNotifierA'))
                .called(1);
            verifyNever(() => storage.delete('MyMultiHydratedStateNotifierB'));

            await MyMultiHydratedStateNotifier('B').clear();
            verify(() => storage.delete('MyMultiHydratedStateNotifierB'))
                .called(1);
          }, createStorage: () => storage);
        });
      });
    });

    group('MyUuidHydratedStateNotifier', () {
      test('stores initial state when instantiated', () {
        HydratedRiverpod.runZoned(() {
          MyUuidHydratedStateNotifier();
          verify(
            () => storage.write('MyUuidHydratedStateNotifier', any<dynamic>()),
          ).called(1);
        }, createStorage: () => storage);
      });

      test('correctly caches computed initial state', () {
        HydratedRiverpod.runZoned(() {
          dynamic cachedState;
          when<dynamic>(() => storage.read(any())).thenReturn(cachedState);
          when(
            () => storage.write(any(), any<dynamic>()),
          ).thenAnswer((_) => Future<void>.value());
          MyUuidHydratedStateNotifier();
          final captured = verify(
            () => storage.write(
                'MyUuidHydratedStateNotifier', captureAny<dynamic>()),
          ).captured;
          cachedState = captured.first;
          when<dynamic>(() => storage.read(any())).thenReturn(cachedState);
          MyUuidHydratedStateNotifier();
          final secondCaptured = verify(
            () => storage.write(
                'MyUuidHydratedStateNotifier', captureAny<dynamic>()),
          ).captured;
          final dynamic initialStateB = secondCaptured.first;

          expect(initialStateB, cachedState);
        }, createStorage: () => storage);
      });
    });
  });
}
