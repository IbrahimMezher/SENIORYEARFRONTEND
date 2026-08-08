import 'dart:async';
import 'package:flutter/material.dart';

class AsyncGuard {
  bool _busy = false;
  bool get isBusy => _busy;

  Future<void> run(
    Future<void> Function() action, {
    void Function(bool busy)? onState,
  }) async {
    if (_busy) return;
    _busy = true;
    onState?.call(true);
    try {
      await action();
    } finally {
      _busy = false;
      onState?.call(false);
    }
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}

mixin AsyncGuardMixin<T extends StatefulWidget> on State<T> {
  bool _guardBusy = false;
  bool get guarded => _guardBusy;

  Future<void> guard(Future<void> Function() action) async {
    if (_guardBusy) return;
    if (mounted) setState(() => _guardBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _guardBusy = false);
    }
  }
}
