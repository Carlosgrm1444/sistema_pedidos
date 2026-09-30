// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sistema_pedido/main.dart';

void main() {
  testWidgets('el usuario predeterminado puede iniciar sesión', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SQL_BROS'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    final campos = find.byType(TextFormField);
    expect(campos, findsNWidgets(2));

    await tester.enterText(campos.at(0), 'admin@sqlbros.com');
    await tester.enterText(campos.at(1), '123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Sistema de Pedidos - Memo'), findsOneWidget);
    expect(find.text('Registrar Producto'), findsOneWidget);
  });
}
