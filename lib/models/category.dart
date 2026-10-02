import 'package:flutter/material.dart';

/// Modelo de Subcategoría (ej. Botellas, Latas para Cervezas).
class Subcategory {
  final String id;
  final String name;
  final IconData icon;

  const Subcategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// Modelo de Categoría principal para los productos de la licorería.
class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color? accentColor;
  final List<Subcategory> subcategories;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.accentColor,
    this.subcategories = const [],
  });

  bool get hasSubcategories => subcategories.isNotEmpty;
}
