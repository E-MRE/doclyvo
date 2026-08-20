import 'dart:async';

import 'package:doclyvo/app/app_router.dart';
import 'package:doclyvo/app/constants/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    router.go(RouteConstants.home);
  });

  testWidgets('boots to the home placeholder', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('navigates to a tool route with a fade-in-up transition', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    unawaited(router.push(RouteConstants.compress));
    await tester.pump();

    expect(find.byType(Opacity), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('Compress'), findsWidgets);
  });

  testWidgets('back navigation returns to the previous route', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    unawaited(router.push(RouteConstants.merge));
    await tester.pumpAndSettle();
    expect(find.text('Merge'), findsWidgets);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
  });
}
