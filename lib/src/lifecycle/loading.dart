import 'package:an_dialogs/src/loading.dart';
import 'package:an_dialogs/src/tools.dart';
import 'package:an_dialogs/src/tools/tools.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

final _loadingKey = Object();

extension on Lifecycle {
  void _showLoadingDialog(CancellableQueue<LoadingMessageBuilder?> queue) {
    launchWhenLifecycleStateResumed(
      cancellable: queue.managerCancellable,
      block: (c) async {
        final state = (owner as State);
        late BuildContext context;
        await Future.delayed(Duration.zero);
        if (state.mounted && (context = state.context).mounted) {
          if (c.isAvailable) {
            showDialogLoading(Navigator.of(context), queue);
          } else if (queue.isAvailable) {
            _showLoadingDialog(queue);
          }
        }
      },
    );
  }
}

extension LifecycleLoadingExt on ILifecycle {
  void _show(
      {LoadingMessageBuilder? messageBuilder,
      required Cancellable cancellable}) {
    if (currentLifecycleState < LifecycleState.initialized) return;
    cancellable = makeLiveCancellable(other: cancellable);
    if (cancellable.isUnavailable) return;
    final routeState = findLifecycleOwner<LifecycleRouteOwnerState>();
    assert(routeState != null, 'LifecycleRouteOwnerState not found');

    final extData = routeState!.extData;
    final loadingQueue = extData.getOrPut(
      key: _loadingKey,
      ifAbsent: (l) {
        final queue = CancellableQueue<LoadingMessageBuilder?>();
        l.launchWhenLifecycleEventDestroy(block: (_) => queue.cancelAll());
        queue.onCancel.then(
          (_) => extData.remove<CancellableQueue<LoadingMessageBuilder?>>(
              key: _loadingKey),
        );
        l._showLoadingDialog(queue);
        return queue;
      },
    );
    loadingQueue.add(messageBuilder, cancellable);
  }

  /// 展示 loading
  /// * [cancellable] 控制loading的结束
  void showLoading({String message = '', required Cancellable cancellable}) =>
      _show(
          cancellable: cancellable,
          messageBuilder: loadingMessageBuilder(message));

  /// 自定义 message 一般用来展示动态消息比如 进度
  /// * [cancellable] 控制loading的结束
  void showCustomLoading(
          {required LoadingMessageBuilder messageBuilder,
          required Cancellable cancellable}) =>
      _show(cancellable: cancellable, messageBuilder: messageBuilder);
}

extension FutureLoadingExt<T> on Future<T> {
  /// 当 Future 还未完成时，自动展示 loading
  Future<T> withLoading(
    ILifecycle lifecycle, {
    String message = '',
    Cancellable? cancellable,
  }) {
    if (lifecycle.currentLifecycleState < LifecycleState.initialized) {
      return this;
    }
    cancellable ??= lifecycle.makeLiveCancellable();
    if (cancellable.isUnavailable) {
      return this;
    }
    lifecycle.showLoading(message: message, cancellable: cancellable);
    return whenComplete(() => cancellable?.cancel());
  }
}

extension StreamLoadingExt<T> on Stream<T> {
  /// 当Stream还未发射数据时，自动展示loading
  Stream<T> withLoading(
    ILifecycle lifecycle, {
    String message = '',
    Cancellable? cancellable,
    bool onErrorCallCancel = true,
  }) {
    if (lifecycle.currentLifecycleState < LifecycleState.initialized) {
      return this;
    }
    cancellable ??= lifecycle.makeLiveCancellable();
    if (cancellable.isUnavailable) {
      return this;
    }
    lifecycle.showLoading(message: message, cancellable: cancellable);

    var result = this;
    if (onErrorCallCancel) {
      result = handleError((_) => cancellable?.cancel());
    }
    return result.onData((_) => cancellable?.cancel);
  }
}
