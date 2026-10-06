import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library.dart';
import '../models/photo.dart';
import '../models/search_filters.dart';
import '../services/api_client.dart';

enum AppPage {
  discover,
  search,
  results,
  detail,
  favorites,
  folders,
  folder,
  settings,
  login,
  register,
}

class AppState extends ChangeNotifier {
  final ApiClient api;
  final SharedPreferencesAsync preferences;
  final FlutterSecureStorage secureStorage;
  final bool persistSessions;
  AppState({
    ApiClient? api,
    SharedPreferencesAsync? preferences,
    FlutterSecureStorage? secureStorage,
    this.persistSessions = true,
  }) : api = api ?? ApiClient(),
       preferences = preferences ?? SharedPreferencesAsync(),
       secureStorage = secureStorage ?? const FlutterSecureStorage();

  AppPage page = AppPage.login;
  AppPage previousPage = AppPage.discover;
  final Map<String, Photo> photos = {};
  List<Photo> feed = [];
  List<Photo> results = [];
  Set<String> favorites = {};
  List<PhotoFolder> folders = [];
  List<String> recentSearches = [];
  UserProfile profile = const UserProfile();
  Map<String, dynamic>? user;
  Photo? currentPhoto;
  PhotoFolder? currentFolder;
  SearchFilters filters = const SearchFilters();
  bool initialized = false;
  bool dataSaver = true;
  bool safeSearch = true;
  bool dark = false;
  bool loadingFeed = false;
  bool loadingResults = false;
  String? feedError;
  String? searchError;
  String feedOrder = 'popular';
  int feedPage = 0;
  int searchPage = 0;
  int totalResults = 0;
  int totalPages = 0;
  bool moreFeed = true;
  int _feedGeneration = 0;
  int _searchGeneration = 0;
  List<Photo> reference = [];
  bool get isAuthenticated => user != null;
  String get _namespace => user?['id']?.toString() ?? 'guest';
  String get _libraryKey => 'imagohub.library.v1.$_namespace';
  List<Photo> get savedPhotos =>
      favorites.map((id) => photos[id]).whereType<Photo>().toList();
  List<Photo> folderPhotos(PhotoFolder folder) =>
      folder.photoIds.map((id) => photos[id]).whereType<Photo>().toList();

  Future<void> initialize() async {
    final raw = await rootBundle.loadString(
      'assets/data/reference_photos.json',
    );
    reference = (jsonDecode(raw) as List)
        .map((j) => Photo(Map<String, dynamic>.from(j)))
        .toList();
    for (final p in reference) {
      photos[p.id] = p;
    }
    feed = [
      reference[0],
      reference[6],
      reference[4],
      reference[7],
      reference[5],
      reference[2],
      reference[3],
      reference[1],
    ];
    dataSaver = await preferences.getBool('imagohub.dataSaver') ?? true;
    safeSearch = await preferences.getBool('imagohub.safeSearch') ?? true;
    dark = await preferences.getBool('imagohub.dark') ?? false;
    recentSearches =
        await preferences.getStringList('imagohub.recentSearches') ?? [];
    if (persistSessions) {
      try {
        if (kIsWeb) {
          api.token = await preferences.getString('imagohub.session');
        } else {
          api.token = await secureStorage.read(key: 'imagohub.session');
        }
        if (api.token != null) {
          final data = await api
              .request('/auth/me')
              .timeout(const Duration(seconds: 5));
          user = Map<String, dynamic>.from(data['user']);
        }
      } catch (_) {
        api.token = null;
        user = null;
      }
    }
    await _loadLibrary();
    page = isAuthenticated ? AppPage.discover : AppPage.login;
    initialized = true;
    notifyListeners();
  }

