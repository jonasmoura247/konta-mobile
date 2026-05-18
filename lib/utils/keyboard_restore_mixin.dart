import 'package:flutter/material.dart';

/// Mixin que restaura o teclado automaticamente ao retornar do background.
///
/// Uso:
/// ```dart
/// class _MyFormState extends State<MyForm>
///     with WidgetsBindingObserver, KeyboardRestoreMixin {
///   late FocusNode _myNode;
///
///   @override
///   void initState() {
///     super.initState();
///     _myNode = FocusNode();
///     registerFocusNode(_myNode);
///   }
/// }
/// ```
mixin KeyboardRestoreMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  FocusNode? _lastFocused;

  void registerFocusNode(FocusNode node) {
    node.addListener(() {
      if (node.hasFocus) _lastFocused = node;
    });
  }

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) _restoreKeyboard();
  }

  void _restoreKeyboard() {
    final node = _lastFocused;
    if (node == null || !mounted) return;
    // 400 ms: tempo suficiente para o Android estabilizar o foco após retorno
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && node.canRequestFocus) node.requestFocus();
    });
  }
}
