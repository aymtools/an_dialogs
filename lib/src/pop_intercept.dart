import 'package:flutter/material.dart';

/// 一个高性能、版本兼容的 PopScope 工具。
///
/// - Flutter 3.22+ 使用 `onPopInvokedWithResult`
/// - Flutter 3.11–3.21 使用 `onPopInvoked`
///
/// ✅ 特点：
/// - 只在首次加载时检测一次 API 支持情况
/// - 后续构建不再使用 `Function.apply`
/// - 性能几乎与原生 PopScope 相同
// ignore: non_constant_identifier_names
Widget PopScopeCompat({
  required Widget child,
  bool canPop = true,
  void Function(bool didPop, Object? result)? onPop,
}) {
  return _PopScopeCompat.instance.build(child, canPop, onPop);
}

class _PopScopeCompat {
  _PopScopeCompat._internal();

  static final _PopScopeCompat instance = _PopScopeCompat._internal();

  static bool? _isNewApiSupported;

  late final Widget Function({
    required Widget child,
    required bool canPop,
    required void Function(bool, Object?)? onPop,
  }) _builder;

  // 构造函数只运行一次
  void _initialize() {
    if (_isNewApiSupported != null) return;

    try {
      // 尝试构造新版 PopScope
      // 如果不支持，会在旧版 Flutter 报错
      // 我们捕获后降级到老 API
      Function.apply(
        PopScope.new,
        const [],
        {
          #canPop: true,
          #onPopInvokedWithResult: (bool _, Object? __) {},
          #child: const SizedBox(),
        },
      );
      _isNewApiSupported = true;
    } catch (_) {
      _isNewApiSupported = false;
    }

    if (_isNewApiSupported == true) {
      // Flutter 3.22+
      _builder = ({
        required Widget child,
        required bool canPop,
        required void Function(bool, Object?)? onPop,
      }) {
        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, result) =>
              onPop?.call(didPop, result),
          child: child,
        );
      };
    } else {
      // Flutter 3.11~3.21
      _builder = ({
        required Widget child,
        required bool canPop,
        required void Function(bool, Object?)? onPop,
      }) {
        return PopScope(
          canPop: canPop,
          // ignore: deprecated_member_use
          onPopInvoked: (didPop) => onPop?.call(didPop, null),
          child: child,
        );
      };
    }
  }

  Widget build(Widget child, bool canPop, void Function(bool, Object?)? onPop) {
    _initialize();
    return _builder(child: child, canPop: canPop, onPop: onPop);
  }
}
