import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:moor/ffi.dart';

import 'package:photoprism/common/db.dart';
import 'package:photoprism/main.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHttpOverrides extends HttpOverrides {}

Future<void> pumpPhotoPrism(WidgetTester tester, PhotoprismModel model) async {
  await EasyLocalization.ensureInitialized();

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
          supportedLocales: const <Locale>[
            Locale('en', 'US'),
            Locale('de', 'DE')
          ],
          path: 'assets/translations',
          fallbackLocale: const Locale('en', 'US'),
          child: ChangeNotifierProvider<PhotoprismModel>(
            create: (BuildContext context) => model,
            child: PhotoprismApp(),
          )),
    );
    await tester.idle();
    await tester.pumpAndSettle();
  });
}

class SecureStorageMock extends Mock implements FlutterSecureStorage {}

void main() {
  PhotoprismModel model;

  setUp(() async {
    SharedPreferences.setMockInitialValues(
        <String, String>{'url': 'http://localhost:2342'});
    HttpOverrides.global = TestHttpOverrides();
    final SecureStorageMock secureStorageMock = SecureStorageMock();
    model = PhotoprismModel(
        () async => MyDatabase(VmDatabase.memory()), secureStorageMock);
    await model.initialize();
  });

  tearDown(() async {
    try {
      await model.dispose();
    } catch (e) {
      print('Disposing model failed: $e');
    }
  });

  testWidgets('bottom navigation bar switches between pages',
      (WidgetTester tester) async {
    await pumpPhotoPrism(tester, model);
    expect(
        find.byKey(const ValueKey<String>('photosGridView')), findsOneWidget);

    final Finder albumIcon = find.byIcon(Icons.photo_album);
    expect(albumIcon, findsOneWidget);
    await tester.tap(albumIcon);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('albumsGridView')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    expect(find.text('Photoprism URL'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.photo));
    await tester.pump();
    expect(
        find.byKey(const ValueKey<String>('photosGridView')), findsOneWidget);
  });

  testWidgets('clicking on photoprism URL opens dialog',
      (WidgetTester tester) async {
    await pumpPhotoPrism(tester, model);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    expect(find.text('Photoprism URL'), findsOneWidget);

    await tester.tap(find.text('Photoprism URL'));
    await tester.pump();
    expect(find.text('Enter Photoprism URL'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('photoprismUrlTextField')),
        findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey<String>('photoprismUrlTextField')),
        'http://example.com/test');
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('http://example.com/test'), findsNothing);
    expect(find.byKey(const ValueKey<String>('photoprismUrlTextField')),
        findsNothing);

    await tester.tap(find.text('Photoprism URL'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey<String>('photoprismUrlTextField')),
        'http://example.com/test');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('photoprismUrlTextField')),
        findsNothing);
    expect(find.text('http://example.com/test'), findsOneWidget);
  });

  testWidgets('album test', (WidgetTester tester) async {
    // TODO this test does not really make sense like it is now
    await pumpPhotoPrism(tester, model);
    await tester.tap(find.byIcon(Icons.photo_album));
    await tester.pumpAndSettle();
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('California'), findsOneWidget);
    await tester.tap(find.text('California'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('PhotoTile')), findsNWidgets(30));
  });

  testWidgets('photoview test', (WidgetTester tester) async {
    await pumpPhotoPrism(tester, model);
    expect(find.byKey(const ValueKey<String>('PhotoTile')), findsNWidgets(24));

    await tester.tap(find.byKey(const ValueKey<String>('PhotoTile')).first);
    // await tester.pumpAndSettle();
    // expect(find.byKey(const ValueKey<String>('PhotoView')), findsOneWidget);
  });
}
