// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/models.dart';
import 'package:flutter_application_1/services/storage_service.dart';

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

  test('Duplicate items merge into one row with summed quantities', () {
    final items = <ListItem>[ListItem(id: '1', text: 'Milk', quantity: '2')];

    final merged = mergeListItems(items, 'Milk', '3');

    expect(merged.length, 1);
    expect(merged.first.text, 'Milk');
    expect(merged.first.quantity, '5');
  });

  test('Recipe hydration does not re-add quantities when the same recipe is opened again', () {
    final recipes = [
      Recipe(
        id: 'r1',
        name: 'Standaard',
        items: [
          RecipeItem(id: 'i1', name: 'Milk', quantity: '2'),
          RecipeItem(id: 'i2', name: 'Bread', quantity: '1'),
        ],
        createdAt: DateTime.now(),
      ),
    ];

    final firstHydration = hydrateSelectedRecipeItems(
      currentItems: [
        ListItem(id: 'a1', text: 'Milk', quantity: '2'),
      ],
      selectedRecipeNames: ['Standaard'],
      recipes: recipes,
    );

    final secondHydration = hydrateSelectedRecipeItems(
      currentItems: firstHydration,
      selectedRecipeNames: ['Standaard'],
      recipes: recipes,
    );

    expect(secondHydration.length, 2);
    expect(secondHydration.firstWhere((item) => item.text == 'Milk').quantity, '2');
    expect(secondHydration.firstWhere((item) => item.text == 'Bread').quantity, '1');
  });

  test('ListItem clones do not share the same object identity', () {
    final original = [ListItem(id: '1', text: 'Milk', quantity: '2')];

    final clone = [original.first.copyWith()];
    clone.first.quantity = '9';

    expect(original.first.quantity, '2');
  });

  test('Storage service loads an empty document when no data is present', () async {
    SharedPreferences.setMockInitialValues({});

    final service = StorageService();
    await service.initialize();
    final document = await service.loadDocument();

    expect(document.version, 1);
    expect(document.recipes, isEmpty);
    expect(document.shoppingLists, isEmpty);
  });

  test('Loading recipes returns empty list when none saved', () async {
    SharedPreferences.setMockInitialValues({});

    final service = RecipeService();
    await service.initialize();
    final recipes = await service.loadRecipes();

    expect(recipes, isEmpty);
  });
}
