import 'package:an_dialogs/src/loading.dart';
import 'package:an_dialogs/src/tools.dart';
import 'package:an_dialogs/src/tools/tools.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

WeakHashMap<NavigatorState, CancellableQueue<LoadingMessageBuilder?>>
    _loadings = WeakHashMap();

extension NavigatorLoadingExt on NavigatorState {
  void _show(
      {LoadingMessageBuilder? messageBuilder,
      required Cancellable cancellable}) {
    if (cancellable.isUnavailable) return;

    var loadingQueue = _loadings[this];
    if (loadingQueue == null) {
      final weakThis = WeakReference(this);
      loadingQueue = CancellableQueue();
      loadingQueue.onCancel.then((_) => _loadings.remove(weakThis.target));
      loadingQueue.add(messageBuilder, cancellable);
      _loadings[this] = loadingQueue;
      showDialogLoading(this, loadingQueue);
    } else {
      loadingQueue.add(messageBuilder, cancellable);
    }
  }

  /// 展示 loading
  /// * [cancellable] 控制loading的结束
  void showLoading({String message = '', required Cancellable cancellable}) =>
      _show(
          cancellable: cancellable,
          messageBuilder: loadingMessageBuilder(message));

  /// 自定义 message 一般用来展示动态消息比如 进度
  void showCustomLoading(
          {required LoadingMessageBuilder messageBuilder,
          required Cancellable cancellable}) =>
      _show(cancellable: cancellable, messageBuilder: messageBuilder);
}
