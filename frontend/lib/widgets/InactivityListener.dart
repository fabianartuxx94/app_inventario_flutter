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
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();

    // Solicita foco al teclado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    _resetInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
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

  void _handlePointerEvent(PointerEvent event) {
    _resetInactivityTimer();
  }

  void _handleGesture() {
    _resetInactivityTimer();
  }

  void _handleKeyEvent(KeyEvent event) {
    _resetInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerEvent,
      onPointerMove: _handlePointerEvent,
      onPointerUp: _handlePointerEvent,
      onPointerCancel: _handlePointerEvent,
      child: GestureDetector(
  behavior: HitTestBehavior.translucent,
  onTap: _handleGesture,
  onPanUpdate: (_) => _handleGesture(),
  child: KeyboardListener(
    focusNode: _focusNode,
    onKeyEvent: _handleKeyEvent,
    child: widget.child,
  ),
)
    );
  }
}
