import 'package:an_dialogs/src/tools.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:flutter/material.dart';

typedef LoadingDialogContentBuilder = Widget Function(
    BuildContext context, String message);

/// loading 配置
class LoadingConfig {
  LoadingConfig._();

  static final LoadingConfig _instance = LoadingConfig._();

  static LoadingConfig get instance => _instance;

  /// 定义如何展示
  DialogDisplayer loadingDialogDisplayer =
      (navigator, cancellable, dialogRoute) =>
          navigator.pushCancellableRoute(dialogRoute, cancellable);

  /// 自己控制如何兼容拦截返回键
  OnBackPressedInterceptBuilder onBackPressedIntercept =
      (Widget child) => child;

  /// 定义 如何构建loading的route
  DialogRouteBuilder loadingDialogRouteBuilder = (context, dialogContent) {
    return DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => dialogContent,
    );
  };

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
//
// /// 默认的loading dialog
// void defaultLoadingDialogDisplayer(
//   NavigatorState navigator,
//   CancellableQueue<String> messageQueue,
// ) {
//   navigator.showDialog(
//     cancellable: messageQueue.managerCancellable,
//     barrierDismissible: false,
//     builder: (context) {
//       return AlertDialog(
//         content: LoadingConfig.instance.loadingOnBackPressedIntercept(
//           AnimatedBuilder(
//             animation: messageQueue,
//             builder: (context, child) {
//               final message =
//                   messageQueue.isAvailable && messageQueue.isNotEmpty
//                       ? messageQueue.lastValue
//                       : '';
//               return LoadingConfig.instance.loadingDialogContentBuilder(
//                 context,
//                 message,
//               );
//             },
//           ),
//         ),
//       );
//     },
//   );
// }
