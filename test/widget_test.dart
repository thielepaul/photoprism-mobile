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
    SharedPreferences.setMockInitialValues(<String, String>{'test': 'test'});

    await tester.pumpWidget(
      ChangeNotifierProvider<PhotoprismModel>(
        create: (BuildContext context) => PhotoprismModel(),
        child: PhotoprismApp(),
      ),
    );
    await tester.pump();
    expect(
        find.byKey(const ValueKey<String>('photosGridView')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.photo_album));
    await tester.pump();
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
    SharedPreferences.setMockInitialValues(<String, String>{'test': 'test'});

    await tester.pumpWidget(
      ChangeNotifierProvider<PhotoprismModel>(
        create: (BuildContext context) => PhotoprismModel(),
        child: PhotoprismApp(),
      ),
    );
    await tester.pump();
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
    SharedPreferences.setMockInitialValues(<String, String>{
      'albums':
          '{"0":{"AlbumUUID":"00000000-0000-0000-0000-000000000000","AlbumName":"New Album 1", "AlbumCount": 2},"1":{"AlbumUUID":"00000000-0000-0000-0000-000000000001","AlbumName":"New Album 2", "AlbumCount": 0}}',
      'photos0':
          '{"0":{"FileHash":"0", "PhotoUUID":"00000000-0000-0000-0000-000000000000", "FileAspectRatio":1}, "1":{"FileHash":"1", "PhotoUUID":"00000000-0000-0000-0000-000000000000", "FileAspectRatio":1}}'
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<PhotoprismModel>(
        create: (BuildContext context) => PhotoprismModel(),
        child: PhotoprismApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.photo_album));
    await tester.pump();
    expect(find.text('New Album 1'), findsOneWidget);
    expect(find.text('New Album 2'), findsOneWidget);
    await tester.tap(find.text('New Album 1'));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('PhotoTile')), findsNWidgets(2));
  });

  testWidgets('photoview test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, String>{
      'momentsTime': '[{"PhotoYear":0, "PhotoMonth":0, "Count":3}]',
      'albumList':
          '{"0":{"AlbumUUID":"00000000-0000-0000-0000-000000000000","AlbumName":"New Album 1"}}',
      'photosList':
          '{"0":{"FileHash":"0", "PhotoUUID":"00000000-0000-0000-0000-000000000000", "FileAspectRatio":1}, "1":{"FileHash":"1", "PhotoUUID":"00000000-0000-0000-0000-000000000000", "FileAspectRatio":1}, "2":{"FileHash":"2", "PhotoUUID":"00000000-0000-0000-0000-000000000000", "FileAspectRatio":1}}'
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<PhotoprismModel>(
        create: (BuildContext context) => PhotoprismModel(),
        child: PhotoprismApp(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('PhotoTile')), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey<String>('PhotoTile')).first);
    // await tester.pump();
    // await tester.pump();
    // expect(find.byKey(ValueKey("PhotoView")), findsOneWidget);
  });
}
