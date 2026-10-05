import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imagohub/main.dart';
import 'package:imagohub/state/app_state.dart';
import 'package:imagohub/models/search_filters.dart';
import 'package:imagohub/ui/widgets.dart';
import 'package:imagohub/ui/screens/search_screen.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await fonts.load();
  });

  Future<void> setup(
    WidgetTester tester,
    AppState state, {
    Size size = const Size(390, 844),
    GlobalKey? boundary,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ImagoHubApp(state: state),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(LabeledField, label),
    matching: find.byType(TextFormField),
  );

  testWidgets(
    'Search, filters, results, photo details and back navigation work',
    (tester) async {
      final state = (await tester.runAsync(() => testState()))!;
      await setup(tester, state);
      await tester.tap(find.byTooltip('Buscar imagens'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'natureza');
      await tester.tap(find.text('3:4'));
      await tester.enterText(find.byType(TextFormField).at(1), '1200');
      await tester.enterText(find.byType(TextFormField).at(2), '1600');
      await tester.enterText(find.byType(TextFormField).at(3), 'verde');
      await tester.ensureVisible(
        find.widgetWithText(ImagoButton, 'Buscar imagens'),
      );
      await tester.tap(find.widgetWithText(ImagoButton, 'Buscar imagens'));
      await tester.pumpAndSettle();
      expect(state.page, AppPage.results);
      expect(find.text('Natureza'), findsOneWidget);
      expect(find.text('1200 × 1600'), findsOneWidget);
      await tester.tap(find.byType(PhotoCard).first);
      await tester.pumpAndSettle();
      expect(state.page, AppPage.detail);
      expect(find.text('Luz entre as árvores'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(state.page, AppPage.results);
      expect(tester.takeException(), isNull);
      state.dispose();
    },
  );

  testWidgets(
    'Create a folder, select images, add them and remove a selection',
    (tester) async {
      final state = (await tester.runAsync(() => testState()))!;
      await setup(tester, state);
      await tester.tap(find.byTooltip('Minhas pastas'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ImagoButton, 'Nova pasta'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Meu projeto');
      await tester.tap(find.widgetWithText(ImagoButton, 'Criar pasta'));
      await tester.pumpAndSettle();
      expect(state.folders.length, 4);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Meu projeto'));
      await tester.tap(find.text('Meu projeto'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ImagoButton, 'Adicionar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PhotoCard).at(0));
      await tester.tap(find.byType(PhotoCard).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ImagoButton, 'Adicionar (2)'));
      await tester.pumpAndSettle();
      expect(state.currentFolder!.photoIds.length, 2);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PhotoCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ImagoButton, 'Remover da pasta'));
      await tester.pumpAndSettle();
      expect(state.currentFolder!.photoIds.length, 1);
      expect(tester.takeException(), isNull);
      state.dispose();
    },
  );

  testWidgets(
    'Registration opens the gallery; logout requires a valid login again',
    (tester) async {
      final state = (await tester.runAsync(
        () => testState(authenticated: false),
      ))!;
      state.navigate(AppPage.register);
      await setup(tester, state);
      await tester.enterText(field('Nome completo'), 'Victor Bonissoni');
      await tester.enterText(field('Nome de usuário'), 'Victor ♥ fotógrafo');
      await tester.enterText(field('E-mail'), 'victor@example.com');
      await tester.enterText(field('Senha'), 'password123');
      await tester.enterText(field('Confirmar senha'), 'different');
      await tester.ensureVisible(
        find.widgetWithText(ImagoButton, 'Criar conta'),
      );
      await tester.tap(find.widgetWithText(ImagoButton, 'Criar conta'));
      await tester.pumpAndSettle();
      expect(find.text('As senhas devem ser iguais.'), findsWidgets);
      expect(state.page, AppPage.register);
      await tester.enterText(field('Confirmar senha'), 'password123');
      await tester.ensureVisible(
        find.widgetWithText(ImagoButton, 'Criar conta'),
      );
      await tester.tap(find.widgetWithText(ImagoButton, 'Criar conta'));
      await tester.pumpAndSettle();
      expect(state.page, AppPage.discover);
      expect(state.isAuthenticated, true);
      expect(state.profile.username, 'Victor ♥ fotógrafo');
      await state.logout();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(state.page, AppPage.login);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'victor@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.tap(find.widgetWithText(ImagoButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(ImagoButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(state.page, AppPage.discover);
      expect(state.user?['email'], 'victor@example.com');
      expect(tester.takeException(), isNull);
      state.dispose();
    },
  );

  testWidgets('A rejected short password can be erased and corrected', (
    tester,
  ) async {
    final state = (await tester.runAsync(
      () => testState(authenticated: false),
    ))!;
    state.navigate(AppPage.register);
    await setup(tester, state);
    await tester.enterText(field('Nome completo'), 'Victor Bonissoni');
    await tester.enterText(field('Nome de usuário'), 'V');
    await tester.enterText(field('E-mail'), 'victor@example.com');
    await tester.enterText(field('Senha'), 'short');
    await tester.enterText(field('Confirmar senha'), 'short');
    await tester.ensureVisible(find.widgetWithText(ImagoButton, 'Criar conta'));
    await tester.tap(find.widgetWithText(ImagoButton, 'Criar conta'));
    await tester.pumpAndSettle();
    expect(state.page, AppPage.register);
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
    await tester.ensureVisible(field('Senha'));
    await tester.tap(find.byTooltip('Limpar senha'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(field('Senha')).controller!.text,
      isEmpty,
    );
    await tester.enterText(field('Senha'), 'corrected123');
    await tester.enterText(field('Confirmar senha'), 'corrected123');
    await tester.ensureVisible(find.widgetWithText(ImagoButton, 'Criar conta'));
    await tester.tap(find.widgetWithText(ImagoButton, 'Criar conta'));
    await tester.pumpAndSettle();
    expect(state.page, AppPage.discover);
    expect(state.profile.username, 'V');
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets('Search starts blank; picking and typing colors update the dot', (
    tester,
  ) async {
    final state = (await tester.runAsync(() => testState()))!;
    state.navigate(AppPage.search);
    await setup(tester, state);
    for (final label in [
      'O que você quer encontrar?',
      'Largura',
      'Altura',
      'Cor predominante',
    ]) {
      expect(
        tester.widget<TextFormField>(field(label)).controller!.text,
        isEmpty,
      );
    }
    await tester.ensureVisible(field('Cor predominante'));
    await tester.tap(find.byTooltip('Selecionar cor'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Amarelo'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(field('Cor predominante')).controller!.text,
      'amarelo',
    );
    expect(
      tester
          .widget<SearchColorDot>(
            find.byKey(const ValueKey('selected-search-color')),
          )
          .option!
          .apiValue,
      'yellow',
    );
    await tester.enterText(field('Cor predominante'), 'azul');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SearchColorDot>(
            find.byKey(const ValueKey('selected-search-color')),
          )
          .option!
          .apiValue,
      'blue',
    );
    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    for (final label in [
      'O que você quer encontrar?',
      'Largura',
      'Altura',
      'Cor predominante',
    ]) {
      expect(
        tester.widget<TextFormField>(field(label)).controller!.text,
        isEmpty,
      );
    }
    state.navigate(AppPage.discover);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carros'));
    await tester.pumpAndSettle();
    expect(state.page, AppPage.results);
    expect(state.filters.query, 'carros');
    expect(state.filters.color, isEmpty);
    expect(state.filters.width, isNull);
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets('No gallery or profile is accessible before signing in', (
    tester,
  ) async {
    final state = (await tester.runAsync(
      () => testState(authenticated: false),
    ))!;
    // Even a stale private route must render the login, never the profile.
    state.page = AppPage.settings;
    await setup(tester, state);
    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(find.text('Perfil'), findsNothing);
    expect(find.byTooltip('Configurações'), findsNothing);
    expect(find.byTooltip('Voltar à galeria'), findsNothing);
    expect(find.byTooltip('Abrir busca'), findsNothing);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Buscar imagens'), findsNothing);
    await tester.tap(find.widgetWithText(ImagoButton, 'Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Crie sua conta'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(state.page, AppPage.login);
    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets(
      'All pages fit a ${width.toInt()}px viewport without overflow',
      (tester) async {
        final state = (await tester.runAsync(() => testState()))!;
        await setup(tester, state, size: Size(width, 900));
        for (final page in [
          AppPage.discover,
          AppPage.search,
          AppPage.results,
          AppPage.favorites,
          AppPage.folders,
          AppPage.settings,
          AppPage.login,
          AppPage.register,
        ]) {
          state.navigate(page);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$page at $width');
        }
        state.openPhoto(state.reference[4]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        state.openFolder(state.folders.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        state.dispose();
      },
    );
  }

  testWidgets('Capture mobile and desktop views of the actual Flutter UI', (
    tester,
  ) async {
    final state = (await tester.runAsync(() => testState()))!;
    final boundary = GlobalKey();
    await setup(tester, state, boundary: boundary);
    final directory = Directory('verification/rendered')
      ..createSync(recursive: true);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${directory.path}/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final item in [
      (AppPage.discover, 'mobile-01-descubra'),
      (AppPage.search, 'mobile-02-busca'),
      (AppPage.favorites, 'mobile-05-favoritos'),
      (AppPage.folders, 'mobile-06-pastas'),
      (AppPage.settings, 'mobile-09-configuracoes'),
      (AppPage.login, 'mobile-10-login'),
      (AppPage.register, 'mobile-11-cadastro'),
    ]) {
      state.navigate(item.$1);
      await capture(item.$2);
    }
    await state.search(
      const SearchFilters(
        query: 'natureza',
        format: '3:4',
        width: 1200,
        height: 1600,
        color: 'verde',
      ),
    );
    await capture('mobile-03-resultados');
    state.openPhoto(state.reference[4]);
    await capture('mobile-04-detalhes');
    state.openFolder(state.folders.first);
    await capture('mobile-07-pasta-aberta');
    state.navigate(AppPage.folders);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ImagoButton, 'Nova pasta'));
    await capture('mobile-08-nova-pasta');
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    state.navigate(AppPage.discover);
    tester.view.physicalSize = const Size(1440, 900);
    await capture('desktop-galeria');
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}
