import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class InactivityListener extends StatefulWidget {
  final Widget child;

  const InactivityListener({super.key, required this.child});

  @override
  State<InactivityListener> createState() => _InactivityListenerState();
}

class _InactivityListenerState extends State<InactivityListener> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _resetInactivityTimer() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.resetInactivityTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerUp: (_) => _resetInactivityTimer(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _resetInactivityTimer,
        child: widget.child,
      ),
    );
  }
}