  Future<void> _loadLibrary() async {
    favorites = {};
    folders = [];
    profile = const UserProfile();
    if (!isAuthenticated) return;
    final raw = await preferences.getString(_libraryKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        favorites = Set<String>.from(data['favorites'] ?? []);
        folders = (data['folders'] as List? ?? [])
            .map((j) => PhotoFolder.fromJson(j))
            .toList();
        for (final j in data['photos'] as List? ?? []) {
          final p = Photo(Map<String, dynamic>.from(j));
          photos[p.id] = p;
        }
        profile = UserProfile.fromJson(data['profile'] ?? {});
      } catch (_) {
        /* A corrupt library must not prevent the app from opening. */
      }
    }
    if (user != null) {
      profile = UserProfile(
        name: user!['name'],
        email: user!['email'],
        username: (user!['username'] as String?)?.isNotEmpty == true
            ? user!['username']
            : profile.username,
        bio: profile.bio,
        avatar: profile.avatar,
      );
    }
  }

  Future<void> saveLibrary() async {
    if (!isAuthenticated) return;
    final ids = {...favorites, ...folders.expand((f) => f.photoIds)};
    await preferences.setString(
      _libraryKey,
      jsonEncode({
        'favorites': favorites.toList(),
        'folders': folders.map((f) => f.toJson()).toList(),
        'profile': profile.toJson(),
        'photos': ids
            .map((id) => photos[id]?.data)
            .whereType<Map<String, dynamic>>()
            .toList(),
      }),
    );
  }

  void navigate(AppPage value) {
    if (value == AppPage.search && page != AppPage.results) {
      clearSearchFilters();
    }
    page =
        isAuthenticated || value == AppPage.login || value == AppPage.register
        ? value
        : AppPage.login;
    notifyListeners();
  }

  void openPhoto(Photo photo) {
    if (!isAuthenticated) {
      navigate(AppPage.login);
      return;
    }
    previousPage = page;
    currentPhoto = photo;
    page = AppPage.detail;
    notifyListeners();
  }

  void backFromPhoto() => navigate(previousPage);
  void openFolder(PhotoFolder folder) {
    if (!isAuthenticated) {
      navigate(AppPage.login);
      return;
    }
    currentFolder = folder;
    navigate(AppPage.folder);
  }

  Future<void> loadFeed({bool reset = false, String? order}) async {
    if (!isAuthenticated) return;
    if (loadingFeed && !reset) return;
    if (!moreFeed && !reset) return;
    if (reset) {
      _feedGeneration++;
      feedPage = 0;
      moreFeed = true;
      if (order != null) feedOrder = order;
    }
    final generation = _feedGeneration;
    loadingFeed = true;
    feedError = null;
    notifyListeners();
    try {
      final next = await api.feed(feedPage + 1, feedOrder);
      if (generation != _feedGeneration) return;
      if (reset) feed = [];
      final ids = feed.map((p) => p.id).toSet();
      feed.addAll(next.where((p) => !ids.contains(p.id)));
      for (final p in next) {
        photos[p.id] = p;
      }
      feedPage++;
      moreFeed = next.length == 20;
    } catch (e) {
      if (generation == _feedGeneration) feedError = e.toString();
    } finally {
      if (generation == _feedGeneration) {
        loadingFeed = false;
        notifyListeners();
      }
    }
  }

  Future<void> search(SearchFilters value) async {
    if (!isAuthenticated) {
      navigate(AppPage.login);
      return;
    }
    _searchGeneration++;
    loadingResults = false;
    filters = value.copyWith(safe: safeSearch);
    results = [];
    searchPage = 0;
    totalResults = 0;
    totalPages = 0;
    recentSearches.removeWhere(
      (q) => q.toLowerCase() == value.query.trim().toLowerCase(),
    );
    recentSearches.insert(0, value.query.trim());
    recentSearches = recentSearches.take(6).toList();
    await preferences.setStringList('imagohub.recentSearches', recentSearches);
    page = AppPage.results;
    await loadResults();
  }

  Future<void> searchCategory(String category) =>
      search(SearchFilters(query: category.toLowerCase()));

  void clearSearchFilters() {
    _requireAccount();
    _searchGeneration++;
    filters = const SearchFilters();
    results = [];
    searchPage = 0;
    totalResults = 0;
    totalPages = 0;
    loadingResults = false;
    searchError = null;
    notifyListeners();
  }

  Future<void> loadResults() async {
    if (!isAuthenticated) return;
    if (loadingResults || (searchPage > 0 && searchPage >= totalPages)) return;
    final generation = _searchGeneration;
    loadingResults = true;
    searchError = null;
    notifyListeners();
    try {
      final next = await api.search(filters, searchPage + 1);
      if (generation != _searchGeneration) return;
      final ids = results.map((p) => p.id).toSet();
      results.addAll(next.photos.where((p) => !ids.contains(p.id)));
      for (final p in next.photos) {
        photos[p.id] = p;
      }
      searchPage++;
      totalResults = next.total;
      totalPages = next.pages;
    } catch (e) {
      if (generation == _searchGeneration) searchError = e.toString();
    } finally {
      if (generation == _searchGeneration) {
        loadingResults = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggleFavorite(Photo photo) async {
    _requireAccount();
    photos[photo.id] = photo;
    final added = !favorites.remove(photo.id);
    if (added) favorites.add(photo.id);
    notifyListeners();
    await saveLibrary();
    if (added) await api.trackDownload(photo);
  }

  Future<PhotoFolder> createFolder(String name) async {
    _requireAccount();
    final value = name.trim();
    if (value.isEmpty) throw const ApiException('Digite o nome da pasta.');
    if (folders.any((f) => f.name.toLowerCase() == value.toLowerCase())) {
      throw const ApiException('Já existe uma pasta com esse nome.');
    }
    final folder = PhotoFolder(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: value,
    );
    folders.add(folder);
    notifyListeners();
    await saveLibrary();
    return folder;
  }

  Future<void> renameFolder(PhotoFolder folder, String name) async {
    _requireAccount();
    final value = name.trim();
    if (value.isEmpty || value.length > 80) {
      throw const ApiException('Digite um nome com até 80 caracteres.');
    }
    if (folders.any(
      (f) => f.id != folder.id && f.name.toLowerCase() == value.toLowerCase(),
    )) {
      throw const ApiException('Já existe uma pasta com esse nome.');
    }
    folder.name = value;
    notifyListeners();
    await saveLibrary();
  }

  Future<void> deleteFolder(PhotoFolder folder) async {
    _requireAccount();
    folders.removeWhere((f) => f.id == folder.id);
    currentFolder = null;
    page = AppPage.folders;
    notifyListeners();
    await saveLibrary();
  }

  Future<void> addToFolder(PhotoFolder folder, Iterable<Photo> values) async {
    _requireAccount();
    final added = values.where((p) => !folder.photoIds.contains(p.id)).toList();
    for (final p in added) {
      photos[p.id] = p;
      folder.photoIds.add(p.id);
    }
    notifyListeners();
    await saveLibrary();
    String? error;
    for (final p in added) {
      try {
        await api.trackDownload(p);
      } catch (e) {
        error = e.toString();
      }
    }
    if (error != null) {
      throw ApiException('Fotos salvas. O registro na Unsplash falhou: $error');
    }
  }

  Future<void> removeFromFolder(PhotoFolder folder, Set<String> ids) async {
    _requireAccount();
    folder.photoIds.removeWhere(ids.contains);
    notifyListeners();
    await saveLibrary();
  }

  Future<void> setPreference(String key, bool value) async {
    _requireAccount();
    if (key == 'dark') dark = value;
    if (key == 'dataSaver') dataSaver = value;
    if (key == 'safeSearch') safeSearch = value;
    await preferences.setBool('imagohub.$key', value);
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile value) async {
    _requireAccount();
    final accountId = user!['id'];
    final sessionToken = api.token;
    if (user != null) {
      final result = await api.request(
        '/auth/profile',
        method: 'PATCH',
        body: {
          'name': value.name,
          'email': value.email,
          'username': value.username,
        },
      );
      if (!isAuthenticated ||
          user!['id'] != accountId ||
          api.token != sessionToken) {
        return;
      }
      user = Map<String, dynamic>.from(result['user']);
    }
    profile = value;
    await saveLibrary();
    notifyListeners();
  }

  Future<void> login(String email, String password, bool remember) async {
    final data = await api.request(
      '/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password, 'remember': remember},
    );
    api.token = data['token'];
    user = Map<String, dynamic>.from(data['user']);
    if (persistSessions) {
      if (remember) {
        if (kIsWeb) {
          await preferences.setString('imagohub.session', api.token ?? '');
        } else {
          await secureStorage.write(key: 'imagohub.session', value: api.token);
        }
      } else {
        if (kIsWeb) {
          await preferences.remove('imagohub.session');
        } else {
          await secureStorage.delete(key: 'imagohub.session');
        }
      }
    }
    await _loadLibrary();
    page = AppPage.discover;
    notifyListeners();
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String? username,
  }) async {
    await api.request(
      '/auth/register',
      method: 'POST',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'username': ?username,
      },
    );
    try {
      await login(email, password, false);
    } catch (e) {
      throw ApiException(
        'Sua conta foi criada. Use Entrar para acessar com seu e-mail e senha. $e',
      );
    }
  }

  Future<void> logout() async {
    try {
      await api.request('/auth/logout', method: 'POST', body: {});
    } catch (_) {}
    api.token = null;
    user = null;
    currentPhoto = null;
    currentFolder = null;
    previousPage = AppPage.discover;
    _searchGeneration++;
    _feedGeneration++;
    results = [];
    filters = const SearchFilters();
    searchPage = 0;
    totalResults = 0;
    totalPages = 0;
    loadingResults = false;
    loadingFeed = false;
    feedError = null;
    searchError = null;
    if (persistSessions) {
      if (kIsWeb) {
        await preferences.remove('imagohub.session');
      } else {
        await secureStorage.delete(key: 'imagohub.session');
      }
    }
    await _loadLibrary();
    page = AppPage.login;
    notifyListeners();
  }

  void _requireAccount() {
    if (!isAuthenticated) {
      throw const ApiException('Entre na sua conta para continuar.', 401);
    }
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}
