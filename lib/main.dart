import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const NotesApp());
}

// List Item Model with Quantity
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isChecked': isChecked,
    'quantity': quantity,
  };

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
    id: json['id'],
    text: json['text'],
    isChecked: json['isChecked'] ?? false,
    quantity: json['quantity'] ?? '',
  );
}

// Recipe Item Model with Quantity
class RecipeItem {
  final String id;
  final String name;
  String quantity;

  RecipeItem({
    required this.id,
    required this.name,
    this.quantity = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
  };

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
    id: json['id'],
    name: json['name'],
    quantity: json['quantity'] ?? '',
  );
}

// Recipe Model (template for notes with quantities)
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
    id: json['id'],
    name: json['name'],
    items: (json['items'] as List<dynamic>?)
        ?.map((item) => RecipeItem.fromJson(item))
        .toList() ?? [],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

// Note Model
class Note {
  final String id;
  final String title;
  final String content;
  final List<ListItem> listItems;
  final List<String> selectedRecipes;
  final bool isChecklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
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

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'] ?? '',
    listItems: (json['listItems'] as List<dynamic>?)
        ?.map((item) => ListItem.fromJson(item))
        .toList() ?? [],
    selectedRecipes: (json['selectedRecipes'] as List<dynamic>?)
        ?.map((item) => item.toString())
        .toList() ?? [],
    isChecklist: json['isChecklist'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

// Notes Service
class NotesService {
  static const String _storageKey = 'notes_list';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Note>> loadNotes() async {
    final String? notesJson = _prefs.getString(_storageKey);
    if (notesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(notesJson);
    return decoded.map((json) => Note.fromJson(json)).toList();
  }

  Future<void> saveNotes(List<Note> notes) async {
    final String encoded = jsonEncode(
      notes.map((note) => note.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, encoded);
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

// Recipe Service
class RecipeService {
  static const String _storageKey = 'recipes_list';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Recipe>> loadRecipes() async {
    final String? recipesJson = _prefs.getString(_storageKey);
    if (recipesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(recipesJson);
    return decoded.map((json) => Recipe.fromJson(json)).toList();
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final String encoded = jsonEncode(
      recipes.map((recipe) => recipe.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, encoded);
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

  @override
  void initState() {
    super.initState();
    _notesService = NotesService();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    await _notesService.initialize();
    final notes = await _notesService.loadNotes();
    setState(() {
      _notes = notes;
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _isLoading = false;
    });
  }

  void _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditNotePage(),
      ),
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
      MaterialPageRoute(
        builder: (context) => AddEditNotePage(note: note),
      ),
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
          : _notes.isEmpty
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                ]
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
                              DateFormat('MMM dd, yyyy - hh:mm a').format(note.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _editNote(note),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () => _editNote(note),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () => _deleteNote(note),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _listItemController = TextEditingController();
    _isChecklist = widget.note?.isChecklist ?? true;
    _listItems = List.from(widget.note?.listItems ?? []);
    _selectedRecipeNames = List.from(widget.note?.selectedRecipes ?? []);
  }

  List<ListItem> _getSortedListItems() {
    final unchecked = _listItems.where((item) => !item.isChecked).toList();
    final checked = _listItems.where((item) => item.isChecked).toList();
    return [...unchecked, ...checked];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _listItemController.dispose();
    super.dispose();
  }

  void _removeListItem(int index) {
    setState(() {
      _listItems.removeAt(index);
    });
  }

  void _toggleListItem(int index) {
    setState(() {
      _listItems[index].isChecked = !_listItems[index].isChecked;
    });
  }

  Future<void> _loadRecipe() async {
    final recipeService = RecipeService();
    await recipeService.initialize();
    final recipes = await recipeService.loadRecipes();

    if (!mounted) return;

    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipes available. Create one first!')),
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
            _listItems.add(ListItem(
              id: '${DateTime.now().millisecondsSinceEpoch}-${recipeItem.id}',
              text: recipeItem.name,
              quantity: recipeItem.quantity,
            ));
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${selectedRecipeIds.length} recipe(s)')),
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
        const SnackBar(content: Text('Please enter a title or add recipes/items')),
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
        _listItems.isNotEmpty) {
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
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildChecklistView(),
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
              : ListView.builder(
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    final item = sortedItems[index];
                    final originalIndex = _listItems.indexOf(item);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: item.isChecked ? Colors.grey[100] : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
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
                                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
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
                                controller: TextEditingController(text: item.quantity),
                                decoration: InputDecoration(
                                  hintText: 'Qty',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        const SizedBox(height: 12),
        if (_selectedRecipeNames.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
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
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
      ],
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
                setState(() {
                  _listItems.add(ListItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    text: _listItemController.text,
                    quantity: quantityController.text,
                  ));
                  _listItemController.clear();
                });
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
    await _recipeService.initialize();
    final recipes = await _recipeService.loadRecipes();
    setState(() {
      _recipes = recipes;
      _recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
    });
  }

  void _addRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditRecipePage(),
      ),
    );

    if (result != null && result is Recipe) {
      await _recipeService.addRecipe(result);
      await _loadRecipes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe created successfully')),
        );
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
      await _recipeService.updateRecipe(result);
      await _loadRecipes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated successfully')),
        );
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
      await _recipeService.deleteRecipe(recipe.id);
      await _loadRecipes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Recipes'),
        elevation: 2,
      ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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
                              DateFormat('MMM dd, yyyy - hh:mm a').format(recipe.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _editRecipe(recipe),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () => _editRecipe(recipe),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () => _deleteRecipe(recipe),
                            ),
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
      _items.add(RecipeItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: text,
        quantity: quantity,
      ));
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
        const SnackBar(content: Text('Please enter a recipe name and at least one item')),
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
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRecipe,
          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  onPressed: () => _addItem(_itemController.text, _quantityController.text),
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
