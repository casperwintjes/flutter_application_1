import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'ha_api.dart';
import 'models.dart';

class StorageService {
  StorageService({
    SharedPreferences? prefs,
    HaApiService? apiService,
    AuthService? authService,
  })  : _prefs = prefs,
        _apiService = apiService ?? HaApiService(authService: authService ?? AuthService());

  final SharedPreferences? _prefs;
  SharedPreferences? _resolvedPrefs;
  final HaApiService _apiService;

  Future<void> initialize() async {
    _resolvedPrefs ??= _prefs ?? await SharedPreferences.getInstance();
  }

  Future<StorageDocument> loadDocument() async {
    await initialize();

    final remoteDocument = await _loadRemoteDocument();
    if (remoteDocument != null) {
      return remoteDocument;
    }

    final localRaw = _resolvedPrefs?.getString(_storageKey);
    if (localRaw == null || localRaw.isEmpty) {
      return StorageDocument.initial();
    }

    try {
      return StorageDocument.fromJson(jsonDecode(localRaw) as Map<String, dynamic>);
    } catch (_) {
      return StorageDocument.initial();
    }
  }

  Future<void> saveDocument(StorageDocument document) async {
    await initialize();
    final encoded = jsonEncode(document.toJson());
    await _resolvedPrefs?.setString(_storageKey, encoded);

    try {
      await _apiService.saveDocument(document.toJson());
    } catch (_) {
      // Fall back to local storage when the Home Assistant API is unavailable.
    }
  }

  Future<List<Recipe>> loadRecipes() async {
    final document = await loadDocument();
    return document.recipes;
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final document = await loadDocument();
    await saveDocument(
      StorageDocument(
        version: document.version,
        recipes: recipes,
        shoppingLists: document.shoppingLists,
      ),
    );
  }

  Future<List<ShoppingList>> loadShoppingLists() async {
    final document = await loadDocument();
    return document.shoppingLists;
  }

  Future<void> saveShoppingLists(List<ShoppingList> shoppingLists) async {
    final document = await loadDocument();
    await saveDocument(
      StorageDocument(
        version: document.version,
        recipes: document.recipes,
        shoppingLists: shoppingLists,
      ),
    );
  }

  Future<StorageDocument?> _loadRemoteDocument() async {
    try {
      final payload = await _apiService.loadDocument();
      if (payload.isEmpty) {
        return null;
      }
      return StorageDocument.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  static const String _storageKey = 'shopping_storage_document';
}
