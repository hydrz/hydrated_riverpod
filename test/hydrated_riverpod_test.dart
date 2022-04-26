import 'dart:async';

import 'package:hydrated_riverpod/hydrated_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class FakeStorage extends Fake implements Storage {}

void main() {
  test('uses default storage when not specified', () {
    HydratedRiverpod.initialize();
    final scope = HydratedRiverpod.instance;
    expect(scope!.storage, isA<Storage>());
  });

  test('uses custom storage when specified', () {
    runZoned(() {
      final storage = FakeStorage();

      HydratedRiverpod.initialize(storage: storage);
      final scope = HydratedRiverpod.instance;
      expect(scope!.storage, equals(storage));
    });
  });

  test('scope cannot be mutated after zone is created', () {
    final originalStorage = FakeStorage();
    final otherStorage = FakeStorage();
    var storage = originalStorage;

    HydratedRiverpod.initialize(storage: storage);
    storage = otherStorage;
    final scope = HydratedRiverpod.instance!;
    expect(scope.storage, equals(originalStorage));
    expect(scope.storage, isNot(equals(otherStorage)));
  });

  test('uses parent storage when nested zone does not specify', () {
    final storage = FakeStorage();

    HydratedRiverpod.initialize(storage: storage);
    final scope = HydratedRiverpod.instance;
    expect(scope!.storage, equals(storage));
  });
}
