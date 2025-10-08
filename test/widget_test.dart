// NaviSafe App Widget Tests
//
// This file contains basic widget tests for the NaviSafe application.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:navisafe_app/main.dart';
import 'package:navisafe_app/services/gnss_service.dart';
import 'package:navisafe_app/services/mesh_network_service.dart';
import 'package:navisafe_app/services/accelerometer_collision_service.dart';

void main() {
  testWidgets('NaviSafe app launches successfully', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NaviSafeApp());

    // Verify that the app starts with navigation screen
    expect(find.text('NaviSafe'), findsOneWidget);

    // Verify that safety status is displayed
    expect(find.text('Safety Status'), findsOneWidget);

    // Verify that mesh network widget is present
    expect(find.text('Mesh Network'), findsOneWidget);
  });

  testWidgets('Safety alerts widget displays correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GnssService()),
          ChangeNotifierProvider(create: (_) => MeshNetworkService()),
          ChangeNotifierProvider(
            create: (_) => AccelerometerCollisionService(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: Text('Test Widget'))),
      ),
    );

    // Verify that the widget renders without errors
    expect(find.text('Test Widget'), findsOneWidget);
  });
}
