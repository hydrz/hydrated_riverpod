part of 'hydrated_state_provider.dart';

// ignore: subtype_of_sealed_class
/// {@macro riverpod.stateprovider}
@sealed
class HydratedAutoDisposeStateProvider<State>
    extends AutoDisposeStateProvider<State> {
  /// {@macro riverpod.stateprovider}
  HydratedAutoDisposeStateProvider(
    Create<State, AutoDisposeStateProviderRef<State>> create, {
    String? name,
    List<ProviderOrFamily>? dependencies,
    Family? from,
    Object? argument,
    Duration? cacheTime,
    Duration? disposeDelay,
  })  : notifier = _HydratedAutoDisposeNotifierProvider(
          create,
          name: name,
          dependencies: dependencies,
          from: from,
          argument: argument,
          cacheTime: cacheTime,
          disposeDelay: disposeDelay,
        ),
        super(create, name: name, from: from, argument: argument);

  /// {@macro riverpod.family}
  static const family = HydratedAutoDisposeStateProviderFamilyBuilder();

  /// {@macro riverpod.stateprovider.notifier}
  @override
  final AutoDisposeProviderBase<StateController<State>> notifier;

  @override
  late final AutoDisposeProviderBase<StateController<State>> state =
      _HydratedAutoDisposeNotifierStateProvider((ref) {
    return _listenStateProvider(
      ref as ProviderElementBase<StateController<State>>,
      ref.watch(notifier),
    );
  }, dependencies: [notifier], from: from, argument: argument);

  @override
  State create(AutoDisposeProviderElementBase<State> ref) {
    final notifier = ref.watch(this.notifier);

    final removeListener = notifier.addListener(ref.setState);
    ref.onDispose(removeListener);

    return notifier.state;
  }

  @override
  bool updateShouldNotify(State previousState, State newState) {
    return true;
  }
}

// ignore: subtype_of_sealed_class
class _HydratedAutoDisposeNotifierProvider<State>
    extends AutoDisposeProviderBase<StateController<State>> {
  _HydratedAutoDisposeNotifierProvider(
    this._create, {
    required String? name,
    required this.dependencies,
    required Family? from,
    required Object? argument,
    required Duration? cacheTime,
    required Duration? disposeDelay,
  }) : super(
          name: name,
          from: from,
          argument: argument,
          cacheTime: cacheTime,
          disposeDelay: disposeDelay,
        );

  final Create<State, AutoDisposeStateProviderRef<State>> _create;

  @override
  final List<ProviderOrFamily>? dependencies;

  @override
  StateController<State> create(AutoDisposeStateProviderRef<State> ref) {
    final initialState = _create(ref);

    final notifier = HydratedStateController(
      initialState,
      storagePrefix: name,
      id: '',
    );

    ref.onDispose(notifier.dispose);
    return notifier;
  }

  @override
  bool updateShouldNotify(
    StateController<State> previousState,
    StateController<State> newState,
  ) {
    return true;
  }

  @override
  _AutoDisposeNotifierStateProviderElement<State> createElement() {
    return _AutoDisposeNotifierStateProviderElement(this);
  }
}

class _AutoDisposeNotifierStateProviderElement<State>
    extends AutoDisposeProviderElementBase<StateController<State>>
    implements AutoDisposeStateProviderRef<State> {
  _AutoDisposeNotifierStateProviderElement(
      _HydratedAutoDisposeNotifierProvider<State> provider)
      : super(provider);

  @override
  StateController<State> get controller => requireState;
}

// ignore: subtype_of_sealed_class
class _HydratedAutoDisposeNotifierStateProvider<State>
    extends AutoDisposeProvider<State> {
  _HydratedAutoDisposeNotifierStateProvider(
    Create<State, AutoDisposeProviderRef<State>> create, {
    List<ProviderOrFamily>? dependencies,
    required Family? from,
    required Object? argument,
  }) : super(
          create,
          dependencies: dependencies,
          from: from,
          argument: argument,
        );

  @override
  bool updateShouldNotify(State previousState, State newState) {
    return true;
  }
}

// ignore: subtype_of_sealed_class
/// {@macro riverpod.stateprovider.family}
@sealed
class HydratedAutoDisposeStateProviderFamily<State, Arg>
    extends AutoDisposeStateProviderFamily<State, Arg> {
  /// {@macro riverpod.stateprovider.family}
  HydratedAutoDisposeStateProviderFamily(
    this._create, {
    String? name,
    List<ProviderOrFamily>? dependencies,
    Duration? cacheTime,
    Duration? disposeDelay,
  }) : super(
          _create,
          name: name,
          dependencies: dependencies,
          cacheTime: cacheTime,
          disposeDelay: disposeDelay,
        );

  final FamilyCreate<State, AutoDisposeStateProviderRef<State>, Arg> _create;

  @override
  HydratedAutoDisposeStateProvider<State> create(Arg argument) {
    return HydratedAutoDisposeStateProvider<State>(
      (ref) => _create(ref, argument),
      name: name,
      from: this,
      argument: argument,
    );
  }

  @override
  void setupOverride(Arg argument, SetupOverride setup) {
    final provider = call(argument);
    setup(origin: provider.notifier, override: provider.notifier);
  }

  /// {@macro riverpod.overridewithprovider}
  @override
  Override overrideWithProvider(
    AutoDisposeStateProvider<State> Function(Arg argument) override,
  ) {
    return FamilyOverride<Arg>(
      this,
      (arg, setup) {
        final provider = call(arg);
        final newProvider = override(arg);
        setup(origin: provider.notifier, override: newProvider.notifier);
      },
    );
  }
}

/// Builds a [HydratedAutoDisposeStateProviderFamily].
class HydratedAutoDisposeStateProviderFamilyBuilder
    extends AutoDisposeStateProviderFamilyBuilder {
  /// Builds a [HydratedAutoDisposeStateProviderFamily].
  const HydratedAutoDisposeStateProviderFamilyBuilder();

  /// {@macro riverpod.family}
  @override
  AutoDisposeStateProviderFamily<State, Arg> call<State, Arg>(
    FamilyCreate<State, AutoDisposeStateProviderRef<State>, Arg> create, {
    String? name,
    List<ProviderOrFamily>? dependencies,
    Duration? cacheTime,
    Duration? disposeDelay,
  }) {
    return HydratedAutoDisposeStateProviderFamily(
      create,
      name: name,
      dependencies: dependencies,
      cacheTime: cacheTime,
      disposeDelay: disposeDelay,
    );
  }
}
