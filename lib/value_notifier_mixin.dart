import 'package:flutter/foundation.dart';

mixin ValueNotifierMixin<T> implements ValueListenable<T> {
  final Set<Function()> _listener = Set();

  @override
  void addListener(listener) {
    _listener.add(listener);
  }

  @override
  void removeListener(listener) {
    _listener.remove(listener);
  }

  notifyListeners() {
    for (final listener in _listener) listener();
  }

  @mustCallSuper
  void dispose() {
    _listener.clear();
  }
}
