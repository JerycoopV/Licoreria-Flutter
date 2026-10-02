import 'package:flutter/material.dart';
import '../models/category.dart';

class CatalogRepository {
  /// Lista de categorías oficiales solicitadas.
  /// NO contiene productos inventados.
  static final List<Category> categories = [
    const Category(
      id: 'bebidas',
      name: 'Bebidas',
      icon: Icons.local_drink_rounded,
      accentColor: Color(0xFF06B6D4), // Cyan
    ),
    const Category(
      id: 'galletas',
      name: 'Galletas',
      icon: Icons.cookie_rounded,
      accentColor: Color(0xFFF97316), // Orange
    ),
    const Category(
      id: 'frituras',
      name: 'Frituras',
      icon: Icons.lunch_dining_rounded,
      accentColor: Color(0xFFEAB308), // Yellow
    ),
    const Category(
      id: 'chicles_mentas',
      name: 'Chicles y mentas',
      icon: Icons.spa_rounded,
      accentColor: Color(0xFF10B981), // Emerald
    ),
    const Category(
      id: 'cigarros',
      name: 'Cigarros',
      icon: Icons.smoking_rooms_rounded,
      accentColor: Color(0xFF94A3B8), // Slate
    ),
    const Category(
      id: 'vino',
      name: 'Vino',
      icon: Icons.wine_bar_rounded,
      accentColor: Color(0xFFBE123C), // Rose/Wine
    ),
    const Category(
      id: 'pisco',
      name: 'Pisco',
      icon: Icons.liquor_rounded,
      accentColor: Color(0xFFD97706), // Amber
    ),
    const Category(
      id: 'vodkas',
      name: 'Vodkas',
      icon: Icons.local_bar_rounded,
      accentColor: Color(0xFF38BDF8), // Light Blue
    ),
    const Category(
      id: 'ron',
      name: 'Ron',
      icon: Icons.coffee_rounded,
      accentColor: Color(0xFFB45309), // Warm Brown/Amber
    ),
    const Category(
      id: 'cervezas',
      name: 'Cervezas',
      icon: Icons.sports_bar_rounded,
      accentColor: Color(0xFFF59E0B), // Golden beer
      subcategories: [
        Subcategory(
          id: 'cervezas_botellas',
          name: 'Botellas',
          icon: Icons.wine_bar_outlined,
        ),
        Subcategory(
          id: 'cervezas_latas',
          name: 'Latas',
          icon: Icons.view_agenda_rounded,
        ),
      ],
    ),
  ];

  static Category? getCategoryById(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }
}
