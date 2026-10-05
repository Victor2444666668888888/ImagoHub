import 'package:flutter/material.dart';

import '../../models/search_filters.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class DiscoverScreen extends StatelessWidget {
  final AppState state;
  const DiscoverScreen({super.key, required this.state});
  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.depth == 0 &&
          notification.metrics.extentAfter < 300 &&
          notification.metrics.pixels > 0 &&
          state.feedError == null) {
        state.loadFeed();
      }
      return false;
    },
    child: RefreshIndicator(
      onRefresh: () => state.loadFeed(reset: true),
      color: ImagoColors.brand,
      child: SingleChildScrollView(
        key: const PageStorageKey('discover'),
        physics: const AlwaysScrollableScrollPhysics(),
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUA PRÓXIMA INSPIRAÇÃO',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: ImagoColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  'Descubra imagens',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore, favorite e dê vida às suas ideias.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: ImagoColors.muted,
                  ),
                ),
                const SizedBox(height: 22),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChipButton(
                        'Populares',
                        selected: state.feedOrder == 'popular',
                        onTap: () =>
                            state.loadFeed(reset: true, order: 'popular'),
                      ),
                      const SizedBox(width: 8),
                      FilterChipButton(
                        'Mais recentes',
                        selected: state.feedOrder == 'latest',
                        onTap: () =>
                            state.loadFeed(reset: true, order: 'latest'),
                      ),
                      for (final category in suggestedCategories) ...[
                        const SizedBox(width: 8),
                        FilterChipButton(
                          category,
                          onTap: () => state.searchCategory(category),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 980
                        ? 3
                        : constraints.maxWidth > 580
                        ? 2
                        : 1;
                    if (columns == 1) {
                      return Column(
                        children: [
                          for (var i = 0; i < state.feed.length; i++) ...[
                            PhotoCard(
                              state.feed[i],
                              state: state,
                              imageHeight: i == 1 ? 210 : 226,
                            ),
                            const SizedBox(height: 18),
                          ],
                        ],
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.feed.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        mainAxisExtent: 314,
                      ),
                      itemBuilder: (context, i) =>
                          PhotoCard(state.feed[i], state: state),
                    );
                  },
                ),
                if (state.loadingFeed)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (state.feedError != null)
                  InlineError(state.feedError!, retry: () => state.loadFeed()),
                if (state.moreFeed &&
                    !state.loadingFeed &&
                    state.feedError == null)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => state.loadFeed(),
                      icon: const LineIcon(
                        'Plus',
                        size: 16,
                        color: ImagoColors.brand,
                      ),
                      label: const Text('Ver mais imagens'),
                    ),
                  ),
                if (!state.moreFeed)
                  const Center(
                    child: Text(
                      'Você chegou ao fim desta galeria.',
                      style: TextStyle(color: ImagoColors.muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ResultsScreen extends StatelessWidget {
  final AppState state;
  const ResultsScreen({super.key, required this.state});
  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
    onNotification: (n) {
      if (n.depth == 0 &&
          n.metrics.extentAfter < 300 &&
          n.metrics.pixels > 0 &&
          state.searchError == null) {
        state.loadResults();
      }
      return false;
    },
    child: SingleChildScrollView(
      key: PageStorageKey('results-${state.filters.query}'),
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeading(
                state.filters.query.isEmpty
                    ? 'Resultados'
                    : '${state.filters.query[0].toUpperCase()}${state.filters.query.substring(1)}',
                'Imagens para a sua busca',
              ),
              const SizedBox(height: 22),
              Material(
                color: panelColor(context),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => state.navigate(AppPage.search),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const LineIcon(
                          'Search',
                          size: 20,
                          color: ImagoColors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.filters.query,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const LineIcon('SlidersHorizontal', size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (state.filters.format != 'Livre')
                    FilterChipButton(
                      state.filters.format,
                      selected: true,
                      onTap: () => state.navigate(AppPage.search),
                    ),
                  if (state.filters.width != null &&
                      state.filters.height != null)
                    FilterChipButton(
                      '${state.filters.width} × ${state.filters.height}',
                      selected: true,
                      onTap: () => state.navigate(AppPage.search),
                    ),
                  if (state.filters.color.isNotEmpty)
                    FilterChipButton(
                      state.filters.color,
                      selected: true,
                      onTap: () => state.navigate(AppPage.search),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resultados${state.totalResults > 0 ? ' (${state.totalResults})' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.filters.order,
                      isDense: true,
                      icon: const LineIcon(
                        'ChevronDown',
                        size: 14,
                        color: ImagoColors.muted,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: ImagoColors.muted,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'relevant',
                          child: Text('Relevância'),
                        ),
                        DropdownMenuItem(
                          value: 'latest',
                          child: Text('Mais recentes'),
                        ),
                      ],
                      onChanged: state.loadingResults
                          ? null
                          : (order) {
                              if (order != null) {
                                state.search(
                                  state.filters.copyWith(order: order),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 950
                      ? 5
                      : constraints.maxWidth > 700
                      ? 4
                      : constraints.maxWidth > 470
                      ? 3
                      : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  final imageHeight = state.filters.ratio == null
                      ? width * 194 / 146
                      : width / state.filters.ratio!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.results.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 12,
                      mainAxisExtent: imageHeight + 70,
                    ),
                    itemBuilder: (context, i) => PhotoCard(
                      state.results[i],
                      state: state,
                      compact: true,
                      imageHeight: imageHeight,
                      imageRatio: state.filters.ratio,
                    ),
                  );
                },
              ),
              if (state.loadingResults)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (state.searchError != null)
                InlineError(
                  state.searchError!,
                  retry: () => state.loadResults(),
                ),
              if (!state.loadingResults &&
                  state.searchError == null &&
                  state.results.isEmpty)
                EmptyState(
                  icon: 'Search',
                  title: 'Nenhuma imagem encontrada',
                  message: 'Experimente outra palavra ou ajuste os filtros.',
                  action: ImagoButton(
                    'Editar busca',
                    icon: 'SlidersHorizontal',
                    onPressed: () => state.navigate(AppPage.search),
                  ),
                ),
              if (!state.loadingResults &&
                  state.searchPage < state.totalPages &&
                  state.searchError == null)
                Center(
                  child: TextButton(
                    onPressed: () => state.loadResults(),
                    child: const Text('Carregar mais imagens'),
                  ),
                ),
              if (state.results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => openCredit(context, 'https://unsplash.com'),
                      child: const Text(
                        'Fotografias da Unsplash ↗',
                        style: TextStyle(
                          fontSize: 11,
                          color: ImagoColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
