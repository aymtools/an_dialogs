import 'package:an_dialogs/src/dialog.dart';
import 'package:an_dialogs/src/loading.dart';
import 'package:an_dialogs/src/tools.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

final _schedulerBinding = SchedulerBinding.instance;

void safeShowDialog(DialogDisplayer dialogDisplayer, NavigatorState navigator,
    Cancellable cancellable, RawDialogRoute<void> dialogRoute) {
  if (cancellable.isUnavailable || !navigator.mounted) return;
  final phase = _schedulerBinding.schedulerPhase;
  if (phase != SchedulerPhase.idle &&
      phase != SchedulerPhase.postFrameCallbacks) {
    _schedulerBinding.addPostFrameCallback(
        (_) => dialogDisplayer(navigator, cancellable, dialogRoute));
    return;
  }
  dialogDisplayer(navigator, cancellable, dialogRoute);
}

void showDialogLoading(
    NavigatorState navigator, CancellableQueue<String> queue) {
  final loading = LoadingConfig.instance;
  // 构建widget
  Widget content = AnimatedBuilder(
    animation: queue,
    builder: (context, child) => loading.loadingDialogContentBuilder(
        context, queue.isAvailable && queue.isNotEmpty ? queue.lastValue : ''),
    child: loading.loadingDialogContentBuilder(
      navigator.context,
      queue.lastValue,
    ),
  );
  // 拦截返回
  content = loading.onBackPressedIntercept(content);
  // 进行展示

  safeShowDialog(
    loading.loadingDialogDisplayer,
    navigator,
    queue.managerCancellable,
    loading.loadingDialogRouteBuilder(
      navigator.context,
      content,
    ),
  );
}

Widget actionWidget(
    {Widget Function(BuildContext, VoidCallback)? actionBuilder,
    Widget? action,
    String? label,
    required String Function(BuildContext) labelBuilder,
    DialogLabelActionBuilder? labelActionBuilder,
    required BuildContext context,
    required VoidCallback onPressed}) {
  if (actionBuilder != null) {
    return actionBuilder(context, onPressed);
  } else if (action != null) {
    return GestureDetector(
      onTap: onPressed,
      child: action,
    );
  } else {
    label ??= labelBuilder(context);
    if (labelActionBuilder != null) {
      return labelActionBuilder(context, label, onPressed);
    }
    return DialogsConfig.instance
        .dialogLabelActionBuilder(context, label, onPressed);
  }
}
