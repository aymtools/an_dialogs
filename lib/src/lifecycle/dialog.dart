import 'dart:async';

import 'package:an_dialogs/src/dialog.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

extension LifecycleDialogsExt on ILifecycle {
  /// 显示对话框
  /// 但是不通过 push 和 pop 来管理对话框的生命周期
  /// 由于会多次尝试加入移除 所以不能用pop来传递返回消息
  void showDialog({
    Cancellable? cancellable,
    LifecycleState runAtLeastState = LifecycleState.started,
    required RawDialogRoute<void> Function(BuildContext) dialogRouteBuilder,
  }) {
    assert(runAtLeastState >= LifecycleState.created,
        'runAtLeastState must be greater than LifecycleState.created');
    if (runAtLeastState < LifecycleState.created) return;
    if (currentLifecycleState == LifecycleState.destroyed) return;
    final checkable = cancellable ?? makeLiveCancellable();
    if (checkable.isUnavailable) return;

    final routeState = findLifecycleOwner<LifecycleRouteOwnerState>();
    assert(routeState != null, 'LifecycleRouteOwnerState not found');
    if (routeState == null) return;

    launchWhenLifecycleStateAtLeast(
      targetState: runAtLeastState,
      cancellable: checkable,
      block: (c) async {
        late BuildContext context;
        await Future.delayed(Duration.zero);
        if (routeState.mounted && (context = routeState.context).mounted) {
          /// 如果发现状态已经错过了 则等待下一次的生命周期状态变化再显示
          if (c.isAvailable) {
            final nav = Navigator.of(context);
            DialogsConfig.instance
                .dialogDisplayer(nav, checkable, dialogRouteBuilder(context));
          } else if (checkable.isAvailable) {
            showDialog(
                cancellable: checkable,
                runAtLeastState: runAtLeastState,
                dialogRouteBuilder: dialogRouteBuilder);
          }
        }
      },
    );
  }

  /// 显示一个alert
  Future<void> showAlert(
      {Widget? title,
      String? titleLabel,
      Widget? content,
      String? message,
      Widget Function(BuildContext context, void Function() onTap)? okBuilder,
      Widget? ok,
      String? okLabel,
      Cancellable? cancellable,
      LifecycleState runAtLeastState = LifecycleState.started}) {
    final checkable = makeLiveCancellable(other: cancellable);

    if (content == null && message == null) {
      throw Exception('content and message cannot be null at the same time');
    }

    if (runAtLeastState < LifecycleState.created) {
      throw Exception(
          'runAtLeastState must be greater than LifecycleState.created');
    }

    final configs = DialogsConfig.instance;

    content ??= Text(
      message!,
      textAlign: configs.dialogContentTextAlign,
    );
    if (title == null && titleLabel != null) {
      title = Text(
        titleLabel,
        textAlign: configs.dialogTitleTextAlign,
      );
    }

    if (checkable.isUnavailable) return Completer<void>().future;

    showDialog(
        cancellable: checkable,
        runAtLeastState: runAtLeastState,
        dialogRouteBuilder: (context) {
          Widget dialog = configs.dialogContentBuilder(
            context,
            title,
            content!,
            _actionWidget(
              context: context,
              actionBuilder: okBuilder,
              action: ok,
              label: okLabel,
              labelBuilder: configs.alertDialogActionDefaultLabel,
              labelActionBuilder: configs.alertDialogLabelActionBuilder,
              onPressed: checkable.cancel,
            ),
            null,
          );
          dialog = configs.onBackPressedIntercept(dialog);
          return configs.alertDialogRouteBuilder(context, dialog);
        });
    return checkable.whenCancel;
  }

  /// 显示一个confirm
  Future<bool> showConfirm(
      {Widget? title,
      String? titleLabel,
      Widget? content,
      String? message,
      Widget Function(BuildContext context, void Function() onTap)? okBuilder,
      Widget? ok,
      String? okLabel,
      Widget Function(BuildContext context, void Function() onTap)?
          cancelBuilder,
      Widget? cancel,
      String? cancelLabel,
      Cancellable? cancellable,
      LifecycleState runAtLeastState = LifecycleState.resumed}) {
    final checkable = makeLiveCancellable(other: cancellable);

    if (content == null && message == null) {
      throw Exception('content and message cannot be null at the same time');
    }
    if (runAtLeastState < LifecycleState.created) {
      throw Exception(
          'runAtLeastState must be greater than LifecycleState.created');
    }

    final configs = DialogsConfig.instance;

    if (title == null && titleLabel != null) {
      title = Text(
        titleLabel,
        textAlign: configs.dialogTitleTextAlign,
      );
    }

    content ??= Text(message!, textAlign: configs.dialogContentTextAlign);

    if (checkable.isUnavailable) return Completer<bool>().future;

    bool result = false;

    void onOkPressed() {
      result = true;
      checkable.cancel();
    }

    void onCancelPressed() {
      result = false;
      checkable.cancel();
    }

    showDialog(
        cancellable: checkable,
        runAtLeastState: runAtLeastState,
        dialogRouteBuilder: (context) {
          Widget dialog = configs.dialogContentBuilder(
            context,
            title,
            content!,
            _actionWidget(
                context: context,
                actionBuilder: okBuilder,
                action: ok,
                label: okLabel,
                labelBuilder: configs.confirmDialogConfirmActionDefaultLabel,
                labelActionBuilder:
                    configs.confirmDialogConfirmLabelActionBuilder,
                onPressed: onOkPressed),
            _actionWidget(
                context: context,
                actionBuilder: cancelBuilder,
                action: cancel,
                label: cancelLabel,
                labelBuilder: configs.confirmDialogCancelActionDefaultLabel,
                labelActionBuilder:
                    configs.confirmDialogCancelLabelActionBuilder,
                onPressed: onCancelPressed),
          );
          dialog = configs.onBackPressedIntercept(dialog);
          return configs.confirmDialogRouteBuilder(context, dialog);
        });
    return checkable.whenCancel.then((_) => result);
  }
}

Widget _actionWidget(
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
