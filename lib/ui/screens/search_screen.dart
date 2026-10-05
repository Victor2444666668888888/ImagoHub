import 'package:flutter/material.dart';

import '../../models/search_filters.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class SearchScreen extends StatefulWidget {
  final AppState state;
  const SearchScreen({super.key, required this.state});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController keyword;
  late final TextEditingController width;
  late final TextEditingController height;
  late final TextEditingController color;
  late String format;
  @override
  void initState() {
    super.initState();
    final f = widget.state.filters;
    keyword = TextEditingController(text: f.query);
    width = TextEditingController(text: f.width?.toString() ?? '');
    height = TextEditingController(text: f.height?.toString() ?? '');
    color = TextEditingController(text: f.color);
    color.addListener(colorChanged);
    format = f.format;
  }

  void colorChanged() {
    if (mounted) setState(() {});
  }

  Future<void> pickColor() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escolha uma cor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final option in searchColorOptions)
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, option.name),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SearchColorDot(option: option),
                            const SizedBox(width: 8),
                            Text(
                              '${option.name[0].toUpperCase()}${option.name.substring(1)}',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: const Text('Qualquer cor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) color.text = selected;
  }

  @override
  void dispose() {
    keyword.dispose();
    width.dispose();
    height.dispose();
    color.dispose();
    super.dispose();
  }

  String? dimension(String? value, TextEditingController other) {
    if ((value ?? '').trim().isEmpty && other.text.trim().isEmpty) return null;
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 1 || number > 8192) {
      return 'Use de 1 a 8192 px.';
    }
    return null;
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.state.search(
      SearchFilters(
        query: keyword.text.trim(),
        format: format,
        width: int.tryParse(width.text.trim()),
        height: int.tryParse(height.text.trim()),
        color: color.text.trim(),
      ),
    );
  }

  void clear() {
    form.currentState?.reset();
    setState(() {
      keyword.clear();
      width.clear();
      height.clear();
      color.clear();
      format = 'Livre';
    });
    widget.state.clearSearchFilters();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ContentWidth(
      maxWidth: 560,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                'Buscar imagens',
                'Digite uma palavra ou frase para encontrar a foto que você tem em mente.',
              ),
              const SizedBox(height: 20),
              LabeledField(
                'O que você quer encontrar?',
                controller: keyword,
                hint: 'Ex.: natureza, montanhas, cidade',
                prefix: const Padding(
                  padding: EdgeInsets.all(12),
                  child: LineIcon('Search', size: 20, color: ImagoColors.muted),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Digite uma palavra ou frase.'
                    : v.length > 200
                    ? 'Use no máximo 200 caracteres.'
                    : null,
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Formato da imagem',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final value in ['Livre', '3:4', '4:3', '1:1']) ...[
                    if (value != 'Livre') const SizedBox(width: 8),
                    Expanded(
                      child: FilterChipButton(
                        value,
                        height: 44,
                        selected: format == value,
                        onTap: () => setState(() {
                          format = value;
                        }),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Retrato 3:4 · Horizontal 4:3 · Quadrado 1:1',
                style: TextStyle(fontSize: 11, color: ImagoColors.muted),
              ),
              const SizedBox(height: 30),
              const Text(
                'Tamanho exato em pixels',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledField(
                      'Largura',
                      controller: width,
                      hint: 'Ex.: 1200',
                      keyboard: TextInputType.number,
                      validator: (v) => dimension(v, height),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      'Altura',
                      controller: height,
                      hint: 'Ex.: 1600',
                      keyboard: TextInputType.number,
                      validator: (v) => dimension(v, width),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              LabeledField(
                'Cor predominante',
                controller: color,
                hint: 'Ex.: verde',
                prefix: Tooltip(
                  message: 'Selecionar cor',
                  child: InkWell(
                    onTap: pickColor,
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SearchColorDot(
                          key: const ValueKey('selected-search-color'),
                          option: searchColorOption(color.text),
                        ),
                      ),
                    ),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').trim().isNotEmpty &&
                        !supportedColors.containsKey(v!.trim().toLowerCase())
                    ? 'Use uma cor válida: verde, azul, preto, branco…'
                    : null,
              ),
              const SizedBox(height: 10),
              const Text(
                'Digite uma cor ou toque na bolinha para escolher.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: ImagoColors.muted,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ImagoButton(
                  'Buscar imagens',
                  icon: 'Search',
                  onPressed: submit,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: clear,
                  child: const Text(
                    'Limpar filtros',
                    style: TextStyle(color: ImagoColors.muted, fontSize: 13),
                  ),
                ),
              ),
              if (widget.state.recentSearches.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'BUSCAS RECENTES',
                  style: TextStyle(
                    fontSize: 10,
                    color: ImagoColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final query in widget.state.recentSearches)
                      FilterChipButton(
                        query,
                        onTap: () {
                          keyword.text = query;
                          submit();
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class SearchColorDot extends StatelessWidget {
  final SearchColorOption? option;
  const SearchColorDot({super.key, this.option});
  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: option == null ? panelColor(context) : Color(option!.argb),
      border: Border.all(color: Theme.of(context).dividerColor),
      gradient: option?.apiValue == 'black_and_white'
          ? const LinearGradient(
              colors: [Colors.black, Colors.black, Colors.white, Colors.white],
              stops: [0, .5, .5, 1],
            )
          : null,
    ),
  );
}
