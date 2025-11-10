import 'package:an_dialogs/src/tools.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
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
