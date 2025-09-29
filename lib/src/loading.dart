import 'package:an_dialogs/src/tools.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

final _loadingKey = Object();

typedef LoadingDialogBuilder = void Function(
  NavigatorState navigator,
  CancellableQueue<String> messageQueue,
);
typedef LoadingDialogContentBuilder = Widget Function(
    BuildContext context, String message);
typedef OnBackPressedInterceptBuilder = Widget Function(
    {required Widget child});

class LoadingConfig {
  LoadingConfig._();

  static final LoadingConfig _instance = LoadingConfig._();

  static LoadingConfig get instance => _instance;

  LoadingDialogBuilder loadingDialogBuilder = defaultLoadingDialogBuilder;
  OnBackPressedInterceptBuilder loadingInterceptOnBackPressed =
      ({required Widget child}) => child;
  LoadingDialogContentBuilder loadingDialogContentBuilder =
      defaultLoadingDialogContentBuilder;
}

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

void defaultLoadingDialogBuilder(
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
      runWithDelayed: true,
      block: (_) {
        final context = (owner as State).context;
        final navigator = Navigator.of(context);
        LoadingConfig.instance.loadingDialogBuilder(navigator, queue);
      },
    );
  }
}

extension LifecycleLoadingExt on ILifecycle {
  void showLoading({String? message, Cancellable? cancellable}) {
    if (currentLifecycleState < LifecycleState.initialized) return;
    cancellable = makeLiveCancellable(other: cancellable);
    if (cancellable.isUnavailable) return;
    message ??= '';
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
  Future<T> withLoading(
    ILifecycle lifecycle, {
    String? message,
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
  Stream<T> withLoading(
    ILifecycle lifecycle, {
    String? message,
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
