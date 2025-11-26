import 'package:flutter/material.dart';

/// Simple ChangeNotifier that holds the current ThemeMode (light / dark / system)
/// and notifies listeners when it changes.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Updates the current theme mode and notifies all listeners (MaterialApp, etc.)
  void setTheme(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}
