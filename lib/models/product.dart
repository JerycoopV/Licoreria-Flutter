/// Modelo de Producto para el catálogo de la licorería.
/// Contiene la información permanente del producto según la estructura oficial.
class Product {
  final dynamic id;
  final String nombre;
  final String categoria;
  final double precio;
  final String? image;
  final String? subcategoryId;
  final String? description;
  final bool isAvailable;

  const Product({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    this.image,
    this.subcategoryId,
    this.description,
    this.isAvailable = true,
  });

  // Getters para mantener compatibilidad total con código existente
  String get name => nombre;
  String get categoryId => categoria;
  double get price => precio;

  Product copyWith({
    dynamic id,
    String? nombre,
    String? categoria,
    double? precio,
    String? image,
    String? subcategoryId,
    String? description,
    bool? isAvailable,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      image: image ?? this.image,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      if (image != null) 'image': image,
      if (subcategoryId != null) 'subcategoria': subcategoryId,
      if (description != null) 'descripcion': description,
      'is_available': isAvailable ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final availableVal = map['is_available'] ?? map['disponible'];
    final isAvail = availableVal is bool
        ? availableVal
        : (availableVal is num ? availableVal == 1 : true);

    return Product(
      id: map['id'],
      nombre: (map['nombre'] ?? map['name'] ?? '').toString(),
      categoria: (map['categoria'] ?? map['category_id'] ?? '').toString(),
      precio: ((map['precio'] ?? map['price'] ?? 0) as num).toDouble(),
      image: map['image'] as String?,
      subcategoryId: (map['subcategoria'] ?? map['subcategory_id']) as String?,
      description: (map['descripcion'] ?? map['description']) as String?,
      isAvailable: isAvail,
    );
  }
}
