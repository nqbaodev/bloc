import 'package:bloc/base_bloc.dart';
import 'package:bloc/provider.dart';
import 'package:flutter/material.dart';

class BlocProvider<T extends BaseBloc> extends StatelessWidget {
  final Provider<T> _provider;

  BlocProvider({
    super.key,
    required T Function(BuildContext) create,
    void Function(T)? dispose,
    required Widget child,
  }) : _provider = Provider<T>.factory(
          create,
          key: key,
          disposer: dispose,
          child: child,
        );

  static T of<T extends BaseBloc>(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderError catch (e) {
      throw BlocProviderError(e.type);
    }
  }

  @override
  Widget build(BuildContext context) => _provider;
}

class BlocProviderError extends Error {
  final Type? type;

  BlocProviderError(this.type);

  @override
  String toString() {
    if (type == null) {
      return 'Error: please specify type instead of using dynamic when calling BlocProvider.of<T>() or context.bloc<T>() method.';
    }
    return 'Error: No $type found. To fix, please try: * Wrapping your MaterialApp with the BlocProvider<$type>,';
  }
}

extension BlocProviderExtension on BuildContext {
  T bloc<T extends BaseBloc>({bool listen = false}) =>
      BlocProvider.of<T>(this, listen: listen);
}

class MultiBlocProvider extends Providers {
  MultiBlocProvider({
    super.key,
    required List<BlocProvider> providers,
    required super.child,
  })  : assert(providers.isNotEmpty),
        super(
          providers: providers.map((e) => e._provider).toList(growable: false),
        );
}
