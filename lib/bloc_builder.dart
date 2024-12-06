import 'package:flutter/widgets.dart';
import 'base_bloc.dart';

class BlocBuilder<B extends BaseBloc<T>, T> extends StatelessWidget {
  final B bloc;
  final Widget Function(BuildContext context, T state) builder;
  final Widget? loadingIndicator;

  const BlocBuilder({
    super.key,
    required this.bloc,
    required this.builder,
    this.loadingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: bloc.stateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingIndicator ?? const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
