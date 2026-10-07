import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_pedido/data.dart';
import 'package:sistema_pedido/main.dart';
import 'package:sistema_pedido/panels.dart';

void main() {
  test(
    'el pedido conserva el precio del catálogo como importe de la línea',
    () {
      const line = OrderLine(
        productId: 'producto-1',
        name: 'Caja',
        categoryName: 'Consumibles',
        unitPriceCents: 2599,
        quantity: 3,
      );
      expect(line.subtotalCents, 7797);
      expect(OrderLine.fromMap(line.toMap()).subtotalCents, 7797);
      expect(money(line.subtotalCents), '\$77.97');
    },
  );

  test('precio no admite importes negativos ni texto', () {
    expect(parsePrice('25.99'), 2599);
    expect(parsePrice('-1'), isNull);
    expect(parsePrice('abc'), isNull);
  });

  testWidgets('login cabe en una pantalla de celular', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(mode: ThemeMode.light, onToggleTheme: () {}),
      ),
    );
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captura de pedido cabe en una pantalla de celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrderEditor(
            products: [],
            categories: [],
            clients: [],
            statuses: [],
          ),
        ),
      ),
    );
    expect(find.text('Nuevo pedido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catálogos e indicadores caben en una pantalla de celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductsPanel(
            products: [
              Item('product-1', {
                'name': 'Producto de prueba',
                'categoryId': 'category-1',
                'priceCents': 2599,
              }),
            ],
            categories: [
              Item('category-1', {'name': 'Categoría'}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 1200);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OverviewPanel(
            orders: [],
            products: [],
            clients: [],
            statuses: [],
            users: [],
            admin: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('orders-trend-chart'))).width,
      greaterThan(200),
    );

    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusesPanel(
            statuses: [
              Item('pending', {'name': 'En espera', 'rank': 10}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('las listas de indicadores se muestran completas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lines = List.generate(
      6,
      (index) => {
        'productId': 'product-$index',
        'name': 'Producto ${index + 1}',
        'categoryName': 'Categoría',
        'unitPriceCents': 1000,
        'quantity': 7 - index,
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverviewPanel(
            orders: [
              Item('order-1', {
                'statusId': 'delivered',
                'totalCents': 21000,
                'lines': lines,
              }),
            ],
            products: const [],
            clients: const [],
            statuses: const [
              Item('pending', {'name': 'En espera'}),
              Item('preparing', {'name': 'En preparación'}),
              Item('shipped', {'name': 'Enviado'}),
              Item('delivered', {'name': 'Entregado'}),
            ],
            users: const [],
            admin: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Productos más solicitados'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Producto 6 · 2 unidades', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
