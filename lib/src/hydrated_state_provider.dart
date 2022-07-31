// ignore_for_file: lines_longer_than_80_chars

import 'package:hydrated_riverpod/hydrated_riverpod.dart';
import 'package:meta/meta.dart';
// ignore: implementation_imports
import 'package:riverpod/src/builders.dart';
// ignore: implementation_imports

part 'hydrated_state_auto_dispose_provider.dart';

/// {@template HydratedStateController}
/// Specialized [StateController] which handles initializing the [StateController] state
/// based on the persisted state. This allows state to be persisted
/// across hot restarts as well as complete app restarts.
///
/// ```dart
/// class Counter extends HydratedStateController<int> {
///   Counter() : super(0);
///
///   void increment() => state++;
///
///   void decrement() => state==;
///
///   @override
///   int fromJson(Map<String, dynamic> json) => json['value'] as int;
///
///   @override
///   Map<String, int> toJson(int state) => {'value': state};
/// }
/// ```
///
/// {@endtemplate}
class HydratedStateController<State> extends StateController<State>
    with HydratedMixin {
  /// {@macro HydratedStateController}
  HydratedStateController(
    State state, {
    String? id,
    String? storagePrefix,
  })  : _id = id,
        _storagePrefix = storagePrefix,
        super(state) {
    hydrate();
  }

  /// [id] is used to uniquely identify multiple instances
  final String? _id;

  /// Storage prefix which can be overridden to provide a custom
  /// storage namespace.
  final String? _storagePrefix;

  @override
  String get id => _id != null ? _id! : '';

  /// Storage prefix which can be overridden to provide a custom
  /// storage namespace.
  /// Defaults to [runtimeType] but should be overridden in cases
  /// where stored data should be resilient to obfuscation or persist
  /// between debug/release builds.
  @override
  String get storagePrefix =>
      _storagePrefix != null ? _storagePrefix! : runtimeType.toString();

  @override
  State? fromJson(Map<String, dynamic> json) => json['value'] as State;

  @override
  Map<String, State>? toJson(State state) => {'value': state};

  @override
  ErrorListener get onError => (Object error, StackTrace? stackTrace) {};
}

// ignore: subtype_of_sealed_class
/// {@macro riverpod.stateprovider}
class HydratedStateProvider<State> extends StateProvider<State> {
  /// {@macro riverpod.stateprovider}
  HydratedStateProvider(
    Create<State, StateProviderRef<State>> create, {
    required String name,
    List<ProviderOrFamily>? dependencies,
    Family? from,
    Object? argument,
  })  : notifier = _HydratedNotifierProvider(
          create,
          name: name,
          dependencies: dependencies,
          from: from,
          argument: argument,
        ),
        super(create, name: name, from: from, argument: argument);

  /// {@macro riverpod.family}
  static const family = HydratedStateProviderFamilyBuilder();

  /// {@macro riverpod.autoDispose}
  static const autoDispose = HydratedAutoDisposeStateProviderBuilder();

  @override
  // ignore: overridden_fields
  late final AlwaysAliveProviderBase<StateController<State>> state =
      _HydratedNotifierStateProvider(
    (ref) {
      return _listenStateProvider(
        ref as ProviderElementBase<StateController<State>>,
        ref.watch(notifier),
      );
    },
    dependencies: [notifier],
    from: from,
    argument: argument,
  );

  /// {@template riverpod.stateprovider.notifier}
  /// Obtains the [StateController] associated with this provider, but without
  /// listening to it.
  ///
  /// Listening to this provider may cause providers/widgets to rebuild in the
  /// event that the [StateController] it recreated.
  ///
  ///
  /// It is preferrable to do:
  /// ```dart
  /// ref.watch(stateProvider.notifier)
  /// ```
  ///
  /// instead of:
  /// ```dart
  /// ref.read(stateProvider)
  /// ```
  ///
  /// The reasoning is, using `read` could cause hard to catch bugs, such as
  /// not rebuilding dependent providers/widgets after using `ref.refresh` on this provider.
  /// {@endtemplate}
  @override
  // ignore: overridden_fields
  final AlwaysAliveProviderBase<StateController<State>> notifier;
}

