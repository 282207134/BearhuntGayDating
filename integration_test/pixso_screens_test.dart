import 'dart:convert';
import 'dart:ui' as ui;

import 'package:bearhunt/design/scene.dart';
import 'package:bearhunt/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const capture = bool.fromEnvironment('BEARHUNT_CAPTURE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Onboarding, filtering, messaging, profile and purchase', (
    tester,
  ) async {
    final library = await SceneLibrary.load();
    await tester.pumpWidget(BearHunt(library: library, initial: Screen.login));
    await tester.pumpAndSettle();

    Future<void> press(String name) async {
      final control = find.byKey(ValueKey(name)).last;
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
    }

    await press('Connect with Facebook');
    await press('Next');
    await press('Top');
    await press('Next');
    await press('Asian');
    await press('Next');
    await press('Friends');
    await tester.tap(find.widgetWithText(TextButton, 'Done'));
    await tester.pumpAndSettle();
    await press('Discover');

    await press('Filters');
    await press('Role');
    await press('Top');
    await press('Back');
    expect(find.text('Top'), findsOneWidget);
    await press('Done');

    await press('Chat');
    await press('Chat with Danny Rice');
    await tester.enterText(find.byType(TextField), 'Hello from the emulator');
    await tester.pumpAndSettle();
    await press('Send message');
    expect(find.text('Hello from the emulator'), findsOneWidget);

    await press('Back');
    await press('Profile');
    await press('Edit Profile');
    await press('Full name');
    await tester.enterText(find.byType(TextFormField), 'BearHunt Tester');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    await press('Done');
    expect(find.text('BearHunt Tester'), findsOneWidget);

    await press('Store');
    await press('Buy 100 credits');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    await press('OK');
    expect(find.text('600'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Export the 57 Flutter scenes',
    (tester) async {
      final library = await SceneLibrary.load();
      final captures = <String, String>{};
      binding.reportData = {'captures': captures};
      final boundary = GlobalKey();
      for (final screen in Screen.values) {
        final scene = library[screen];
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: boundary,
                  child: SizedBox(
                    width: designWidth,
                    height: scene.height - designStatusHeight,
                    child: MediaQuery(
                      data: MediaQueryData(
                        size: Size(
                          designWidth,
                          scene.height - designStatusHeight,
                        ),
                      ),
                      child: BearHunt(
                        key: ValueKey(screen),
                        library: library,
                        initial: screen,
                        animateTransitions: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // PNG image decodes run on the engine's IO thread.
        await tester.runAsync(() async {
          final context = boundary.currentContext!;
          final paths = [
            ...scene.layers,
            ...scene.footer,
          ].whereType<ImageLayer>().map((layer) => layer.path).toSet();
          await Future.wait(
            paths.map((path) => precacheImage(AssetImage(path), context)),
          );
        });
        await tester.pumpAndSettle();
        final view =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await view.toImage(pixelRatio: 2);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final id = screen.number.toString().padLeft(2, '0');
        captures[id] = base64Encode(bytes.buffer.asUint8List());
        image.dispose();
        expect(tester.takeException(), isNull, reason: scene.name);
      }
    },
    skip: !capture,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
