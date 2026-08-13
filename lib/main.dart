import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'services/models.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const NotesApp());
}

int _parseQuantityValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 1;
  return int.tryParse(trimmed) ?? 1;
}

List<ListItem> mergeListItems(
  List<ListItem> items,
  String text,
  String quantity,
) {
  final normalizedText = text.trim();
  if (normalizedText.isEmpty) {
    return List<ListItem>.from(items);
  }

  final updatedItems = List<ListItem>.from(items);
  final existingIndex = updatedItems.indexWhere(
    (item) => item.text.trim().toLowerCase() == normalizedText.toLowerCase(),
  );

  if (existingIndex != -1) {
    final existing = updatedItems[existingIndex];
    final sum = _parseQuantityValue(existing.quantity) + _parseQuantityValue(quantity);
    updatedItems[existingIndex] = ListItem(
      id: existing.id,
      text: existing.text,
      isChecked: existing.isChecked,
      quantity: sum.toString(),
    );
    return updatedItems;
  }

  // ensure a unique id even when items are added rapidly
  // Use a safe upper bound for nextInt to avoid JS 32-bit shift overflow on web.
  final uniqueId = '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}';
  updatedItems.add(
    ListItem(
      id: uniqueId,
      text: normalizedText,
      quantity: quantity.trim().isEmpty ? '1' : quantity.trim(),
    ),
  );

  return updatedItems;
}

class Note extends ShoppingList {
  Note({
    required super.id,
    required super.title,
    super.content = '',
    super.listItems = const [],
    super.selectedRecipes = const [],
    super.isChecklist = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
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

class NotesService {
  NotesService({StorageService? storage}) : _storage = storage ?? StorageService();

  final StorageService _storage;

  Future<void> initialize() async {
    await _storage.initialize();
  }

  Future<List<Note>> loadNotes() async {
    final document = await _storage.loadDocument();
    final notes = document.shoppingLists
        .map(
          (shoppingList) => Note(
            id: shoppingList.id,
            title: shoppingList.title,
            content: shoppingList.content,
            listItems: shoppingList.listItems,
            selectedRecipes: shoppingList.selectedRecipes,
            isChecklist: shoppingList.isChecklist,
            createdAt: shoppingList.createdAt,
            updatedAt: shoppingList.updatedAt,
          ),
        )
        .toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<void> saveNotes(List<Note> notes) async {
    final document = await _storage.loadDocument();
    await _storage.saveDocument(
      StorageDocument(
        version: document.version,
        recipes: document.recipes,
        shoppingLists: notes
            .map(
              (note) => ShoppingList(
                id: note.id,
                title: note.title,
                content: note.content,
                listItems: note.listItems,
                selectedRecipes: note.selectedRecipes,
                isChecklist: note.isChecklist,
                createdAt: note.createdAt,
                updatedAt: note.updatedAt,
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> addNote(Note note) async {
    final notes = await loadNotes();
    notes.add(note);
    await saveNotes(notes);
  }

  Future<void> updateNote(Note note) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      notes[index] = note;
      await saveNotes(notes);
    }
  }

  Future<void> deleteNote(String id) async {
    final notes = await loadNotes();
    notes.removeWhere((n) => n.id == id);
    await saveNotes(notes);
  }
}

class RecipeService {
  RecipeService({StorageService? storage}) : _storage = storage ?? StorageService();

  final StorageService _storage;

  Recipe _buildDefaultRecipe() {
    return Recipe(
      id: 'default-standaard',
      name: 'Standaard',
      items: [
        RecipeItem(
          id: 'default-standaard-kwark-r',
          name: 'Kwark R',
          quantity: '2',
        ),
        RecipeItem(
          id: 'default-standaard-kwark-c',
          name: 'Kwark C',
          quantity: '1',
        ),
        RecipeItem(id: 'default-standaard-kaas', name: 'Kaas', quantity: '1'),
        RecipeItem(id: 'default-standaard-cola', name: 'Cola', quantity: 'X'),
        RecipeItem(id: 'default-standaard-fanta', name: 'Fanta', quantity: 'X'),
      ],
      createdAt: DateTime(2024, 1, 1),
    );
  }

  Future<void> initialize() async {
    await _storage.initialize();
  }

  Future<List<Recipe>> loadRecipes() async {
    final document = await _storage.loadDocument();
    // Return a mutable copy so callers can sort or modify safely.
    return List<Recipe>.from(document.recipes);
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final document = await _storage.loadDocument();
    await _storage.saveDocument(
      StorageDocument(
        version: document.version,
        recipes: recipes,
        shoppingLists: document.shoppingLists,
      ),
    );
  }

  Future<void> addRecipe(Recipe recipe) async {
    final recipes = await loadRecipes();
    recipes.add(recipe);
    await saveRecipes(recipes);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final recipes = await loadRecipes();
    final index = recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      recipes[index] = recipe;
      await saveRecipes(recipes);
    }
  }

  Future<void> deleteRecipe(String id) async {
    final recipes = await loadRecipes();
    recipes.removeWhere((r) => r.id == id);
    await saveRecipes(recipes);
  }
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes & Recipes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF1E40AF),
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
        ),
      ),
      home: const NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  late NotesService _notesService;
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _notesService = NotesService();
    _loadNotes();

    _refreshTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _refreshNotes();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    await _notesService.initialize();
    final notes = await _notesService.loadNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _isLoading = false;
    });
  }

