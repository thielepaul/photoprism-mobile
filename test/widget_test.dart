import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photoprism/main.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('bottom navigation bar switches between pages',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => PhotoprismModel(),
        child: MyApp(),
      ),
    );
    expect(find.byKey(ValueKey("photosGridView")), findsOneWidget);

    await tester.tap(find.byIcon(Icons.photo_album));
    await tester.pump();
    expect(find.byKey(ValueKey("albumsGridView")), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    expect(find.text("Photoprism URL"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.photo));
    await tester.pump();
    expect(find.byKey(ValueKey("photosGridView")), findsOneWidget);
  });

  testWidgets('clicking on photoprism URL opens dialog',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'test': 'test'});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => PhotoprismModel(),
        child: MyApp(),
      ),
    );
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    expect(find.text("Photoprism URL"), findsOneWidget);

    await tester.tap(find.text("Photoprism URL"));
    await tester.pump();
    expect(find.text("Enter Photoprism URL"), findsOneWidget);
    expect(find.text("Save"), findsOneWidget);
    expect(find.text("Cancel"), findsOneWidget);
    expect(find.byKey(ValueKey("photoprismUrlTextField")), findsOneWidget);

    await tester.enterText(find.byKey(ValueKey("photoprismUrlTextField")),
        "http://example.com/test");
    await tester.tap(find.text("Cancel"));
    await tester.pump();
    expect(find.text("http://example.com/test"), findsNothing);
    expect(find.byKey(ValueKey("photoprismUrlTextField")), findsNothing);

    await tester.tap(find.text("Photoprism URL"));
    await tester.pump();
    await tester.enterText(find.byKey(ValueKey("photoprismUrlTextField")),
        "http://example.com/test");
    await tester.tap(find.text("Save"));
    await tester.pump();
    expect(find.byKey(ValueKey("photoprismUrlTextField")), findsNothing);
    expect(find.text("http://example.com/test"), findsOneWidget);
  });

  testWidgets('album test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'albumList':
          '[{"AlbumUUID":"00000000-0000-0000-0000-000000000000","AlbumName":"New Album 1"},{"AlbumUUID":"00000000-0000-0000-0000-000000000001","AlbumName":"New Album 2"}]',
      'photosList00000000-0000-0000-0000-000000000000':
          '[{"FileHash":"0"}, {"FileHash":"1"}]'
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => PhotoprismModel(),
        child: MyApp(),
      ),
    );
    await tester.tap(find.byIcon(Icons.photo_album));
    await tester.pump();
    expect(find.text("New Album 1"), findsOneWidget);
    expect(find.text("New Album 2"), findsOneWidget);
    await tester.tap(find.text("New Album 1"));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(ValueKey("PhotoTile")), findsNWidgets(2));
  });

  testWidgets('photoview test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'albumList':
          '[{"AlbumUUID":"00000000-0000-0000-0000-000000000000","AlbumName":"New Album 1"}]',
      'photosList': '[{"FileHash":"0"}, {"FileHash":"1"}, {"FileHash":"2"}]'
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => PhotoprismModel(),
        child: MyApp(),
      ),
    );
    await tester.pump();
    expect(find.byKey(ValueKey("PhotoTile")), findsNWidgets(3));

    await tester.tap(find.byKey(ValueKey("PhotoTile")).first);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(ValueKey("PhotoView")), findsOneWidget);
  });
}
