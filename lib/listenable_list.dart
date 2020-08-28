library listenable_list;

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'value_notifier_mixin.dart';

abstract class _ListBase<T> extends ListBase<T> {
  final List<T> _internal;

  _ListBase([final Iterable<T> initial])
      : _internal = initial?.toList(growable: true) ?? List();

  @override
  int get length {
    return _internal.length;
  }

  @override
  set length(final int newLength) {
    _internal.length = newLength;
  }

  @override
  T operator [](final int index) {
    return _internal[index];
  }

  @override
  void operator []=(final int index, final T value) {
    _internal[index] = value;
  }
}

class ListenableList<T> extends _ListBase<T>
    with ValueNotifierMixin<_ListBase<T>> {
  Map<int, T> added = const {};
  Map<int, T> removed = const {};
  Map<int, T /*the value before change*/ > changed = const {};

  @visibleForTesting
  bool lock = false;

  ListenableList() : super();
  ListenableList.from(Iterable<T> other) : super(other);

  static StreamListenableList<T> fromStream<T>(
    final Stream<T> stream, {
    final List<T> initial,
    final Function(ListenableList<T> self, T) listen,
  }) {
    return StreamListenableList(stream, initial: initial, listen: listen);
  }

  @Deprecated('Replace filter with override where')
  ListenableList<T> filter({@required bool Function(T) filter}) {
    return _FilterListenableList(parent: this, retain: filter);
  }

  @override
  _FilterListenableList<T> where(bool Function(T element) test) {
    return _FilterListenableList(parent: this, retain: test);
  }

  _TransformListenableList<X, T> transform<X>(
      {@required final X Function(T) transform}) {
    return _TransformListenableList<X, T>(this, transform);
  }

  @override
  ListenableList<T> toList({bool growable = true}) {
    return ListenableList<T>.from(_internal);
  }

  @override
  notifyListeners() {
    lock = false;
    return super.notifyListeners();
  }

  @override
  String toString() {
    return '${super.toString()} \n    added: $added\n    removed: $removed\n    changed: $changed';
  }

  @override
  void operator []=(final int index, final T value) {
    if (lock) {
      _internal[index] = value;
      return;
    }

    if (value != super[index]) {
      lock = true;
      added = const {};
      removed = const {};
      changed = {index: super[index]};
      _internal[index] = value;
      notifyListeners();
    }
  }

  @override
  void add(T element) {
    if (lock) return super.add(element);
    lock = true;
    super.add(element);
    added = {super.length - 1: element};
    removed = const {};
    changed = const {};
    notifyListeners();
  }

  @override
  void addAll(Iterable<T> iterable) {
    if (lock) return super.addAll(iterable);
    if (iterable.isNotEmpty) {
      lock = true;
      int index = super.length.toInt();
      super.addAll(iterable);
      added = {};
      for (final element in iterable) added[index++] = element;
      removed = const {};
      changed = const {};
      notifyListeners();
    }
  }

  @override
  bool remove(Object element) {
    if (lock) return super.remove(element);

    final index = super.indexOf(element);
    if (index != -1) {
      lock = true;
      added = const {};
      removed = {index: super[index]};
      changed = const {};
      super.remove(element);
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  T removeAt(int index) {
    if (lock) return super.removeAt(index);
    lock = true;
    final res = super.removeAt(index);
    added = const {};
    removed = {index: res};
    changed = const {};
    notifyListeners();
    return res;
  }

  @override
  T removeLast() {
    if (lock) return super.removeLast();
    lock = true;
    final res = super.removeLast();
    added = const {};
    removed = {length: res};
    changed = const {};
    notifyListeners();
    return res;
  }

  @override
  void removeRange(int start, int end) {
    if (lock) return super.removeRange(start, end);
    if (start < end) {
      lock = true;
      added = const {};
      removed = {};
      changed = const {};
      for (int index = start.toInt(); index < end; index++)
        removed[index] = super[index];
      super.removeRange(start, end);
      notifyListeners();
    }
  }

  @override
  void removeWhere(bool Function(T element) test) {
    if (lock) return super.removeWhere(test);
    final removed = <int, T>{};
    for (int index = 0; index < super.length; index++) {
      if (test(super[index])) removed[index] = super[index];
    }
    if (removed.isNotEmpty) {
      lock = true;
      added = const {};
      changed = const {};
      this.removed = removed;
      super.removeWhere(test);
      notifyListeners();
    }
  }

  @override
  void insert(int index, T element) {
    if (lock) return super.insert(index, element);
    lock = true;
    added = {index: element};
    removed = const {};
    changed = const {};
    super.insert(index, element);
    notifyListeners();
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    if (lock) return super.insertAll(index, iterable);
    if (iterable.isNotEmpty) {
      lock = true;
      added = {};
      removed = const {};
      changed = const {};
      int cache = index.toInt();
      for (final element in iterable) added[cache++] = element;
      super.insertAll(index, iterable);
      notifyListeners();
    }
  }

  @override
  void fillRange(int start, int end, [T fill]) {
    if (lock) return super.fillRange(start, end, fill);
    if (start < end) {
      lock = true;
      added = const {};
      removed = const {};
      changed = {};
      for (int index = start.toInt(); index < end; index++)
        changed[index] = super[index];
      super.fillRange(start, end, fill);
      notifyListeners();
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<T> newContents) {
    if (lock) return super.replaceRange(start, end, newContents);
    if (start < end) {
      lock = true;
      added = const {};
      removed = const {};
      changed = {};
      for (int index = start.toInt(); index < end; index++)
        changed[index] = super[index];
      super.replaceRange(start, end, newContents);
      notifyListeners();
    }
  }

  @override
  void retainWhere(bool Function(T element) test) {
    if (lock) return super.retainWhere(test);
    final removed = <int, T>{};
    for (int index = 0; index < super.length; index++) {
      if (!test(super[index])) removed[index] = super[index];
    }
    if (removed.isNotEmpty) {
      lock = true;
      added = const {};
      this.removed = removed;
      changed = const {};
      super.retainWhere(test);
      notifyListeners();
    }
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    if (lock) return super.setRange(start, end, iterable, skipCount);
    final changed = <int, T>{};
    for (int index = start.toInt(); index < end; index = index + 1 + skipCount)
      changed[index] = super[index];

    if (changed.isNotEmpty) {
      lock = true;
      added = const {};
      removed = const {};
      this.changed = changed;
      super.setRange(start, end, iterable, skipCount);
      notifyListeners();
    }
  }

  @override
  void clear() {
    if (lock) return super.clear();
    if (isNotEmpty) {
      lock = true;
      added = const {};
      removed = super.asMap();
      changed = const {};
      super.clear();
      notifyListeners();
    }
  }

  @override
  void setAll(int index, Iterable<T> iterable) {
    if (lock) return super.setAll(index, iterable);
    final changed = <int, T>{};
    for (int i = index.toInt(); i < index + iterable.length; i++)
      changed[i] = super[i];
    if (changed.isNotEmpty) {
      lock = true;
      added = const {};
      removed = const {};
      this.changed = changed;
      super.setAll(index, iterable);
      notifyListeners();
    }
  }

  @override
  void sort([int Function(T a, T b) compare]) {
    if (lock) return super.sort(compare);
    lock = true;
    added = const {};
    removed = const {};
    changed = super.asMap();
    super.sort(compare);
    notifyListeners();
  }

  @override
  ListenableList<T> get value => this;

  @override
  void dispose() {
    super.dispose();
    added = null;
    removed = null;
    changed = null;
  }
}

abstract class AutoListenableList<T> {
  stop();
  resume();
  pause([Future<void> resumeSignal]);
}

class StreamListenableList<T> extends ListenableList<T>
    implements AutoListenableList<T> {
  static void _listen<T>(final ListenableList<T> list, final T element) =>
      list.add(element);

  StreamListenableList(
    this._stream, {
    final List<T> initial,
    this.listen,
  }) : super.from(initial) {
    _streamSubscription = _stream.listen(listen == null
        ? (T event) => _listen<T>(this, event)
        : (T event) => listen(this, event))
      ..onDone(_onDone);
  }

  Stream<T> get lastElements {
    final StreamController<T> controller = StreamController();
    listener() {
      for (final event in added.values) controller.add(event);
    }

    addListener(listener);
    onDone.then((value) async {
      removeListener(listener);
      controller.close();
    });

    return controller.stream;
  }

  @override
  StreamListenableList<T> get value => this;
  final Stream<T> _stream;
  final Function(ListenableList<T>, T) listen;
  StreamSubscription _streamSubscription;
  final Completer<StreamListenableList<T>> _completer = Completer();
  Future<StreamListenableList<T>> get onDone => _completer.future;

  _onDone() {
    if (_completer.isCompleted != true) _completer.complete(this);
  }

  @override
  stop() {
    _onDone();
    _streamSubscription.cancel();
    _streamSubscription = null;
  }

  @override
  pause([Future<void> resumeSignal]) {
    return _streamSubscription.pause(resumeSignal);
  }

  @override
  resume() {
    return _streamSubscription.resume();
  }

  @override
  void dispose() {
    _onDone();
    _streamSubscription?.cancel();
    super.dispose();
  }
}

class _FilterListenableList<T> extends ListenableList<T>
    implements AutoListenableList<T> {
  _FilterListenableList({
    @required this.parent,
    @required this.retain,
  }) : super.from(parent._internal.where(retain)) {
    parent.addListener(_listener);
  }

  final ListenableList<T> parent;
  final bool Function(T) retain;

  _listener() {
    final added = parent.added.values.where(retain);
    assert(() {
      // debug info
      if (parent.removed.isNotEmpty || parent.changed.isNotEmpty)
        print(
            'notion: FilterListenableList\'s parent has removed/changed some element, but self don\'t remove/change element base on parent');
      return true;
    }());
    addAll(added);
  }

  @override
  void dispose() {
    parent.removeListener(_listener);
    super.dispose();
  }

  @override
  _FilterListenableList<T> resume() {
    parent.addListener(_listener);
    return this;
  }

  @override
  _FilterListenableList<T> stop() {
    parent.removeListener(_listener);
    return this;
  }

  @override
  pause([Future<void> resumeSignal]) async {
    parent.removeListener(_listener);
    if (resumeSignal != null) {
      await resumeSignal;
      parent.addListener(_listener);
    }
  }
}

class _TransformListenableList<T, X> extends ListenableList<T>
    implements AutoListenableList<T> {
  final ListenableList<X> parent;
  final T Function(X) convert;
  bool _modifyPermission = false;

  _TransformListenableList(this.parent, this.convert) : super() {
    parent.addListener(_listener);
  }

  _listener() {
    if (parent.added.isNotEmpty ||
        parent.removed.isNotEmpty ||
        parent.changed.isNotEmpty) {
      lock = true;
      added = <int, T>{};
      final addedIndex = parent.added.keys.toList()..sort();
      for (final index in addedIndex)
        insert(index, added[index] = convert(parent.added[index]));

      removed = <int, T>{};
      final removedIndex = parent.removed.keys.toList()..sort((a, b) => b - a);
      for (final index in removedIndex) removed[index] = removeAt(index);

      changed = <int, T>{};
      for (final index in parent.changed.keys)
        changed[index] = (this[index] = convert(parent[index]));

      _modifyPermission = true;
      notifyListeners();
    }
  }

  @mustCallSuper
  @override
  notifyListeners() {
    if (_modifyPermission == false)
      throw AssertionError(
          '_TransformListenableList can\'t modify from outside. ');
    _modifyPermission = false;
    return super.notifyListeners();
  }

  @override
  void dispose() {
    parent.removeListener(_listener);
    super.dispose();
  }

  @override
  _TransformListenableList<T, X> resume() {
    parent.addListener(_listener);
    return this;
  }

  @override
  _TransformListenableList<T, X> stop() {
    parent.removeListener(_listener);
    return this;
  }

  @override
  pause([Future<void> resumeSignal]) async {
    parent.removeListener(_listener);
    if (resumeSignal != null) {
      await resumeSignal;
      parent.addListener(_listener);
    }
  }
}
