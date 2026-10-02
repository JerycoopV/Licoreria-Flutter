import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:licoreria_pos/main.dart';
import 'package:licoreria_pos/models/sale.dart';
import 'package:licoreria_pos/repositories/catalog_repository.dart';
import 'package:licoreria_pos/repositories/sales_repository.dart';

void main() {
  setUp(() {
    // Asegurar estado inicial limpio para cada prueba
    SalesRepository().clearAll();
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
      'Cigarros',
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
}
