import 'package:flutter/material.dart';
import 'package:fluttertest/core/router/route_guard.dart';
import 'package:fluttertest/core/theme/app_theme.dart';

class GuardedRoute extends StatefulWidget {
  final String route;
  final Widget child;

  const GuardedRoute({super.key, required this.route, required this.child});

  @override
  State<GuardedRoute> createState() => _GuardedRouteState();
}

class _GuardedRouteState extends State<GuardedRoute> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final resolved = await RouteGuard.resolveRedirect(widget.route);
      if (!mounted) return;
      if (resolved != widget.route) {
        Navigator.pushReplacementNamed(context, resolved);
      } else {
        setState(() => _checked = true);
      }
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.sienna, strokeCap: StrokeCap.round)),
      );
    }
    return widget.child;
  }
}
