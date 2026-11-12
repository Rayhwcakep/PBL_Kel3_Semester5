import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan pilihan mode tampilan aplikasi (gelap / terang) secara persisten.
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'scoutify_theme_mode';
  ThemeMode _mode = ThemeMode.dark;

  ThemeProvider() {
    _loadFromDisk();
  }

  ThemeMode get mode => _mode;

  bool get isDark => _mode != ThemeMode.light;

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_storageKey);
      if (savedMode == 'light') {
        _mode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _mode = ThemeMode.dark;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat preferensi tema: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        _mode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (e) {
      debugPrint('Gagal menyimpan preferensi tema: $e');
    }
  }

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _saveToDisk();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _saveToDisk();
  }
}
