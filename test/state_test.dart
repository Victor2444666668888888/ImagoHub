import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:imagohub/models/search_filters.dart';
import 'package:imagohub/models/library.dart';
import 'package:imagohub/state/app_state.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Search sends complete filters on every page; image transformations preserve ixid',
    () async {
      final calls = <Uri>[];
      final state = await testState(
        respond: (r) async {
          calls.add(r.url);
          return http.Response(
            jsonEncode({'results': [], 'total': 40, 'total_pages': 2}),
            200,
          );
        },
      );
      await state.search(
        const SearchFilters(
          query: 'woman with balloon',
          format: '3:4',
          width: 1200,
          height: 1600,
          color: 'verde',
        ),
      );
      await state.loadResults();
      expect(calls.length, 2);
      for (final call in calls) {
        expect(call.queryParameters['query'], 'woman with balloon');
        expect(call.queryParameters['orientation'], 'portrait');
        expect(call.queryParameters['color'], 'green');
        expect(call.queryParameters['content_filter'], 'high');
        expect(call.queryParameters.containsKey('width'), false);
      }
      expect(calls.last.queryParameters['page'], '2');
      final photo = state.reference.first;
      final uri = Uri.parse(photo.imageUrl(width: 1200, height: 1600));
      expect(
        uri.queryParameters['ixid'],
        Uri.parse(photo.urls['raw']).queryParameters['ixid'],
      );
      expect(uri.queryParameters['w'], '1200');
      expect(uri.queryParameters['h'], '1600');
      expect(uri.queryParameters['fit'], 'crop');
      state.dispose();
    },
  );

  test(
    'Late response from an older search never replaces the new results',
    () async {
      final old = Completer<http.Response>();
      final state = await testState(
        respond: (request) async {
          if (request.url.queryParameters['query'] == 'old') return old.future;
          return http.Response('{"results":[],"total":0,"total_pages":0}', 200);
        },
      );
      final first = state.search(const SearchFilters(query: 'old'));
      await Future<void>.delayed(Duration.zero);
      await state.search(const SearchFilters(query: 'new'));
      old.complete(
        http.Response('{"results":[],"total":999,"total_pages":50}', 200),
      );
      await first;
      expect(state.filters.query, 'new');
      expect(state.totalResults, 0);
      expect(state.loadingResults, false);
      expect(state.searchPage, 1);
      state.dispose();
    },
  );

  test(
    'Folders deduplicate additions; removing a photo keeps its favorite and other folders',
    () async {
      final state = await testState();
      final photo = state.reference.first;
      final folder = await state.createFolder('Meu projeto');
      await state.addToFolder(folder, [photo]);
      await state.addToFolder(folder, [photo]);
      expect(folder.photoIds, [photo.id]);
      await state.removeFromFolder(folder, {photo.id});
      expect(folder.photoIds, isEmpty);
      expect(state.favorites.contains(photo.id), true);
      expect(state.folders.first.photoIds.contains(photo.id), true);
      await expectLater(state.createFolder('MEU PROJETO'), throwsException);
      final reloaded = await testState(clearStorage: false);
      expect(reloaded.folders.last.name, 'Meu projeto');
      expect(reloaded.folders.last.photoIds, isEmpty);
      state.dispose();
      reloaded.dispose();
    },
  );

  test('A local favorite survives an unavailable tracking endpoint', () async {
    final state = await testState(
      respond: (_) async => http.Response('{"error":"Offline"}', 502),
    );
    final photo = state.reference.first;
    await state.toggleFavorite(photo); // Removing is local.
    await expectLater(state.toggleFavorite(photo), throwsException);
    expect(state.favorites.contains(photo.id), true);
    final reloaded = await testState(clearStorage: false);
    expect(reloaded.favorites.contains(photo.id), true);
    state.dispose();
    reloaded.dispose();
  });

  test(
    'Accounts have separate local libraries; logout hides and clears the account',
    () async {
      final state = await testState();
      await state.login('a@example.com', 'password123', false);
      expect(state.favorites, isEmpty);
      expect(state.folders, isEmpty);
      await state.toggleFavorite(state.reference.first);
      await state.createFolder('Conta A');
      await state.logout();
      expect(state.favorites, isEmpty);
      expect(state.folders, isEmpty);
      expect(state.profile.name, isEmpty);
      expect(state.page, AppPage.login);
      await state.login('b@example.com', 'password123', false);
      expect(state.favorites, isEmpty);
      expect(state.folders, isEmpty);
      await state.logout();
      await state.login('a@example.com', 'password123', false);
      expect(state.favorites.length, 1);
      expect(state.folders.single.name, 'Conta A');
      state.dispose();
    },
  );

  test(
    'Authenticated profile and preferences persist across application restarts',
    () async {
      final state = await testState();
      await state.saveProfile(
        const UserProfile(
          name: 'Victor',
          username: '@victor',
          email: 'victor@example.com',
          bio: 'Natureza',
        ),
      );
      await state.setPreference('dark', true);
      await state.setPreference('safeSearch', false);
      await state.setPreference('dataSaver', false);
      final reloaded = await testState(clearStorage: false);
      expect(reloaded.profile.name, 'Victor');
      expect(reloaded.profile.bio, 'Natureza');
      expect(reloaded.dark, true);
      expect(reloaded.safeSearch, false);
      expect(reloaded.dataSaver, false);
      state.dispose();
      reloaded.dispose();
    },
  );

  test('Login is required for private routes and profile changes', () async {
    final state = await testState(authenticated: false);
    expect(state.page, AppPage.login);
    expect(state.isAuthenticated, false);
    expect(state.profile.name, isEmpty);
    expect(state.folders, isEmpty);
    expect(state.favorites, isEmpty);
    for (final route in [
      AppPage.discover,
      AppPage.search,
      AppPage.results,
      AppPage.detail,
      AppPage.favorites,
      AppPage.folders,
      AppPage.folder,
      AppPage.settings,
    ]) {
      state.navigate(route);
      expect(state.page, AppPage.login);
    }
    state.navigate(AppPage.register);
    expect(state.page, AppPage.register);
    state.openPhoto(state.reference.first);
    expect(state.page, AppPage.login);
    await state.search(const SearchFilters(query: 'natureza'));
    expect(state.results, isEmpty);
    await expectLater(
      state.saveProfile(const UserProfile(name: 'Visitor')),
      throwsException,
    );
    await expectLater(state.createFolder('Private'), throwsException);
    expect(
      await state.preferences.getString('imagohub.library.v1.guest'),
      isNull,
    );
    state.dispose();
  });

  test(
    'Registration signs in; failed login keeps the application locked',
    () async {
      final state = await testState(authenticated: false);
      await expectLater(
        state.login('victor@example.com', 'wrongpass', false),
        throwsException,
      );
      expect(state.isAuthenticated, false);
      expect(state.page, AppPage.login);
      await state.register('Victor', 'victor@example.com', 'password123');
      expect(state.isAuthenticated, true);
      expect(state.page, AppPage.discover);
      expect(state.profile.email, 'victor@example.com');
      state.navigate(AppPage.settings);
      expect(state.page, AppPage.settings);
      await state.logout();
      expect(state.isAuthenticated, false);
      expect(state.profile.email, isEmpty);
      state.navigate(AppPage.settings);
      expect(state.page, AppPage.login);
      state.dispose();
    },
  );
}
