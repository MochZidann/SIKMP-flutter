import 'package:flutter/material.dart';

class CategoryHelper {
  CategoryHelper._();

  /// Mendapatkan icon Material yang sesuai berdasarkan nama kategori
  static IconData getIcon(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('minum')) return Icons.local_drink_rounded;
    if (cat.contains('makan')) return Icons.restaurant_rounded;
    if (cat.contains('sembako') || cat.contains('beras') || cat.contains('minyak')) {
      return Icons.kitchen_rounded;
    }
    if (cat.contains('snack') || cat.contains('biskuit') || cat.contains('wafer') || cat.contains('camilan')) {
      return Icons.cookie_rounded;
    }
    if (cat.contains('tulis') || cat.contains('buku') || cat.contains('alat')) {
      return Icons.edit_note_rounded;
    }
    if (cat.contains('sabun') || cat.contains('shampo') || cat.contains('gigi') || cat.contains('perawatan')) {
      return Icons.clean_hands_rounded;
    }
    if (cat.contains('rumah') || cat.contains('plastik') || cat.contains('tisu') || cat.contains('kebutuhan')) {
      return Icons.home_work_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  /// Mendapatkan warna aksen kategori untuk tampilan kartu produk
  static Color getColor(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('minum')) return const Color(0xFF1E88E5);
    if (cat.contains('makan') || cat.contains('snack') || cat.contains('camilan')) return const Color(0xFFFB8C00);
    if (cat.contains('sembako') || cat.contains('beras') || cat.contains('minyak')) return const Color(0xFF43A047);
    if (cat.contains('tulis') || cat.contains('buku') || cat.contains('alat')) return const Color(0xFF8E24AA);
    if (cat.contains('sabun') || cat.contains('shampo') || cat.contains('perawatan')) return const Color(0xFFE91E63);
    if (cat.contains('rumah') || cat.contains('kebutuhan')) return const Color(0xFF3949AB);
    return const Color(0xFFD32F2F);
  }
}
