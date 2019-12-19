import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photoprism/main.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

void main() {
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
}
