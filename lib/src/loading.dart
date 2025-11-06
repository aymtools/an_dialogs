import 'package:an_dialogs/src/tools.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

final _loadingKey = Object();

typedef LoadingDialogDisplayer = void Function(
  NavigatorState navigator,
  CancellableQueue<String> messageQueue,
);
typedef LoadingDialogContentBuilder = Widget Function(
    BuildContext context, String message);

/// loading 配置
class LoadingConfig {
  LoadingConfig._();

  static final LoadingConfig _instance = LoadingConfig._();

  static LoadingConfig get instance => _instance;

  /// 定义如何展示
  LoadingDialogDisplayer loadingDialogDisplayer = defaultLoadingDialogDisplayer;

  /// 自己控制如何兼容拦截返回键
  OnBackPressedInterceptBuilder loadingInterceptOnBackPressed =
      ({required Widget child}) => child;

  /// 定义如何构建loading的布局
  LoadingDialogContentBuilder loadingDialogContentBuilder =
      defaultLoadingDialogContentBuilder;
}

/// 默认的loading dialog content
Widget defaultLoadingDialogContentBuilder(
  BuildContext context,
  String message,
) {
  if (message.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text(message),
    ],
  );
}

/// 默认的loading dialog
void defaultLoadingDialogDisplayer(
  NavigatorState navigator,
  CancellableQueue<String> messageQueue,
) {
  navigator.showDialog(
    cancellable: messageQueue.managerCancellable,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        content: LoadingConfig.instance.loadingInterceptOnBackPressed(
          child: AnimatedBuilder(
            animation: messageQueue,
            builder: (context, child) {
              final message =
                  messageQueue.isAvailable && messageQueue.isNotEmpty
                      ? messageQueue.lastValue
                      : '';
              return LoadingConfig.instance.loadingDialogContentBuilder(
                context,
                message,
              );
            },
          ),
        ),
      );
    },
  );
}

extension on Lifecycle {
  void _showLoadingDialog(CancellableQueue<String> queue) {
    launchWhenLifecycleStateResumed(
      cancellable: queue.managerCancellable,
      block: (c) async {
        final state = (owner as State);
        late BuildContext context;
        await Future.delayed(Duration.zero);
        if (state.mounted && (context = state.context).mounted) {
          if (c.isAvailable) {
            LoadingConfig.instance
                .loadingDialogDisplayer(Navigator.of(context), queue);
          } else if (queue.isAvailable) {
            _showLoadingDialog(queue);
          }
        }
      },
    );
  }
}

extension LifecycleLoadingExt on ILifecycle {
  /// 展示 loading
  /// * [cancellable] 控制loading的结束
  void showLoading({String message = '', required Cancellable cancellable}) {
    if (currentLifecycleState < LifecycleState.initialized) return;
    cancellable = makeLiveCancellable(other: cancellable);
    if (cancellable.isUnavailable) return;
    final routeState = findLifecycleOwner<LifecycleRouteOwnerState>();
    assert(routeState != null, 'LifecycleRouteOwnerState not found');

    final extData = routeState!.extData;
    final loadingQueue = extData.getOrPut(
      key: _loadingKey,
      ifAbsent: (l) {
        final queue = CancellableQueue<String>();
        l.launchWhenLifecycleEventDestroy(block: (_) => queue.cancelAll());
        queue.onCancel.then(
          (_) => extData.remove<CancellableQueue<String>>(key: _loadingKey),
        );
        l._showLoadingDialog(queue);
        return queue;
      },
    );
    loadingQueue.add(message, cancellable);
  }
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
