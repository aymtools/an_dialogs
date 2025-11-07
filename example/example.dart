import 'package:an_dialogs/an_dialogs.dart';
import 'package:an_dialogs/pop_intercept.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';

void main() {
  initDialogs();
  runApp(const MyApp());
}

void initDialogs() {
  Widget onBackPressedIntercept(Widget child) => PopScopeCompat(
        canPop: false,
        onPop: (didPop, result) {
          if (didPop) return;
        },
        child: child,
      );

  /// 配置拦截返回键 默认不拦截可取消
  LoadingConfig.instance.onBackPressedIntercept = onBackPressedIntercept;
  DialogsConfig.instance.onBackPressedIntercept = onBackPressedIntercept;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        navigatorObservers: [LifecycleNavigatorObserver.hookMode()],
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lifecycle = context.lifecycle;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextButton(
              onPressed: () {
                lifecycle.showAlert(
                    titleLabel: 'Title', message: 'Alert message');
              },
              child: Text('showAlert'),
            ),
            TextButton(
              onPressed: () async {
                final select = await lifecycle.showConfirm(
                    titleLabel: 'Confirm', message: 'Confirm message');
                print('select:$select');
              },
              child: Text('showConfirm'),
            ),
            TextButton(
              onPressed: () async {
                final loading = lifecycle.makeLiveCancellable();
                lifecycle.showLoading(cancellable: loading);
                try {
                  await _loading1Future();
                } finally {
                  loading.cancel();
                }
              },
              child: Text('showLoading 3s'),
            ),
            TextButton(
              onPressed: () {
                final loading1 = lifecycle.makeLiveCancellable();
                final loading2 = lifecycle.makeLiveCancellable();

                lifecycle.showLoading(cancellable: loading1);
                lifecycle.showLoading(cancellable: loading2);

                _loading1Future().whenComplete(() => loading1.cancel());
                _loading2Future().whenComplete(() => loading2.cancel());
              },
              child: Text('showLoading 3s & 5s '),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _loading1Future() async {
  await Future.delayed(const Duration(seconds: 3));
}

Future<void> _loading2Future() async {
  await Future.delayed(const Duration(seconds: 5));
}

extension on BuildContext {
  Lifecycle get lifecycle => Lifecycle.of(this);
}
