class ListItem {
  final String id;
  final String text;
  bool isChecked;
  String quantity;

  ListItem({
    required this.id,
    required this.text,
    this.isChecked = false,
    this.quantity = '',
  });

  ListItem copyWith({
    String? id,
    String? text,
    bool? isChecked,
    String? quantity,
  }) =>
      ListItem(
        id: id ?? this.id,
        text: text ?? this.text,
        isChecked: isChecked ?? this.isChecked,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isChecked': isChecked,
        'quantity': quantity,
      };

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        isChecked: json['isChecked'] as bool? ?? false,
        quantity: json['quantity'] as String? ?? '',
      );
}

class RecipeItem {
  final String id;
  final String name;
  String quantity;

  RecipeItem({required this.id, required this.name, this.quantity = ''});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
      };

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as String? ?? '',
      );
}

class Recipe {
  final String id;
  final String name;
  final List<RecipeItem> items;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => RecipeItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      );
}

class ShoppingList {
  final String id;
  final String title;
  final String content;
  final List<ListItem> listItems;
  final List<String> selectedRecipes;
  final bool isChecklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    required this.id,
    required this.title,
    this.content = '',
    this.listItems = const [],
    this.selectedRecipes = const [],
    this.isChecklist = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'listItems': listItems.map((item) => item.toJson()).toList(),
        'selectedRecipes': selectedRecipes,
        'isChecklist': isChecklist,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        listItems: (json['listItems'] as List<dynamic>? ?? const [])
            .map((item) => ListItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        selectedRecipes: (json['selectedRecipes'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        isChecklist: json['isChecklist'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      );
}

class StorageDocument {
  final int version;
  final List<Recipe> recipes;
  final List<ShoppingList> shoppingLists;

  StorageDocument({
    required this.version,
    required this.recipes,
    required this.shoppingLists,
  });

  factory StorageDocument.initial() => StorageDocument(version: 1, recipes: const [], shoppingLists: const []);

  Map<String, dynamic> toJson() => {
        'version': version,
        'recipes': recipes.map((recipe) => recipe.toJson()).toList(),
        'shoppingLists': shoppingLists.map((shoppingList) => shoppingList.toJson()).toList(),
      };

  factory StorageDocument.fromJson(Map<String, dynamic> json) => StorageDocument(
        version: json['version'] as int? ?? 1,
        recipes: (json['recipes'] as List<dynamic>? ?? const [])
            .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
            .toList(),
        shoppingLists: (json['shoppingLists'] as List<dynamic>? ?? const [])
            .map((item) => ShoppingList.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
