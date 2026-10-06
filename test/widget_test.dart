import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:licoreria_pos/main.dart';
import 'package:licoreria_pos/models/product.dart';
import 'package:licoreria_pos/models/sale.dart';
import 'package:licoreria_pos/presentation/categories/category_detail_screen.dart';
import 'package:licoreria_pos/repositories/catalog_repository.dart';
import 'package:licoreria_pos/repositories/sales_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await CatalogRepository().loadProducts();
  });

  setUp(() async {
    // Asegurar almacenamiento mock limpio para cada prueba
    SharedPreferences.setMockInitialValues({});
    await SalesRepository().clearAll();
  });

  testWidgets('1. Carga inicial de Home: Título, botón "+" y estado vacío', (WidgetTester tester) async {
    await tester.pumpWidget(const LicoreriaApp());
    await tester.pumpAndSettle();

    // Título principal
    expect(find.text('LICORERÍA POS'), findsOneWidget);

    // Botón grande de nueva venta
    expect(find.text('NUEVA VENTA'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Métricas iniciales en 0
    expect(find.text('S/. 0.00'), findsAtLeastNWidgets(1));
    expect(find.text('0 ventas'), findsOneWidget);

    // Mensaje de estado vacío
    expect(find.text('No hay registros anteriores'), findsOneWidget);
  });

  testWidgets('2. Navegación al pulsar "+": Abre menú con las 10 categorías requeridas', (WidgetTester tester) async {
    await tester.pumpWidget(const LicoreriaApp());
    await tester.pumpAndSettle();

    // Tocar el botón "+" de nueva venta
    await tester.tap(find.text('NUEVA VENTA'));
    await tester.pumpAndSettle();

    // Verificar que estamos en el menú de categorías
    expect(find.text('Menú de Categorías'), findsOneWidget);
    expect(find.text('Selecciona una Categoría'), findsOneWidget);

    // Verificar que las 10 categorías están presentes en el catálogo
    final expectedCategories = [
      'Bebidas',
      'Galletas',
      'Frituras',
      'Chicles y mentas',
      'Cigarrillos',
      'Vino',
      'Pisco',
      'Vodkas',
      'Ron',
      'Cervezas',
    ];

    for (final catName in expectedCategories) {
      expect(CatalogRepository.categories.any((c) => c.name == catName), isTrue,
          reason: 'Debe contener la categoría $catName');
    }
  });

  testWidgets('3. Navegación en "Cervezas": Muestra subcategorías "Botellas" y "Latas"', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LicoreriaApp());
    await tester.pumpAndSettle();

    // Ir a menú de categorías
    await tester.tap(find.text('NUEVA VENTA'));
    await tester.pumpAndSettle();

    // Tocar la categoría "Cervezas"
    final cervezasTile = find.text('Cervezas');
    expect(cervezasTile, findsOneWidget);
    await tester.tap(cervezasTile);
    await tester.pumpAndSettle();

    // Verificar que estamos en la pantalla de subcategorías con "Botellas" y "Latas"
    expect(find.text('Botellas'), findsOneWidget);
    expect(find.text('Latas'), findsOneWidget);
    expect(find.text('PRESENTACIONES DISPONIBLES'), findsOneWidget);
  });

  testWidgets('4. Registro reactivo de venta: Actualiza historial y cálculo de totales', (WidgetTester tester) async {
    await tester.pumpWidget(const LicoreriaApp());
    await tester.pumpAndSettle();

    // Inicialmente 0 ventas
    expect(find.text('0 ventas'), findsOneWidget);

    // Registrar una venta en Efectivo de S/. 50.00
    SalesRepository().recordSale(
      Sale(
        id: 'test_sale_1',
        createdAt: DateTime.now(),
        totalAmount: 50.00,
        cashAmount: 50.00,
        yapeAmount: 0.0,
        paymentMethod: PaymentMethod.efectivo,
        note: 'Prueba Efectivo',
      ),
    );
    await tester.pumpAndSettle();

    // Verificar que se actualizó el contador y los totales
    expect(find.text('1 ventas'), findsOneWidget);
    expect(find.text('S/. 50.00'), findsAtLeastNWidgets(1));
    expect(find.text('Prueba Efectivo'), findsOneWidget);

    // Registrar una venta en Yape de S/. 35.50
    SalesRepository().recordSale(
      Sale(
        id: 'test_sale_2',
        createdAt: DateTime.now(),
        totalAmount: 35.50,
        cashAmount: 0.0,
        yapeAmount: 35.50,
        paymentMethod: PaymentMethod.yape,
        note: 'Prueba Yape',
      ),
    );
    await tester.pumpAndSettle();

    // Gran total = 50 + 35.50 = S/. 85.50
    expect(find.text('2 ventas'), findsOneWidget);
    expect(find.text('S/. 85.50'), findsOneWidget);
    expect(find.text('Prueba Yape'), findsOneWidget);
  });

  test('5. Modelo Product: Constructor, toMap y fromMap según estructura oficial', () {
    const product = Product(
      id: 1,
      nombre: 'Inca Kola 500ml',
      categoria: 'Bebidas',
      precio: 3.50,
      description: 'Gaseosa personal',
      image: 'assets/images/products/inca_kola_500ml.png',
      isAvailable: true,
    );

    expect(product.id, 1);
    expect(product.nombre, 'Inca Kola 500ml');
    expect(product.categoria, 'Bebidas');
    expect(product.precio, 3.50);
    expect(product.image, 'assets/images/products/inca_kola_500ml.png');

    final map = product.toMap();
    expect(map['id'], 1);
    expect(map['nombre'], 'Inca Kola 500ml');
    expect(map['categoria'], 'Bebidas');
    expect(map['precio'], 3.50);
    expect(map['image'], 'assets/images/products/inca_kola_500ml.png');

    final fromMapProduct = Product.fromMap(map);
    expect(fromMapProduct.id, 1);
    expect(fromMapProduct.nombre, 'Inca Kola 500ml');
    expect(fromMapProduct.categoria, 'Bebidas');
    expect(fromMapProduct.precio, 3.50);
    expect(fromMapProduct.image, 'assets/images/products/inca_kola_500ml.png');
    expect(fromMapProduct.isAvailable, isTrue);

    final copied = product.copyWith(precio: 4.00, image: null);
    expect(copied.precio, 4.00);
    expect(copied.nombre, 'Inca Kola 500ml');
  });

  test('6. Modelo Sale: Representación JSON con id, nombre, categoria, cantidad, precio, metodo_pago', () {
    final sale = Sale(
      id: 25,
      nombre: 'Coca Cola 500ml',
      categoria: 'Bebidas',
      cantidad: 3,
      precio: 3.50, // PRECIO UNITARIO
      metodoPago: 'Yape',
    );

    expect(sale.id, 25);
    expect(sale.nombre, 'Coca Cola 500ml');
    expect(sale.categoria, 'Bebidas');
    expect(sale.cantidad, 3);
    expect(sale.precio, 3.50);
    expect(sale.metodoPago, 'Yape');
    expect(sale.total, 10.50); // cantidad × precio

    final jsonMap = sale.toMap();
    expect(jsonMap['id'], 25);
    expect(jsonMap['nombre'], 'Coca Cola 500ml');
    expect(jsonMap['categoria'], 'Bebidas');
    expect(jsonMap['cantidad'], 3);
    expect(jsonMap['precio'], 3.50);
    expect(jsonMap['metodo_pago'], 'Yape');

    final fromJsonSale = Sale.fromMap(jsonMap);
    expect(fromJsonSale.id, 25);
    expect(fromJsonSale.nombre, 'Coca Cola 500ml');
    expect(fromJsonSale.categoria, 'Bebidas');
    expect(fromJsonSale.cantidad, 3);
    expect(fromJsonSale.precio, 3.50);
    expect(fromJsonSale.metodoPago, 'Yape');
    expect(fromJsonSale.total, 10.50);
  });

  testWidgets('7. CategoryDetailScreen: Flujo completo producto -> cantidad -> método de pago -> registrar venta', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Cargar catálogo de prueba
    await CatalogRepository().loadProducts();

    final vinoCategory = CatalogRepository.getCategoryById('vino')!;

    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDetailScreen(category: vinoCategory),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificar categoría
    expect(find.text('Vino'), findsAtLeastNWidgets(1));

    // 2. Verificar producto y precio en soles
    expect(find.textContaining('Santiago Queirolo Borgoña'), findsOneWidget);
    expect(find.textContaining('S/. 24.00'), findsOneWidget);

    // 3. Tocar el producto para abrir el modal
    await tester.tap(find.textContaining('Santiago Queirolo Borgoña'));
    await tester.pumpAndSettle();

    // 4. Modal abierto con elementos requeridos
    expect(find.text('Registrar Venta'), findsOneWidget);
    expect(find.text('CANTIDAD'), findsOneWidget);
    expect(find.text('TOTAL A COBRAR'), findsOneWidget);
    expect(find.text('MÉTODO DE PAGO'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('Yape'), findsOneWidget);

    // 5. Incrementar cantidad a 3
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();

    // Total para 3 botellas = 24.00 * 3 = S/. 72.00
    expect(find.text('S/. 72.00'), findsAtLeastNWidgets(1));

    // 6. Seleccionar método de pago Yape
    await tester.tap(find.text('Yape'));
    await tester.pumpAndSettle();

    // 7. Presionar el botón "Registrar venta"
    final registrarBtn = find.textContaining('Registrar venta');
    expect(registrarBtn, findsOneWidget);
    await tester.tap(registrarBtn);
    await tester.pumpAndSettle();

    // 8. Verificar que la venta fue registrada localmente
    expect(SalesRepository().sales.length, 1);
    final recordedSale = SalesRepository().sales.first;
    expect(recordedSale.nombre, contains('Santiago Queirolo Borgoña'));
    expect(recordedSale.categoria, 'Vino');
    expect(recordedSale.cantidad, 3);
    expect(recordedSale.precio, 24.00);
    expect(recordedSale.total, 72.00);
    expect(recordedSale.metodoPago, 'Yape');
  });

  testWidgets('8. Categoría Bebidas: Muestra exactamente los 14 productos con sus nombres, precios y fallback visual', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CatalogRepository().loadProducts();
    final bebidasCategory = CatalogRepository.getCategoryById('bebidas')!;
    final bebidasProducts = CatalogRepository().getProductsByCategory('bebidas');

    // 1. Verificar conteo exacto de 14 productos
    expect(bebidasProducts.length, 14);

    final expectedProducts = [
      {'nombre': 'Inka Cola personal 500ml', 'precio': 3.00},
      {'nombre': 'Coca Cola personal 500ml', 'precio': 3.00},
      {'nombre': 'Cielo 625 ml', 'precio': 1.50},
      {'nombre': 'Cielo chupon 1L', 'precio': 2.50},
      {'nombre': 'San Mateo 625ml', 'precio': 2.00},
      {'nombre': 'Fanta 625 ml', 'precio': 2.50},
      {'nombre': 'Sprite 625 ml', 'precio': 2.50},
      {'nombre': 'Coca Cola 1L', 'precio': 4.50},
      {'nombre': 'Inka Cola 1L', 'precio': 4.50},
      {'nombre': 'Coca Cola 1.5L', 'precio': 6.50},
      {'nombre': 'Inka Cola 1.5L', 'precio': 6.50},
      {'nombre': 'Inka Cola 3L', 'precio': 13.00},
      {'nombre': 'Coca Cola 3L', 'precio': 13.00},
      {'nombre': 'Pepsi 2L', 'precio': 5.50},
    ];

    // 2. Verificar datos exactos en el catálogo: nombres, precios numéricos y image == null
    for (int i = 0; i < expectedProducts.length; i++) {
      final p = bebidasProducts[i];
      final exp = expectedProducts[i];
      expect(p.id, i + 1);
      expect(p.nombre, exp['nombre']);
      expect(p.precio, exp['precio']);
      expect(p.image, isNull);
      expect(p.categoria, 'Bebidas');
    }

    // 3. Renderizar CategoryDetailScreen para Bebidas
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDetailScreen(category: bebidasCategory),
      ),
    );
    await tester.pumpAndSettle();

    // 4. Verificar cabecera y contador en pantalla
    expect(find.text('Bebidas'), findsAtLeastNWidgets(1));
    expect(find.text('14 productos disponibles'), findsOneWidget);

    // 5. Verificar productos visibles y formato de precio S/.
    expect(find.text('Inka Cola personal 500ml'), findsOneWidget);
    expect(find.text('S/. 3.00'), findsAtLeastNWidgets(1));
    expect(find.text('Sprite 625 ml'), findsOneWidget);
  });
}