// ignore: subtype_of_sealed_class
class _HydratedNotifierStateProvider<State> extends Provider<State> {
  _HydratedNotifierStateProvider(
    Create<State, ProviderRef<State>> create, {
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
class _HydratedNotifierProvider<State>
    extends AlwaysAliveProviderBase<StateController<State>> {
  _HydratedNotifierProvider(
    this._create, {
    required String? name,
    required this.dependencies,
    required Family? from,
    required Object? argument,
  }) : super(name: name, from: from, argument: argument);

  final Create<State, StateProviderRef<State>> _create;

  @override
  final List<ProviderOrFamily>? dependencies;

  @override
  StateController<State> create(StateProviderRef<State> ref) {
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
  _HydratedNotifierStateProviderElement<State> createElement() {
    return _HydratedNotifierStateProviderElement(this);
  }
}

class _HydratedNotifierStateProviderElement<State>
    extends ProviderElementBase<StateController<State>>
    implements StateProviderRef<State> {
  _HydratedNotifierStateProviderElement(
      _HydratedNotifierProvider<State> provider)
      : super(provider);

  @override
  StateController<State> get controller => requireState;
}

/// {@template riverpod.stateprovider}
/// A provider that expose a value which can be modified from outside.
///
/// It can be useful for very simple states, like a filter or the currently
/// selected item – which can then be combined with other providers or accessed
/// in multiple screens.
///
/// The following code shows a list of products, and allows selecting
/// a product by tapping on it.
///
/// ```dart
/// final selectedProductIdProvider = StateProvider<String?>((ref) => null);
/// final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>((ref) => ProductsNotifier());
///
/// Widget build(BuildContext context, WidgetRef ref) {
///   final List<Product> products = ref.watch(productsProvider);
///   final selectedProductId = ref.watch(selectedProductIdProvider);
///
///   return ListView(
///     children: [
///       for (final product in products)
///         GestureDetector(
///           onTap: () => ref.read(selectedProductIdProvider.notifier).state = product.id,
///           child: ProductItem(
///             product: product,
///             isSelected: selectedProductId.state == product.id,
///           ),
///         ),
///     ],
///   );
/// }
/// ```
/// {@endtemplate}
StateController<State> _listenStateProvider<State>(
  ProviderElementBase<StateController<State>> ref,
  StateController<State> controller,
) {
  void listener(State newState) {
    ref.setState(controller);
  }

  // No need to remove the listener on dispose, since we are disposing the controller
  controller.addListener(listener, fireImmediately: false);

  return controller;
}

/// Builds a [StateProviderFamily].
class HydratedStateProviderFamilyBuilder extends StateProviderFamilyBuilder {
  /// Builds a [StateProviderFamily].
  const HydratedStateProviderFamilyBuilder() : super();

  /// {@macro riverpod.family}
  @override
  HydratedStateProviderFamily<State, Arg> call<State, Arg>(
    FamilyCreate<State, StateProviderRef<State>, Arg> create, {
    String? name,
    List<ProviderOrFamily>? dependencies,
  }) {
    return HydratedStateProviderFamily(
      create,
      name: name!,
      dependencies: dependencies,
    );
  }

  /// {@macro riverpod.autoDispose}
  HydratedAutoDisposeStateProviderFamilyBuilder get autoDispose {
    return const HydratedAutoDisposeStateProviderFamilyBuilder();
  }
}

// ignore: subtype_of_sealed_class
/// {@macro riverpod.stateprovider.family}
class HydratedStateProviderFamily<State, Arg>
    extends StateProviderFamily<State, Arg> {
  /// {@macro riverpod.stateprovider.family}
  HydratedStateProviderFamily(
    this._create, {
    required String name,
    List<ProviderOrFamily>? dependencies,
  }) : super(_create, name: name, dependencies: dependencies);

  final FamilyCreate<State, StateProviderRef<State>, Arg> _create;

  @override
  HydratedStateProvider<State> create(
    Arg argument,
  ) {
    return HydratedStateProvider<State>(
      (ref) => _create(ref, argument),
      name: name!,
      from: this,
      argument: argument,
    );
  }
}

/// Builds a [AutoDisposeStateProvider].
class HydratedAutoDisposeStateProviderBuilder
    extends AutoDisposeStateProviderBuilder {
  ///
  const HydratedAutoDisposeStateProviderBuilder() : super();

  /// {@macro riverpod.autoDispose}
  @override
  HydratedAutoDisposeStateProvider<State> call<State>(
    Create<State, AutoDisposeStateProviderRef<State>> create, {
    String? name,
    List<ProviderOrFamily>? dependencies,
    Duration? cacheTime,
    Duration? disposeDelay,
  }) {
    return HydratedAutoDisposeStateProvider(
      create,
      name: name,
      dependencies: dependencies,
      cacheTime: cacheTime,
      disposeDelay: disposeDelay,
    );
  }

  /// {@macro riverpod.family}
  @override
  HydratedAutoDisposeStateProviderFamilyBuilder get family {
    return const HydratedAutoDisposeStateProviderFamilyBuilder();
  }
}
