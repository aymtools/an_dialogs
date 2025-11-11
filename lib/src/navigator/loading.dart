import 'package:an_dialogs/src/tools.dart';
import 'package:an_dialogs/src/tools/tools.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

WeakHashMap<NavigatorState, CancellableQueue<String>> _loadings = WeakHashMap();

extension NavigatorLoadingExt on NavigatorState {
  /// 展示 loading
  /// * [cancellable] 控制loading的结束
  void showLoading({String message = '', required Cancellable cancellable}) {
    if (cancellable.isUnavailable) return;

    var loadingQueue = _loadings[this];
    if (loadingQueue == null) {
      final weakThis = WeakReference(this);
      loadingQueue = CancellableQueue<String>();
      loadingQueue.onCancel.then((_) => _loadings.remove(weakThis.target));
      loadingQueue.add(message, cancellable);
      _loadings[this] = loadingQueue;
      showDialogLoading(this, loadingQueue);
    } else {
      loadingQueue.add(message, cancellable);
    }
  }
}
