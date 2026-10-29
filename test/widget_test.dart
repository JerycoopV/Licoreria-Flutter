import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:licoreria_pos/main.dart';
import 'package:licoreria_pos/models/product.dart';
import 'package:licoreria_pos/models/sale.dart';
import 'package:licoreria_pos/presentation/categories/category_detail_screen.dart';
import 'package:licoreria_pos/core/services/boleta_pdf_service.dart';
import 'package:licoreria_pos/models/boleta.dart';
import 'package:licoreria_pos/presentation/boletas/boletas_screen.dart';
import 'package:licoreria_pos/repositories/boletas_repository.dart';
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
    await BoletasRepository().clearAll();
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

    // Verificar que todas las categorías están presentes en el catálogo
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
      'Bebidas alcohólicas preparadas',
      'Whisky',
      'Combos',
      'Hielo',
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

  testWidgets('8. Categoría Bebidas: Muestra exactamente los 23 productos con sus nombres, precios y fallback visual', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CatalogRepository().loadProducts();
    final bebidasCategory = CatalogRepository.getCategoryById('bebidas')!;
    final bebidasProducts = CatalogRepository().getProductsByCategory('bebidas');

    // 1. Verificar conteo de 28 productos en Bebidas
    expect(bebidasProducts.length, 28);

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
      {'nombre': 'Fanta 500ml', 'precio': 2.50},
      {'nombre': 'Hey Frit 600ml', 'precio': 2.50},
      {'nombre': 'San Mateo 600ml', 'precio': 2.00},
      {'nombre': 'San Luis 625ml', 'precio': 2.00},
      {'nombre': 'Sporade 500ml', 'precio': 2.50},
      {'nombre': 'Sporade 1.5L', 'precio': 5.50},
      {'nombre': 'Inka Cola piraña 192ml', 'precio': 1.20},
      {'nombre': 'Coca Cola piraña 192ml', 'precio': 1.20},
      {'nombre': 'Fanta cola piraña 192ml', 'precio': 1.20},
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

    // Verificar nuevas gaseosas (Guaraná y Pepsi)
    expect(bebidasProducts.any((p) => p.nombre == 'Guaraná 300ml' && p.precio == 1.5), isTrue);
    expect(bebidasProducts.any((p) => p.nombre == 'Guaraná 450ml' && p.precio == 2.5), isTrue);
    expect(bebidasProducts.any((p) => p.nombre == 'Guaraná 2L' && p.precio == 6.5), isTrue);
    expect(bebidasProducts.any((p) => p.nombre == 'Pepsi personal 700ml' && p.precio == 3.0), isTrue);
    expect(bebidasProducts.any((p) => p.nombre == 'Pepsi 300ml' && p.precio == 1.2), isTrue);

    // Verificar alias "gaseosa" y búsqueda fonética "pepso"
    expect(CatalogRepository.getCategoryById('gaseosa'), isNotNull);
    expect(CatalogRepository.getCategoryById('gaseosa')!.id, 'bebidas');
    expect(CatalogRepository().searchProducts('pepso').any((p) => p.nombre == 'Pepsi 300ml'), isTrue);

    // 3. Renderizar CategoryDetailScreen para Bebidas
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDetailScreen(category: bebidasCategory),
      ),
    );
    await tester.pumpAndSettle();

    // 4. Verificar cabecera y contador en pantalla
    expect(find.text('Bebidas'), findsAtLeastNWidgets(1));
    expect(find.text('28 productos disponibles'), findsOneWidget);

    // 5. Verificar productos visibles y formato de precio S/.
    expect(find.text('Inka Cola personal 500ml'), findsOneWidget);
    expect(find.text('S/. 3.00'), findsAtLeastNWidgets(1));
    expect(find.text('Sprite 625 ml'), findsOneWidget);
  });

  testWidgets('9. Categoría Bebidas alcohólicas preparadas: Muestra productos y permite visualización', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CatalogRepository().loadProducts();
    final preparadasCategory = CatalogRepository.getCategoryById('bebidas_alcoholicas_preparadas');
    expect(preparadasCategory, isNotNull);
    expect(preparadasCategory!.name, 'Bebidas alcohólicas preparadas');

    final preparadasProducts = CatalogRepository().getProductsByCategory('bebidas_alcoholicas_preparadas');
    expect(preparadasProducts.isNotEmpty, isTrue);
    expect(preparadasProducts.any((p) => p.name.contains("Mike's")), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDetailScreen(category: preparadasCategory),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bebidas alcohólicas preparadas'), findsAtLeastNWidgets(1));
    expect(find.textContaining("Mike's"), findsOneWidget);
  });

  testWidgets('10. Nuevas Categorías: Whisky, Combos y Hielo están disponibles con sus productos', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CatalogRepository().loadProducts();

    // 1. Verificar existencia de las categorías
    final whiskyCat = CatalogRepository.getCategoryById('whisky');
    final combosCat = CatalogRepository.getCategoryById('combos');
    final hieloCat = CatalogRepository.getCategoryById('hielo');

    expect(whiskyCat, isNotNull);
    expect(whiskyCat!.name, 'Whisky');
    expect(combosCat, isNotNull);
    expect(combosCat!.name, 'Combos');
    expect(hieloCat, isNotNull);
    expect(hieloCat!.name, 'Hielo');

    // 2. Verificar productos cargados
    final whiskyProducts = CatalogRepository().getProductsByCategory('whisky');
    expect(whiskyProducts.isNotEmpty, isTrue);
    expect(whiskyProducts.any((p) => p.name.contains('Johnnie Walker')), isTrue);

    final combosProducts = CatalogRepository().getProductsByCategory('combos');
    expect(combosProducts.length, 27);
    expect(combosProducts.any((p) => p.name.contains('Ron Cartavio')), isTrue);
    expect(combosProducts.any((p) => p.name.contains('Whisky Red Label')), isTrue);
    expect(combosProducts.any((p) => p.name.contains('Jägermeister')), isTrue);

    final hieloProducts = CatalogRepository().getProductsByCategory('hielo');
    expect(hieloProducts.isNotEmpty, isTrue);
    expect(hieloProducts.any((p) => p.name.contains('Bolsa de Hielo')), isTrue);

    // Verificar nuevos productos incorporados
    final ronProducts = CatalogRepository().getProductsByCategory('ron');
    expect(ronProducts.any((p) => p.name == 'Ron Havana Club'), isTrue);
    expect(ronProducts.any((p) => p.name == 'Ron Bacardí'), isTrue);

    final piscoProducts = CatalogRepository().getProductsByCategory('pisco');
    expect(piscoProducts.any((p) => p.name == 'Pisco Queirolo Quebranta'), isTrue);

    final vodkasProducts = CatalogRepository().getProductsByCategory('vodkas');
    expect(vodkasProducts.any((p) => p.name == 'Sky Vodka'), isTrue);
    expect(CatalogRepository().getProductsByCategory('vodka').any((p) => p.name == 'Sky Vodka'), isTrue);

    // Verificar vinos actualizados y nuevos
    final vinoProducts = CatalogRepository().getProductsByCategory('vino');
    expect(vinoProducts.firstWhere((p) => p.name.contains('Tacama')).price, 23.0);
    expect(vinoProducts.firstWhere((p) => p.name.contains('Tabernero Borgoña')).price, 20.0);
    expect(vinoProducts.any((p) => p.name == 'Vino Tabernero Semi Seco 750ml' && p.price == 18.0), isTrue);
    expect(vinoProducts.any((p) => p.name == 'Vino Santiago Queirolo 750ml' && p.price == 19.0), isTrue);

    // Verificar chicles y mentas actualizados y nuevos
    final chiclesProducts = CatalogRepository().getProductsByCategory('chicles_mentas');
    expect(chiclesProducts.any((p) => p.name == 'Barra de Halls' && p.price == 2.0), isTrue);
    expect(chiclesProducts.any((p) => p.name == 'Trident paquete 14 chicles 25,2g' && p.price == 2.0), isTrue);
    expect(chiclesProducts.any((p) => p.name == 'Chicles unidad' && p.price == 0.3), isTrue);
    expect(chiclesProducts.any((p) => p.name == '3 Chicles' && p.price == 0.5), isTrue);
    expect(chiclesProducts.any((p) => p.name == 'Chupetín' && p.price == 0.4), isTrue);
    expect(chiclesProducts.any((p) => p.name == 'Halls unidad' && p.price == 0.3), isTrue);
    expect(chiclesProducts.any((p) => p.name == '3 Halls' && p.price == 0.5), isTrue);

    // Solo debe haber un Trident y una Barra de Halls
    expect(chiclesProducts.where((p) => p.name.toLowerCase().contains('trident')).length, 1);
    expect(chiclesProducts.where((p) => p.name.toLowerCase().contains('barra de halls')).length, 1);

    // Búsqueda con soporte para aliases "hals" y "chiles"
    expect(CatalogRepository().searchProducts('hals').any((p) => p.name == 'Barra de Halls'), isTrue);
    expect(CatalogRepository().searchProducts('chiles').any((p) => p.name == 'Chicles unidad'), isTrue);

    // 3. Renderizar pantalla de detalle para Whisky
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDetailScreen(category: whiskyCat),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Whisky'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Johnnie Walker Red Label'), findsOneWidget);
  });

  testWidgets('11. Función exclusiva Yape: Combinar ventas de Yape y separar ventas combinadas', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await SalesRepository().clearAll();

    // 1. Registrar 2 ventas de Yape y 1 de Efectivo (exactamente como la captura del usuario)
    final saleYape1 = Sale(
      id: 'yape_1',
      nombre: 'Vodka Absolut Original 750ml',
      categoria: 'Vodkas',
      cantidad: 1,
      precio: 41.00,
      metodoPago: 'Yape',
      createdAt: DateTime.now(),
    );

    final saleYape2 = Sale(
      id: 'yape_2',
      nombre: 'Pisco Portón Mosto Verde 750ml',
      categoria: 'Pisco',
      cantidad: 1,
      precio: 89.00,
      metodoPago: 'Yape',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final saleEfectivo = Sale(
      id: 'efectivo_1',
      nombre: 'Six Pack Pilsen Callao Latas',
      categoria: 'Cervezas',
      cantidad: 2,
      precio: 32.00,
      metodoPago: 'Efectivo',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    );

    await SalesRepository().recordSale(saleEfectivo);
    await SalesRepository().recordSale(saleYape2);
    await SalesRepository().recordSale(saleYape1);

    expect(SalesRepository().sales.length, 3);
    expect(SalesRepository().totalSalesAmount, 194.00);
    expect(SalesRepository().totalCashAmount, 64.00);
    expect(SalesRepository().totalYapeAmount, 130.00);

    // 2. Renderizar HomeScreen y verificar interfaz
    await tester.pumpWidget(const LicoreriaApp());
    await tester.pumpAndSettle();

    expect(find.text('S/. 194.00'), findsOneWidget);
    expect(find.text('S/. 130.00'), findsOneWidget);
    expect(find.text('3 ventas'), findsOneWidget);

    // 3. Ejecutar combinación de las 2 ventas de Yape
    final success = await SalesRepository().combineYapeSales(
      baseSale: saleYape1,
      salesToCombine: [saleYape2],
    );
    expect(success, isTrue);

    await tester.pumpAndSettle();

    // 4. Verificar que se unificaron en 1 sola venta de Yape
    expect(SalesRepository().sales.length, 2); // 1 Efectivo + 1 Yape unificado
    expect(SalesRepository().totalYapeAmount, 130.00);
    expect(SalesRepository().totalSalesAmount, 194.00);
    expect(find.text('2 ventas'), findsOneWidget);
    expect(find.text('COMBINADO'), findsOneWidget);
    expect(find.textContaining('Vodka Absolut Original 750ml + Pisco Portón Mosto Verde 750ml'), findsOneWidget);

    // 5. Verificar que se pueden separar las ventas combinadas
    final combinedSale = SalesRepository().sales.firstWhere((s) => s.isCombined);
    expect(combinedSale.originalSales.length, 2);

    final unmerged = await SalesRepository().separateCombinedSale(combinedSale);
    expect(unmerged, isTrue);

    await tester.pumpAndSettle();

    expect(SalesRepository().sales.length, 3);
    expect(find.text('3 ventas'), findsOneWidget);
    expect(find.text('COMBINADO'), findsNothing);
  });

  testWidgets(
      '12. Pantallas pequeñas (320px de ancho): Botón de nueva venta e historial renderizan sin desbordamientos',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await SalesRepository().clearAll();

    // Registrar ventas con nombres largos
    await SalesRepository().recordSale(
      Sale(
        id: 'test_small_1',
        nombre: 'Pisco Portón Mosto Verde 750ml',
        categoria: 'Pisco',
        cantidad: 1,
        precio: 89.00,
        metodoPago: 'Yape',
        createdAt: DateTime.now(),
      ),
    );
    await SalesRepository().recordSale(
      Sale(
        id: 'test_small_2',
        nombre: 'Six Pack Pilsen Callao Latas',
        categoria: 'Cervezas',
        cantidad: 2,
        precio: 32.00,
        metodoPago: 'Efectivo',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );

    await tester.pumpWidget(const LicoreriaApp());
    await tester.pumpAndSettle();

    // Verificar que el botón de nueva venta y su texto existen y no causan overflow
    expect(find.text('NUEVA VENTA'), findsOneWidget);
    expect(find.text('Toca para abrir categorías y registrar'), findsOneWidget);

    // Desplazar para verificar que los elementos del historial se renderizan correctamente
    await tester.scrollUntilVisible(
      find.textContaining('Pisco Portón'),
      100,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('13. Modelo Boleta: Constructor, serialización toMap/fromMap y generación de ticket en texto plano', () {
    final now = DateTime(2026, 10, 29, 1, 30);
    final items = [
      const BoletaItem(
        id: '1',
        nombre: 'Pilsen Callao margarito 1L',
        categoria: 'Cervezas',
        cantidad: 2,
        precioUnitario: 10.0,
        subtotal: 20.0,
        metodoPago: 'Efectivo',
      ),
      const BoletaItem(
        id: '2',
        nombre: 'Coca Cola personal 500ml',
        categoria: 'Bebidas',
        cantidad: 1,
        precioUnitario: 3.0,
        subtotal: 3.0,
        metodoPago: 'Yape',
      ),
    ];

    final boleta = Boleta(
      id: 'boleta_test_1',
      numero: 'B001-00001',
      fecha: now,
      items: items,
    );

    expect(boleta.id, 'boleta_test_1');
    expect(boleta.numero, 'B001-00001');
    expect(boleta.total, 23.0);
    expect(boleta.totalEfectivo, 20.0);
    expect(boleta.totalYape, 3.0);
    expect(boleta.cantidadProductos, 3);

    // Verificación de toMap y fromMap
    final map = boleta.toMap();
    expect(map['numero'], 'B001-00001');
    expect(map['total'], 23.0);
    expect(map['items'], isList);

    final fromMapBoleta = Boleta.fromMap(map);
    expect(fromMapBoleta.numero, 'B001-00001');
    expect(fromMapBoleta.items.length, 2);
    expect(fromMapBoleta.total, 23.0);
    expect(fromMapBoleta.totalEfectivo, 20.0);
    expect(fromMapBoleta.totalYape, 3.0);

    // Verificación de ticket plano
    final ticketText = boleta.toPlainTextTicket();
    expect(ticketText, contains('BOLETA DE VENTA'));
    expect(ticketText, contains('B001-00001'));
    expect(ticketText, contains('Pilsen Callao'));
    expect(ticketText, contains('Coca Cola personal'));
    expect(ticketText, contains('TOTAL A PAGAR: S/. 23.00'));
  });

  test('14. BoletasRepository: Genera y persiste boleta a partir de ventas con fecha actual', () async {
    final now = DateTime.now();
    final sales = [
      Sale(
        id: 'sale_1',
        nombre: 'Cuates 43g',
        categoria: 'Frituras',
        cantidad: 2,
        precio: 1.0,
        metodoPago: 'Efectivo',
        createdAt: now,
      ),
      Sale(
        id: 'sale_2',
        nombre: 'Fanta 625 ml',
        categoria: 'Bebidas',
        cantidad: 1,
        precio: 2.5,
        metodoPago: 'Yape',
        createdAt: now,
      ),
    ];

    final repo = BoletasRepository();
    expect(repo.boletas.isEmpty, isTrue);

    final boleta = await repo.createBoletaFromSales(sales);
    expect(boleta.numero, 'B001-00001');
    expect(boleta.items.length, 2);
    expect(boleta.total, 4.5);
    expect(repo.boletas.length, 1);
    expect(repo.totalBoletasAmount, 4.5);

    // Recargar desde SharedPreferences para verificar persistencia
    final reloaded = await repo.loadBoletas();
    expect(reloaded.length, 1);
    expect(reloaded.first.numero, 'B001-00001');
  });

  testWidgets('15. Flujo Exporta Boleta: Botón en Home guarda los productos vendidos en el listado de boletas', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await SalesRepository().clearAll();
    await BoletasRepository().clearAll();

    // 1. Cargar Home inicialmente con 0 ventas
    await tester.pumpWidget(const LicoreriaApp());
    await tester.pumpAndSettle();

    // El botón 'EXPORTA BOLETA' está presente al inicio de la lista
    expect(find.text('EXPORTA BOLETA'), findsOneWidget);

    // 2. Registrar 2 ventas
    await SalesRepository().recordSale(
      Sale(
        id: 'v1',
        nombre: 'Pilsen Callao margarito 1L',
        categoria: 'Cervezas',
        cantidad: 1,
        precio: 10.0,
        metodoPago: 'Efectivo',
      ),
    );
    await SalesRepository().recordSale(
      Sale(
        id: 'v2',
        nombre: 'Coca Cola personal 500ml',
        categoria: 'Bebidas',
        cantidad: 1,
        precio: 3.0,
        metodoPago: 'Yape',
      ),
    );
    await tester.pumpAndSettle();

    // Verificar que el botón muestra el contador de 2 productos
    expect(find.text('EXPORTA BOLETA'), findsOneWidget);
    expect(find.text('2'), findsAtLeastNWidgets(1));

    // 3. Tocar el botón 'EXPORTA BOLETA'
    await tester.tap(find.text('EXPORTA BOLETA'));
    await tester.pumpAndSettle();

    // 4. Modal de Boleta abierta con diseño de ticket y datos
    expect(find.text('Boleta Generada'), findsOneWidget);
    expect(find.text('B001-00001'), findsAtLeastNWidgets(1));
    expect(find.text('Pilsen Callao margarito 1L'), findsAtLeastNWidgets(1));
    expect(find.text('Coca Cola personal 500ml'), findsAtLeastNWidgets(1));
    expect(find.text('S/. 13.00'), findsAtLeastNWidgets(1));

    // Verificar que la boleta se guardó en BoletasRepository
    expect(BoletasRepository().boletas.length, 1);
    expect(BoletasRepository().boletas.first.numero, 'B001-00001');

    // 5. Opción de limpiar para nueva venta
    expect(find.text('¿Deseas iniciar una nueva venta?'), findsOneWidget);
    await tester.tap(find.text('Nueva venta'));
    await tester.pumpAndSettle();

    // Los registros de la pantalla principal se limpiaron para la nueva venta
    expect(SalesRepository().sales.isEmpty, isTrue);
    expect(find.text('No hay registros anteriores'), findsOneWidget);

    // Pero la boleta sigue guardada en el listado
    expect(BoletasRepository().boletas.length, 1);
  });

  testWidgets('16. Pantalla BoletasScreen: Muestra listado de boletas guardadas y permite buscar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await BoletasRepository().clearAll();

    // Crear una boleta en el repositorio
    await BoletasRepository().createBoletaFromSales([
      Sale(
        id: 'prod_1',
        nombre: 'Whisky Red Label',
        categoria: 'Whisky',
        cantidad: 1,
        precio: 65.0,
        metodoPago: 'Yape',
      ),
    ]);

    await tester.pumpWidget(
      const MaterialApp(
        home: BoletasScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verificar cabecera y boleta listada
    expect(find.text('Listado de Boletas'), findsOneWidget);
    expect(find.text('B001-00001'), findsOneWidget);
    expect(find.textContaining('Whisky Red Label'), findsOneWidget);
    expect(find.text('S/. 65.00'), findsOneWidget);

    // Búsqueda en el listado
    await tester.enterText(find.byType(TextField), 'Vodka');
    await tester.pumpAndSettle();
    expect(find.textContaining('No se encontraron boletas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Whisky');
    await tester.pumpAndSettle();
    expect(find.text('B001-00001'), findsOneWidget);
  });

  test('17. BoletaPdfService: Generación de archivo PDF válido para compartir', () async {
    final boleta = Boleta(
      id: 'boleta_pdf_test',
      numero: 'B001-00042',
      items: [
        const BoletaItem(
          id: '1',
          nombre: 'Pisco Portón Mosto Verde 750ml',
          categoria: 'Pisco',
          cantidad: 1,
          precioUnitario: 89.0,
          subtotal: 89.0,
          metodoPago: 'Yape',
        ),
      ],
    );

    final pdfBytes = await BoletaPdfService.generateBoletaPdf(boleta);
    expect(pdfBytes, isNotEmpty);
    // Un archivo PDF siempre inicia con la firma de encabezado "%PDF"
    final header = String.fromCharCodes(pdfBytes.take(4));
    expect(header, '%PDF');
  });
}


