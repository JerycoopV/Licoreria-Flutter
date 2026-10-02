/// Modelo de Producto estructurado para la base de datos y catálogo.
/// NO se incluyen productos ficticios; preparado para la carga posterior de listas oficiales.
class Product {
  final String id;
  final String categoryId;
  final String? subcategoryId;
  final String name;
  final double price;
  final String? description;
  final bool isAvailable;

  const Product({
    required this.id,
    required this.categoryId,
    this.subcategoryId,
    required this.name,
    required this.price,
    this.description,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'name': name,
      'price': price,
      'description': description,
      'is_available': isAvailable ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      subcategoryId: map['subcategory_id'] as String?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      isAvailable: (map['is_available'] as int?) == 1,
    );
  }
}
