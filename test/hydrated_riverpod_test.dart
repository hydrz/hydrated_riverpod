import 'package:hydrated_riverpod/hydrated_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class FakeStorage extends Fake implements Storage {}

void main() {
  group('HydratedRiverpod', () {
    group('runZoned', () {
      test('uses default storage when not specified', () {
        HydratedRiverpod.runZoned(() {
          final scope = HydratedRiverpod.current;
          expect(scope!.storage, isA<Storage>());
        });
      });

      test('uses custom storage when specified', () {
        final storage = FakeStorage();
        HydratedRiverpod.runZoned(() {
          final scope = HydratedRiverpod.current;
          expect(scope!.storage, equals(storage));
        }, createStorage: () => storage);
      });

      test(
          'uses nested storage when specified '
          'and zone already contains a storage', () {
        final rootStorage = FakeStorage();
        HydratedRiverpod.runZoned(() {
          final nestedStorage = FakeStorage();
          final scope = HydratedRiverpod.current;
          expect(scope!.storage, equals(rootStorage));
          HydratedRiverpod.runZoned(() {
            final scope = HydratedRiverpod.current;
            expect(scope!.storage, equals(nestedStorage));
          }, createStorage: () => nestedStorage);
        }, createStorage: () => rootStorage);
      });

      test('uses parent storage when nested zone does not specify', () {
        final storage = FakeStorage();
        HydratedRiverpod.runZoned(() {
          HydratedRiverpod.runZoned(() {
            final scope = HydratedRiverpod.current;
            expect(scope!.storage, equals(storage));
          });
        }, createStorage: () => storage);
      });

      test('scope cannot be mutated after zone is created', () {
        final originalStorage = FakeStorage();
        final otherStorage = FakeStorage();
        var storage = originalStorage;
        HydratedRiverpod.runZoned(() {
          storage = otherStorage;
          final scope = HydratedRiverpod.current!;
          expect(scope.storage, equals(originalStorage));
          expect(scope.storage, isNot(equals(otherStorage)));
        }, createStorage: () => storage);
      });
    });
  });
}
