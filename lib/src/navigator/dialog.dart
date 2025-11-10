import 'dart:async';

import 'package:an_dialogs/src/dialog.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

extension NavigatorDialogsExt on NavigatorState {
  /// 显示一个alert
  Future<void> showAlert(
      {Widget? title,
      String? titleLabel,
      Widget? content,
      String? message,
      Widget Function(BuildContext context, void Function() onTap)? okBuilder,
      Widget? ok,
      String? okLabel,
      Cancellable? cancellable}) {
    if (content == null && message == null) {
      throw Exception('content and message cannot be null at the same time');
    }

    if (cancellable?.isUnavailable == true) {
      throw Exception('cancellable must be available');
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

    if (cancellable?.isUnavailable == true) return Completer<void>().future;
    final checkable = cancellable ?? Cancellable();

    Widget dialog = configs.dialogContentBuilder(
      context,
      title,
      content,
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
    final route = configs.alertDialogRouteBuilder(context, dialog);
    configs.dialogDisplayer(this, checkable, route);
    return checkable.whenCancel;
  }

  /// 显示一个confirm
  Future<bool> showConfirm({
    Widget? title,
    String? titleLabel,
    Widget? content,
    String? message,
    Widget Function(BuildContext context, void Function() onTap)? okBuilder,
    Widget? ok,
    String? okLabel,
    Widget Function(BuildContext context, void Function() onTap)? cancelBuilder,
    Widget? cancel,
    String? cancelLabel,
    Cancellable? cancellable,
  }) {
    final checkable = cancellable ?? Cancellable();

    if (content == null && message == null) {
      throw Exception('content and message cannot be null at the same time');
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

    Widget dialog = configs.dialogContentBuilder(
      context,
      title,
      content,
      _actionWidget(
          context: context,
          actionBuilder: okBuilder,
          action: ok,
          label: okLabel,
          labelBuilder: configs.confirmDialogConfirmActionDefaultLabel,
          labelActionBuilder: configs.confirmDialogConfirmLabelActionBuilder,
          onPressed: onOkPressed),
      _actionWidget(
          context: context,
          actionBuilder: cancelBuilder,
          action: cancel,
          label: cancelLabel,
          labelBuilder: configs.confirmDialogCancelActionDefaultLabel,
          labelActionBuilder: configs.confirmDialogCancelLabelActionBuilder,
          onPressed: onCancelPressed),
    );
    dialog = configs.onBackPressedIntercept(dialog);
    final route = configs.confirmDialogRouteBuilder(context, dialog);
    configs.dialogDisplayer(this, checkable, route);
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
