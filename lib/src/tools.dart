import 'dart:collection';

import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

class _CancellableEntity<T> {
  final Cancellable cancellable;
  final T value;

  _CancellableEntity(this.cancellable, this.value);
}

class CancellableQueue<T> with ChangeNotifier {
  final Queue<_CancellableEntity<T>> _queue = ListQueue();

  late final Cancellable _manager = () {
    return Cancellable()
      ..onCancel.then((reason) {
        for (var c in [..._queue]) {
          c.cancellable.cancel(reason);
        }
        _queue.clear();
      });
  }();

  void add(T value, Cancellable cancellable) {
    if (cancellable.isUnavailable) return;
    final entity = _CancellableEntity<T>(cancellable, value);
    _queue.add(entity);
    cancellable.onCancel.then(_check);
    notifyListeners();
  }

  void _check(_) {
    _queue.removeWhere((e) => e.cancellable.isUnavailable);
    if (_queue.isEmpty) {
      _manager.cancel();
      return;
    }
    notifyListeners();
  }

  void cancelAll([Object? reason]) {
    _manager.cancel(reason);
  }

  bool get isAvailable => _manager.isAvailable;

  bool get isUnavailable => _manager.isUnavailable;

  Future<CancelledException> get whenCancel => _manager.whenCancel;

  Future<CancelledException> get onCancel => _manager.onCancel;

  Cancellable get managerCancellable => _manager;

  bool get isEmpty => _queue.isEmpty;

  bool get isNotEmpty => _queue.isNotEmpty;

  int get length => _queue.length;

  T get lastValue => _queue.last.value;

  T get firstValue => _queue.first.value;
}
