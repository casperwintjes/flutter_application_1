// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Notes app displays empty state', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    // Verify that the app displays the empty state message
    expect(find.text('No notes yet'), findsOneWidget);
    expect(
      find.text('Tap the + button to create your first note'),
      findsOneWidget,
    );

    // Verify that the FAB is present
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  test('Duplicate items merge into one row with multiplied quantities', () {
    final items = <ListItem>[ListItem(id: '1', text: 'Milk', quantity: '2')];

    final merged = mergeListItems(items, 'Milk', '3');

    expect(merged.length, 1);
    expect(merged.first.text, 'Milk');
    expect(merged.first.quantity, '6');
  });

  test('Shared storage reads from a configured shared endpoint', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://example.com/storage');
      expect(request.headers['Authorization'], 'Bearer secret-token');
      return http.Response(jsonEncode({'notes_list': '[]'}), 200);
    });

    final storage = SharedStorageService(
      client: client,
      endpointUrl: 'https://example.com/storage',
      token: 'secret-token',
    );

    final value = await storage.loadValue('notes_list');

    expect(value, '[]');
  });
}
