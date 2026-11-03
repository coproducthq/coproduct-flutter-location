import 'package:flutter/widgets.dart';

/// Binds [onResume] to run on every background-to-foreground transition.
/// Returns a disposer that detaches it.
void Function() bindForegroundResume(void Function() onResume) {
  final listener = AppLifecycleListener(onResume: onResume);
  return listener.dispose;
}
