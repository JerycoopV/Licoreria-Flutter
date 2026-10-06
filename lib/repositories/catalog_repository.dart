import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/category.dart';
import '../models/product.dart';

class CatalogRepository extends ChangeNotifier {
  /// Lista de las 10 categorías oficiales requeridas.
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
      id: 'cigarrillos',
      name: 'Cigarrillos',
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
      final clean = id.toLowerCase().trim();
      return categories.firstWhere((cat) =>
          cat.id.toLowerCase() == clean ||
          cat.name.toLowerCase() == clean ||
          (clean == 'cigarros' && cat.id == 'cigarrillos') ||
          (clean == 'cigarrillos' && cat.id == 'cigarrillos'));
    } catch (_) {
      return null;
    }
  }

  // Singleton y reactividad para acceso global
  static final CatalogRepository _instance = CatalogRepository._internal();
  factory CatalogRepository() => _instance;

  CatalogRepository._internal();

  final List<Product> _products = [];
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Carga los productos desde assets/data/products.json
  Future<List<Product>> loadProducts({bool forceRefresh = false}) async {
    if (_isLoaded && !forceRefresh) {
      return _products;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      _products.clear();
      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          _products.add(Product.fromMap(item));
        }
      }
      _isLoaded = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'No se pudo cargar el catálogo de productos.';
      debugPrint('Error cargando catálogo de productos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _products;
  }

  /// Retorna los productos de una categoría (filtrando por nombre o ID)
  /// y opcionalmente por subcategoría.
  List<Product> getProductsByCategory(String categoryIdentifier,
      {String? subcategoryId}) {
    final clean = categoryIdentifier.toLowerCase().trim();
    return _products.where((p) {
      final pCat = p.categoria.toLowerCase().trim();
      final pCatId = p.categoryId.toLowerCase().trim();
      final matchesCategory = pCat == clean ||
          pCatId == clean ||
          (clean == 'cigarrillos' && (pCat == 'cigarros' || pCatId == 'cigarros')) ||
          (clean == 'cigarros' && (pCat == 'cigarrillos' || pCatId == 'cigarrillos'));
      if (!matchesCategory) return false;

      if (subcategoryId != null && subcategoryId.trim().isNotEmpty) {
        final cleanSub = subcategoryId.toLowerCase().trim();
        final pSub = (p.subcategoryId ?? '').toLowerCase().trim();
        if (pSub.isNotEmpty &&
            !pSub.contains(cleanSub) &&
            !cleanSub.contains(pSub)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Busca productos por nombre en una categoría o globalmente.
  List<Product> searchProducts(String query,
      {String? categoryId, String? subcategoryId}) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) {
      if (categoryId != null) {
        return getProductsByCategory(categoryId, subcategoryId: subcategoryId);
      }
      return _products;
    }

    return _products.where((p) {
      if (categoryId != null) {
        final pCat = p.categoria.toLowerCase().trim();
        final pCatId = p.categoryId.toLowerCase().trim();
        final clean = categoryId.toLowerCase().trim();
        final matches = pCat == clean || pCatId == clean;
        if (!matches) return false;
      }
      if (subcategoryId != null && subcategoryId.isNotEmpty) {
        final cleanSub = subcategoryId.toLowerCase().trim();
        final pSub = (p.subcategoryId ?? '').toLowerCase().trim();
        if (pSub.isNotEmpty &&
            !pSub.contains(cleanSub) &&
            !cleanSub.contains(pSub)) {
          return false;
        }
      }
      return p.nombre.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  /// Obtiene un producto por su identificador.
  Product? getProductById(dynamic id) {
    try {
      final idStr = id.toString();
      return _products.firstWhere((p) => p.id.toString() == idStr);
    } catch (_) {
      return null;
    }
  }
}
