import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import 'screens/gallery_screens.dart';
import 'screens/search_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/library_screens.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screens.dart';
import 'theme.dart';
import 'widgets.dart';

class AppShell extends StatelessWidget {
  final AppState state;
  const AppShell({super.key, required this.state});
  AppPage get visiblePage => state.isAuthenticated
      ? state.page
      : state.page == AppPage.register
      ? AppPage.register
      : AppPage.login;
  bool get auth =>
      visiblePage == AppPage.login || visiblePage == AppPage.register;
  bool get back =>
      visiblePage == AppPage.detail || visiblePage == AppPage.folder;
  AppPage get active => switch (visiblePage) {
    AppPage.results => AppPage.search,
    AppPage.detail =>
      state.previousPage == AppPage.results
          ? AppPage.search
          : state.previousPage == AppPage.favorites
          ? AppPage.favorites
          : state.previousPage == AppPage.folder
          ? AppPage.folders
          : AppPage.discover,
    AppPage.folder => AppPage.folders,
    _ => state.page,
  };
  void goBack() {
    if (auth) {
      state.navigate(AppPage.login);
    } else if (state.page == AppPage.detail) {
      state.backFromPhoto();
    } else if (state.page == AppPage.folder) {
      state.navigate(AppPage.folders);
    } else {
      state.navigate(AppPage.discover);
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): goBack,
      if (!auth)
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            state.navigate(AppPage.search),
    },
    child: Focus(
      autofocus: true,
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: ColoredBox(
                  color: ImagoColors.rail,
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Positioned(
                          top: 20,
                          left: 7,
                          child: Tooltip(
                            message: state.user == null
                                ? 'Entrar na conta'
                                : 'Seu perfil',
                            child: Material(
                              color: ImagoColors.brand,
                              borderRadius: BorderRadius.circular(11),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => state.navigate(
                                  state.user == null
                                      ? AppPage.login
                                      : AppPage.settings,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Image.asset(
                                    'assets/brand/imago-logo.png',
                                    width: 34,
                                    height: 34,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!auth)
                          Positioned(
                            top: 100,
                            bottom: 80,
                            left: 5,
                            right: 5,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  for (final item in [
                                    (
                                      AppPage.discover,
                                      'Image',
                                      'Descobrir imagens',
                                    ),
                                    (
                                      AppPage.search,
                                      'Search',
                                      'Buscar imagens',
                                    ),
                                    (AppPage.favorites, 'Star', 'Favoritos'),
                                    (
                                      AppPage.folders,
                                      'Folder',
                                      'Minhas pastas',
                                    ),
                                  ]) ...[
                                    IconAction(
                                      icon: item.$2,
                                      label: item.$3,
                                      color: Colors.white,
                                      background: active == item.$1
                                          ? ImagoColors.brand
                                          : ImagoColors.rail,
                                      onTap: () => state.navigate(item.$1),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        if (!auth)
                          Positioned(
                            bottom: 20,
                            left: 5,
                            child: IconAction(
                              icon: 'Settings',
                              label: 'Configurações',
                              color: Colors.white,
                              background: active == AppPage.settings
                                  ? ImagoColors.brand
                                  : ImagoColors.rail,
                              onTap: () => state.navigate(AppPage.settings),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (back) ...[
                            IconAction(
                              icon: 'ArrowLeft',
                              label: 'Voltar',
                              size: 36,
                              onTap: goBack,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              'ImagoHub',
                              style: TextStyle(
                                fontSize: back ? 19 : 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (!auth)
                            IconAction(
                              icon: 'Search',
                              label: 'Abrir busca',
                              background: softColor(context),
                              color: ImagoColors.brand,
                              onTap: () => state.navigate(AppPage.search),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey(visiblePage),
                        child: switch (visiblePage) {
                          AppPage.discover => DiscoverScreen(state: state),
                          AppPage.search => SearchScreen(state: state),
                          AppPage.results => ResultsScreen(state: state),
                          AppPage.detail => DetailScreen(state: state),
                          AppPage.favorites => SavedPhotosScreen(state: state),
                          AppPage.folders => FoldersScreen(state: state),
                          AppPage.folder => SavedPhotosScreen(
                            state: state,
                            folder: state.currentFolder,
                          ),
                          AppPage.settings => SettingsScreen(state: state),
                          AppPage.login => AuthScreen(state: state),
                          AppPage.register => AuthScreen(
                            state: state,
                            register: true,
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
