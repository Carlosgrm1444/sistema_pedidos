import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_pedido/design.dart';
import 'package:sistema_pedido/main.dart';

void main() {
  Future<void> checkLogin(
    WidgetTester tester,
    Size size,
    String fileName, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(brightness),
        home: LoginView(
          mode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          onToggleTheme: () {},
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/brand/mark.png'),
        tester.element(find.byType(LoginView)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(Image).first).dy,
      greaterThanOrEqualTo(0),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/$fileName'),
    );
  }

  testWidgets('login móvil conserva su composición', (tester) async {
    await checkLogin(tester, const Size(390, 844), 'login_mobile.png');
  });

  testWidgets('login de escritorio conserva su composición', (tester) async {
    await checkLogin(tester, const Size(1280, 800), 'login_desktop.png');
  });

  testWidgets('login oscuro conserva su composición', (tester) async {
    await checkLogin(
      tester,
      const Size(390, 844),
      'login_dark_mobile.png',
      brightness: Brightness.dark,
    );
  });
}
