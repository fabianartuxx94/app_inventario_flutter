// widgets/inactivity_listener.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class InactivityListener extends StatefulWidget {
  final Widget child;
  
  const InactivityListener({super.key, required this.child});
  
  @override
  State<InactivityListener> createState() => _InactivityListenerState();
}

class _InactivityListenerState extends State<InactivityListener> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
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
  
  // Detectar cuando la app vuelve a ser activa
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }
  
  // Listener para eventos táctiles (con parámetro PointerEvent)
  void _handlePointerEvent(PointerEvent event) {
    _resetInactivityTimer();
  }
  
  // Handler para GestureDetector (sin parámetros)
  void _handleGesture() {
    _resetInactivityTimer();
  }
  
  // Handler para KeyboardListener
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
        onTap: _handleGesture, // Sin parámetros
        onPanUpdate: (_) => _resetInactivityTimer(),
        onScaleUpdate: (_) => _resetInactivityTimer(),
        behavior: HitTestBehavior.translucent,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: _handleKeyEvent,
          child: widget.child,
        ),
      ),
    );
  }
}