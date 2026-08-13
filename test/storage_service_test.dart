import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/models.dart';

void main() {
  group('StorageDocument', () {
    test('creates a default document with empty recipe and shopping list collections', () {
      final document = StorageDocument.initial();

      expect(document.version, 1);
      expect(document.recipes, isEmpty);
      expect(document.shoppingLists, isEmpty);
    });

    test('round-trips JSON without losing data', () {
      final document = StorageDocument(
        version: 1,
        recipes: [Recipe(id: 'r1', name: 'Bread', items: const [], createdAt: DateTime.utc(2024, 1, 1))],
        shoppingLists: [
          ShoppingList(
            id: 's1',
            title: 'Groceries',
            content: 'Milk',
            listItems: [ListItem(id: 'i1', text: 'Milk')],
            selectedRecipes: const [],
            isChecklist: true,
            createdAt: DateTime.utc(2024, 1, 2),
            updatedAt: DateTime.utc(2024, 1, 2),
          ),
        ],
      );

      final encoded = document.toJson();
      final decoded = StorageDocument.fromJson(encoded);

      expect(decoded.version, 1);
      expect(decoded.recipes.length, 1);
      expect(decoded.shoppingLists.length, 1);
      expect(decoded.shoppingLists.first.title, 'Groceries');
    });
  });
}
