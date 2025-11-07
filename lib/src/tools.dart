import 'dart:collection';

import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

class _CancellableEntity<T> {
  final Cancellable cancellable;
  final T value;

  _CancellableEntity(this.cancellable, this.value);
}

/// 一个包含cancel 管理的队列形式
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

  void _check(dynamic _) {
    _queue.removeWhere((e) => e.cancellable.isUnavailable);
    if (_queue.isEmpty) {
      _manager.cancel();
      return;
    }
    notifyListeners();
  }

  ///
  void cancelAll([Object? reason]) {
    _manager.cancel(reason);
  }

  /// 判断可用性
  bool get isAvailable => _manager.isAvailable;

  /// 判断不可用性
  bool get isUnavailable => _manager.isUnavailable;

  /// 当队列不在可用时， 异步
  Future<CancelledException> get whenCancel => _manager.whenCancel;

  /// 当队列不可用时， 同步
  Future<CancelledException> get onCancel => _manager.onCancel;

  /// 获取管理器
  Cancellable get managerCancellable => _manager;

  /// 判断是否为空
  bool get isEmpty => _queue.isEmpty;

  /// 判断是否不为空
  bool get isNotEmpty => _queue.isNotEmpty;

  /// 当前存放的长度
  int get length => _queue.length;

  /// 最后一个值
  T get lastValue => _queue.last.value;

  /// 第一个值
  T get firstValue => _queue.first.value;
}

typedef OnBackPressedInterceptBuilder = Widget Function(Widget child);

typedef DialogDisplayer = void Function(NavigatorState navigator,
    Cancellable cancellable, RawDialogRoute<void> dialogRoute);

typedef DialogRouteBuilder = RawDialogRoute<void> Function(
    BuildContext context, Widget dialogContent);