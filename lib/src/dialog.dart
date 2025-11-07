import 'dart:async';

import 'package:an_dialogs/src/tools.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

typedef DialogContentBuilder = Widget Function(BuildContext context,
    Widget? title, Widget content, Widget? confirm, Widget? cancel);
typedef DialogLabelActionBuilder = Widget Function(
    BuildContext context, String label, VoidCallback onPressed);

/// Dialog 配置
class DialogsConfig {
  DialogsConfig._();

  static final DialogsConfig _instance = DialogsConfig._();

  static DialogsConfig get instance => _instance;

  /// 定义如何拦截系统返回键
  OnBackPressedInterceptBuilder onBackPressedIntercept =
      (Widget child) => child;

  /// 定义如何使用路由管理dialog
  DialogDisplayer dialogDisplayer = (navigator, cancellable, dialogRoute) =>
      navigator.pushCancellableRoute(dialogRoute, cancellable);

  /// 定义如何构建dialog的route
  DialogRouteBuilder dialogRouteBuilder = (context, dialogContent) {
    return DialogRoute<void>(
      context: context,
      builder: (BuildContext context) => dialogContent,
    );
  };

  DialogRouteBuilder? _alert, _confirm;

  DialogRouteBuilder get alertDialogRouteBuilder =>
      _alert ?? instance.dialogRouteBuilder;

  /// 单独定义alert的route
  set alertDialogRouteBuilder(DialogRouteBuilder builder) {
    _alert = builder;
  }

  DialogRouteBuilder get confirmDialogRouteBuilder =>
      _confirm ?? instance.dialogRouteBuilder;

  /// 单独定义confirm的route
  set confirmDialogRouteBuilder(DialogRouteBuilder builder) {
    _confirm = builder;
  }

  /// 定义dialog内容如何布局
  DialogContentBuilder dialogContentBuilder =
      (context, title, content, confirm, cancel) {
    return AlertDialog(
      title: title,
      content: content,
      actions: [if (cancel != null) cancel, if (confirm != null) confirm],
    );
  };

  /// 定义dialog 中如何将label转换为按钮
  DialogLabelActionBuilder dialogLabelActionBuilder =
      (context, label, onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  };

  DialogLabelActionBuilder? _alertAction,
      _confirmActionConfirm,
      _confirmActionCancel;

  DialogLabelActionBuilder get alertDialogLabelActionBuilder =>
      _alertAction ?? instance.dialogLabelActionBuilder;

  /// alert 的label action
  set alertDialogLabelActionBuilder(DialogLabelActionBuilder builder) {
    _alertAction = builder;
  }

  DialogLabelActionBuilder get confirmDialogConfirmLabelActionBuilder =>
      _confirmActionConfirm ?? instance.dialogLabelActionBuilder;

  DialogLabelActionBuilder get confirmDialogCancelLabelActionBuilder =>
      _confirmActionCancel ?? instance.dialogLabelActionBuilder;

  /// confirm 的label action
  set confirmDialogConfirmLabelActionBuilder(DialogLabelActionBuilder builder) {
    _confirmActionConfirm = builder;
  }

  /// confirm 的label action
  set confirmDialogCancelLabelActionBuilder(DialogLabelActionBuilder builder) {
    _confirmActionCancel = builder;
  }

  /// confirm 的label action
  void setConfirmDialogLabelActionBuilder(
      DialogLabelActionBuilder confirmBuilder,
      DialogLabelActionBuilder cancelBuilder) {
    _confirmActionConfirm = confirmBuilder;
    _confirmActionCancel = cancelBuilder;
  }

  /// 默认的alert的按钮文字
  String Function(BuildContext context) alertDialogActionDefaultLabel =
      (_) => 'OK';

  /// 默认的confirm的确认按钮文字
  String Function(BuildContext context) confirmDialogConfirmActionDefaultLabel =
      (_) => 'OK';

  /// 默认的confirm的取消按钮文字
  String Function(BuildContext context) confirmDialogCancelActionDefaultLabel =
      (_) => 'Cancel';

  /// dialog 标题的对齐方式
  TextAlign dialogTitleTextAlign = TextAlign.center;

  /// dialog 内容的对齐方式
  TextAlign dialogContentTextAlign = TextAlign.center;
}

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