  Future<void> _refreshNotes() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadNotes();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditNotePage()),
    );

    if (result != null && result is Note) {
      await _notesService.addNote(result);
      await _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added successfully')),
        );
      }
    }
  }

  void _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditNotePage(note: note)),
    );

    if (result != null && result is Note) {
      await _notesService.updateNote(result);
      await _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note updated successfully')),
        );
      }
    }
  }

  void _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _notesService.deleteNote(note.id);
      await _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes & Recipes'),
        elevation: 2,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _refreshNotes,
            tooltip: 'Refresh notes',
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipesPage()),
              );
            },
            tooltip: 'Manage Recipes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshNotes,
              child: _notes.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.note_outlined,
                                    size: 64,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No notes yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to create your first note',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _notes.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              note.title.isEmpty ? 'Untitled' : note.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                if (note.isChecklist)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.check_box,
                                            size: 16,
                                            color: const Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${note.listItems.where((item) => item.isChecked).length}/${note.listItems.length} completed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF2563EB),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  )
                                else
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy - hh:mm a',
                                  ).format(note.updatedAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _editNote(note),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editNote(note);
                                } else if (value == 'delete') {
                                  _deleteNote(note);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({super.key, this.note});

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _listItemController;
  late List<ListItem> _listItems;
  late List<String> _selectedRecipeNames;
  late bool _isChecklist;
  late RecipeService _recipeService;
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _listItemController = TextEditingController();
    _isChecklist = widget.note?.isChecklist ?? true;
    _listItems = List.from(widget.note?.listItems ?? []);
    _selectedRecipeNames = List.from(widget.note?.selectedRecipes ?? []);
    _recipeService = RecipeService();
    // initialize controllers for existing items
    for (final item in _listItems) {
      _quantityControllers[item.id] = TextEditingController(text: item.quantity);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateSelectedRecipes();
    });
  }

  void _ensureControllerForItem(ListItem item) {
    final existing = _quantityControllers[item.id];
    if (existing == null) {
      _quantityControllers[item.id] = TextEditingController(text: item.quantity);
    } else if (existing.text != item.quantity) {
      existing.text = item.quantity;
    }
  }

  void _removeControllerForId(String id) {
    final c = _quantityControllers.remove(id);
    c?.dispose();
  }

  void _syncQuantityControllers() {
    for (final item in _listItems) {
      _ensureControllerForItem(item);
    }
    final toRemove = _quantityControllers.keys.where((k) => !_listItems.any((i) => i.id == k)).toList();
    for (final id in toRemove) {
      _removeControllerForId(id);
    }
  }

  Future<void> _hydrateSelectedRecipes() async {
    if (_selectedRecipeNames.isEmpty) return;
    await _recipeService.initialize();
    final recipes = await _recipeService.loadRecipes();
    // Batch updates and set state once to avoid multiple rebuilds.
    final updated = List<ListItem>.from(_listItems);
    for (final name in _selectedRecipeNames) {
      final recipe = recipes.firstWhere(
        (r) => r.name.toLowerCase() == name.toLowerCase(),
        orElse: () => Recipe(id: '', name: '', items: [], createdAt: DateTime.now()),
      );
      if (recipe.id.isEmpty) continue;
      for (final recipeItem in recipe.items) {
        final merged = mergeListItems(updated, recipeItem.name, recipeItem.quantity);
        updated
          ..clear()
          ..addAll(merged);
      }
    }

    if (!mounted) return;
    setState(() {
      _listItems = updated;
    });
    // Ensure controllers exist for any newly added/merged items
    _syncQuantityControllers();
  }

  List<ListItem> _getSortedListItems() {
    // Preserve the user-defined order to allow reordering.
    return _listItems;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _listItemController.dispose();
    for (final c in _quantityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _removeListItem(int index) {
    setState(() {
      final removed = _listItems.removeAt(index);
      _removeControllerForId(removed.id);
    });
  }

  void _addItemToList(String text, String quantity) {
    setState(() {
      _listItems = mergeListItems(_listItems, text, quantity);
      _listItemController.clear();
      _syncQuantityControllers();
    });
  }

  void _toggleListItem(int index) {
    setState(() {
      final currently = _listItems[index];
      // Toggle checked state
      currently.isChecked = !currently.isChecked;

      // If item was just checked, move it to the bottom of the list
      if (currently.isChecked) {
        // Remove from current position and append to end
        final moved = _listItems.removeAt(index);
        _listItems.add(moved);
        // Keep quantity controllers in sync with new ordering
        _syncQuantityControllers();
      }
    });
  }

  Future<void> _loadRecipe() async {
    final recipeService = RecipeService();
    await recipeService.initialize();
    final recipes = await recipeService.loadRecipes();

    if (!mounted) return;

    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recipes available. Create one first!'),
        ),
      );
      return;
    }

    final selectedRecipeIds = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add recipes'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return CheckboxListTile(
                      value: selectedRecipeIds.contains(recipe.id),
                      title: Text(recipe.name),
                      subtitle: Text('${recipe.items.length} items'),
                      onChanged: (selected) {
                        setDialogState(() {
                          if (selected ?? false) {
                            selectedRecipeIds.add(recipe.id);
                          } else {
                            selectedRecipeIds.remove(recipe.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRecipeIds.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed ?? false) {
      setState(() {
        for (final recipeId in selectedRecipeIds) {
          final recipe = recipes.firstWhere((recipe) => recipe.id == recipeId);
          if (_selectedRecipeNames.contains(recipe.name)) {
            continue;
          }

          _selectedRecipeNames.add(recipe.name);
          for (final recipeItem in recipe.items) {
            _listItems = mergeListItems(
              _listItems,
              recipeItem.name,
              recipeItem.quantity,
            );
          }
        }
      });
      // Ensure controllers exist for any newly added items from recipes
      _syncQuantityControllers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${selectedRecipeIds.length} recipe(s)'),
          ),
        );
      }
    }
  }

  void _saveNote() {
    if (_titleController.text.isEmpty &&
        _contentController.text.isEmpty &&
        _listItems.isEmpty &&
        _selectedRecipeNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title or add recipes/items'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      content: _contentController.text,
      listItems: _listItems,
      selectedRecipes: _selectedRecipeNames,
      isChecklist: _isChecklist,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, note);
  }

  void _handleBackButton() {
    // Auto-save if there's any content
    if (_titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _listItems.isNotEmpty ||
        _selectedRecipeNames.isNotEmpty) {
      _saveNote();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackButton,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLines: null,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose recipes and add any extra items you need.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: const [Tab(text: 'Items'), Tab(text: 'Selected Recipes')],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildChecklistView(),
                          _buildSelectedRecipesView(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistView() {
    final sortedItems = _getSortedListItems();
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadRecipe,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Add recipes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add extra item'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: sortedItems.isEmpty
              ? Center(
                  child: Text(
                    'No items yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
                : ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _listItems.removeAt(oldIndex);
                      _listItems.insert(newIndex, item);
                    });
                    // Keep controllers in sync with the moved items
                    _syncQuantityControllers();
                  },
                  // Disable the default right-side drag handles because we
                  // provide a left-side `ReorderableDragStartListener`.
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: List.generate(
                    sortedItems.length,
                    (index) {
                      final item = sortedItems[index];
                      final originalIndex = index;
                      return Card(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: item.isChecked ? Colors.grey[100] : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: item.isChecked,
                                onChanged: (_) => _toggleListItem(originalIndex),
                                activeColor: const Color(0xFF2563EB),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.text,
                                      style: TextStyle(
                                        decoration: item.isChecked
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: item.isChecked ? Colors.grey : Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (item.quantity.isNotEmpty)
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _quantityControllers[item.id],
                                  decoration: InputDecoration(
                                    hintText: 'Qty',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _listItems[originalIndex].quantity = value;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _removeListItem(originalIndex),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSelectedRecipesView() {
    if (_selectedRecipeNames.isEmpty) {
      return Center(
        child: Text(
          'No selected recipes',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              Text(
                'Selected recipes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedRecipeNames
                .map(
                  (name) => Chip(
                    label: Text(name),
                    backgroundColor: const Color(0xFFDBEAFE),
                    labelStyle: const TextStyle(color: Color(0xFF1D4ED8)),
                    onDeleted: () {
                      setState(() {
                        _selectedRecipeNames.remove(name);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add extra item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _listItemController,
              decoration: const InputDecoration(
                hintText: 'Item name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                hintText: 'Quantity (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_listItemController.text.isNotEmpty) {
                _addItemToList(
                  _listItemController.text,
                  quantityController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// Recipes Management Page
class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  late RecipeService _recipeService;
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _recipeService = RecipeService();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      await _recipeService.initialize();
      final recipes = await _recipeService.loadRecipes();
      setState(() {
        _recipes = List<Recipe>.from(recipes);
        _recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e, st) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipes: $e')),
        );
      }
      // print to console for remote debugging
      // ignore: avoid_print
      print('Error loading recipes: $e\n$st');
    }
  }

  void _addRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditRecipePage()),
    );

    if (result != null && result is Recipe) {
      try {
        await _recipeService.addRecipe(result);
        await _loadRecipes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add recipe: $e')),
          );
        }
      }
      if (mounted) {
      }
    }
  }

  void _editRecipe(Recipe recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecipePage(recipe: recipe),
      ),
    );

    if (result != null && result is Recipe) {
      try {
        await _recipeService.updateRecipe(result);
        await _loadRecipes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update recipe: $e')),
          );
        }
      }
    }
  }

  void _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _recipeService.deleteRecipe(recipe.id);
        await _loadRecipes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete recipe: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Recipes'), elevation: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recipes yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first recipe',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _recipes.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '${recipe.items.length} items',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          ).format(recipe.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _editRecipe(recipe),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editRecipe(recipe);
                        } else if (value == 'delete') {
                          _deleteRecipe(recipe);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecipe,
        tooltip: 'Add Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Add/Edit Recipe Page
class AddEditRecipePage extends StatefulWidget {
  final Recipe? recipe;

  const AddEditRecipePage({super.key, this.recipe});

  @override
  State<AddEditRecipePage> createState() => _AddEditRecipePageState();
}

class _AddEditRecipePageState extends State<AddEditRecipePage> {
  late TextEditingController _nameController;
  late TextEditingController _itemController;
  late TextEditingController _quantityController;
  late List<RecipeItem> _items;
  late FocusNode _quantityFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _itemController = TextEditingController();
    _quantityController = TextEditingController();
    _quantityFocusNode = FocusNode();
    _items = List.from(widget.recipe?.items ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemController.dispose();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _addItem(String text, String quantity) {
    if (text.isEmpty) return;
    setState(() {
      _items.add(
        RecipeItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: text,
          quantity: quantity,
        ),
      );
      _itemController.clear();
      _quantityController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _handleBackButton() {
    // Auto-save if there's content
    if (_nameController.text.isNotEmpty && _items.isNotEmpty) {
      _saveRecipe();
    } else {
      Navigator.pop(context);
    }
  }

  void _saveRecipe() {
    if (_nameController.text.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recipe name and at least one item'),
        ),
      );
      return;
    }

    final recipe = Recipe(
      id: widget.recipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      items: _items,
      createdAt: widget.recipe?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, recipe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'New Recipe' : 'Edit Recipe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackButton,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveRecipe),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Items (${_items.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                if (item.quantity.isNotEmpty)
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Item name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) {
                      _quantityFocusNode.requestFocus();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) {
                      _addItem(_itemController.text, _quantityController.text);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _addItem(_itemController.text, _quantityController.text),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
