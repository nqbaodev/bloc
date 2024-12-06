import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract class Provider<T> extends StatefulWidget {
  const Provider._({super.key});

  factory Provider.factory(
    T Function(BuildContext) factory, {
    Key? key,
    void Function(T)? disposer,
    required Widget child,
  }) =>
      _FactoryProvider<T>(
        key: key,
        factory: factory,
        disposer: disposer,
        child: child,
      );

  factory Provider.value(
    T value, {
    Key? key,
    void Function(T)? disposer,
    bool Function(T previous, T current)? updateShouldNotify,
    Widget? child,
  }) =>
      _ValueProvider<T>(
        value: value,
        disposer: disposer,
        updateShouldNotify: updateShouldNotify ?? _notEquals,
        key: key,
        child: child,
      );

  static T of<T>(BuildContext context, {bool listen = false}) {
    if (T == dynamic) {
      throw ProviderError();
    }

    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<_ProviderScope<T>>()
        : (context
        .getElementForInheritedWidgetOfExactType<_ProviderScope<T>>()
        ?.widget as _ProviderScope<T>?);

    if (scope == null) {
      throw ProviderError(T);
    }

    return scope.requireValue;
  }

  @factory
  Provider<T> _copyWithChild(Widget child);

}

bool _notEquals<T>(T previous, T current) => previous != current;

extension ProviderBuildContextExtension on BuildContext {
  T get<T>({bool listen = false}) => Provider.of<T>(this, listen: listen);
}

class _FactoryProvider<T> extends Provider<T> {
  final T Function(BuildContext) factory;
  final void Function(T)? disposer;
  final Widget child;

  const _FactoryProvider({
    super.key,
    required this.factory,
    this.disposer,
    required this.child,
  }) : super._();

  @override
  _FactoryProviderState<T> createState() => _FactoryProviderState<T>();

  @override
  Provider<T> _copyWithChild(Widget child) {
    return Provider.factory(
      factory,
      key: key,
      disposer: disposer,
      child: child,
    );
  }
}

class _FactoryProviderState<T> extends State<_FactoryProvider<T>> {
  T? value;

  @override
  void initState() {
    super.initState();
    value = widget.factory(context);
  }

  @override
  void didUpdateWidget(covariant _FactoryProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.factory != widget.factory) {
      value = widget.factory(context);
      if (value != null) {
        widget.disposer?.call(value as T);
      }
    }
  }

  @override
  void dispose() {
    if (value != null ) {
      widget.disposer?.call(value as T);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ProviderScope<T>(
      value: value,
      getNullableValue: () {
        return value;
      },
      child: widget.child,
    );
  }
}


class _ValueProvider<T> extends Provider<T> {
  final T value;
  final void Function(T)? disposer;
  final bool Function(T, T) updateShouldNotify;
  final Widget? child;

  const _ValueProvider({
    super.key,
    required this.value,
    required this.disposer,
    required this.updateShouldNotify,
    this.child,
  }) : super._();

  @override
  _ValueProviderState<T> createState() => _ValueProviderState<T>();

  @override
  Provider<T> _copyWithChild(Widget child) {
    return Provider<T>.value(
      value,
      key: key,
      updateShouldNotify: updateShouldNotify,
      disposer: disposer,
      child: child,
    );
  }
}

class _ValueProviderState<T> extends State<_ValueProvider<T>> {
  @override
  void didUpdateWidget(covariant _ValueProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      oldWidget.disposer?.call(oldWidget.value);
    }
  }

  @override
  void dispose() {
    widget.disposer?.call(widget.value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final val = widget.value;
    assert(widget.child != null);

    return _ProviderScope<T>(
      value: val,
      getNullableValue: () => val,
      updateShouldNotifyDelegate: widget.updateShouldNotify,
      child: widget.child!,
    );
  }
}

class _ProviderScope<T> extends InheritedWidget {
  final T Function()? getValue;
  final T? value;
  final bool Function(T, T)? updateShouldNotifyDelegate;

  final T? Function() getNullableValue;

  T get requireValue => value ?? getValue!();

  _ProviderScope({
    super.key,
    this.getValue,
    this.value,
    this.updateShouldNotifyDelegate,
    required super.child,
    required this.getNullableValue,
  })  : assert(() {
    if (getValue == null && value == null) {
      return false;
    }
    if (getValue != null && value != null) {
      return false;
    }

    return true;
  }());

  @override
  bool updateShouldNotify(_ProviderScope<T> oldWidget) {
    if (oldWidget.value != null && value != null && updateShouldNotifyDelegate != null) {
      return updateShouldNotifyDelegate!(oldWidget.value as T, value as T);
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(
      DiagnosticsProperty<T>(
        'value',
        getNullableValue(),
        ifNull: '<not yet created>',
      ),
    );
    properties.add(DiagnosticsProperty<Type>('type', T));
  }
}

class ProviderError extends Error {
  final Type? type;

  ProviderError([this.type]);

  @override
  String toString() {
    if (type == null) {
      return '''Error: please specify type instead of using dynamic when calling Provider.of<T>() or context.get<T>() method.''';
    }

    return '''Error: No Provider<$type> found. To fix, please try:
  * Wrapping your MaterialApp with the Provider<$type>.
  * Providing full type information to Provider<$type>, Provider.of<$type> and context.get<$type>() method.
      ''';
  }
}

class Providers extends StatelessWidget {
  final Widget _child;

  Providers({
    super.key,
    required List<Provider<dynamic>> providers,
    required Widget child,
  })  : assert(providers.isNotEmpty),
        _child = providers.reversed.fold(child, (acc, e) => e._copyWithChild(acc));

  @override
  Widget build(BuildContext context) => _child;
}