import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BuildContext Extensions
/// ─────────────────────────────────────────────────────────────────────────────
extension BuildContextX on BuildContext {
  // ── Theme ─────────────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ── Media ─────────────────────────────────────────────────────────────────────
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;

  // ── Navigation ────────────────────────────────────────────────────────────────
  void hideKeyboard() => FocusScope.of(this).unfocus();

  // ── SnackBar ──────────────────────────────────────────────────────────────────
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
  }

  void showErrorSnackBar(String message) => showSnackBar(
        message,
        duration: const Duration(seconds: 4),
      );
}
