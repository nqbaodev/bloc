import 'dart:async';

abstract class BaseBloc<T> {
  BaseBloc(T state) {
    _controller.add(state);
    _state = state;
  }

  final StreamController<T> _controller = StreamController<T>.broadcast();

  Stream<T> get stateStream => _controller.stream;

  late T _state;

  T get state => _state;

  void dispose() {
    _controller.close();
  }

  void emit(T state) {
    if (_controller.isClosed) return;
    _controller.add(state);
    _state = state;
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    if (_controller.isClosed) return;
    _controller.addError(error, stackTrace);
  }
}