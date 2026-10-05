class SearchColorOption {
  final String name;
  final String apiValue;
  final int argb;
  const SearchColorOption(this.name, this.apiValue, this.argb);
}

const searchColorOptions = [
  SearchColorOption('preto e branco', 'black_and_white', 0xFF747782),
  SearchColorOption('preto', 'black', 0xFF16171B),
  SearchColorOption('branco', 'white', 0xFFFFFFFF),
  SearchColorOption('amarelo', 'yellow', 0xFFF4C542),
  SearchColorOption('laranja', 'orange', 0xFFED9134),
  SearchColorOption('vermelho', 'red', 0xFFE45454),
  SearchColorOption('roxo', 'purple', 0xFF8B5CC2),
  SearchColorOption('magenta', 'magenta', 0xFFD54D9C),
  SearchColorOption('verde', 'green', 0xFF668C65),
  SearchColorOption('verde-azulado', 'teal', 0xFF349A94),
  SearchColorOption('azul', 'blue', 0xFF488BCB),
];

SearchColorOption? searchColorOption(String name) {
  final apiValue = supportedColors[name.trim().toLowerCase()];
  for (final option in searchColorOptions) {
    if (option.apiValue == apiValue) return option;
  }
  return null;
}

const suggestedCategories = [
  'Natureza',
  'Paisagens',
  'Animais',
  'Carros',
  'Praias',
  'Arquitetura',
  'Tecnologia',
  'Pessoas',
];

const categorySearchTerms = <String, String>{
  'natureza': 'nature',
  'paisagens': 'landscape',
  'paisagem': 'landscape',
  'animais': 'animals',
  'animal': 'animal',
  'carros': 'cars',
  'carro': 'car',
  'praias': 'beaches',
  'praia': 'beach',
  'arquitetura': 'architecture',
  'tecnologia': 'technology',
  'pessoas': 'people',
};

const supportedColors = <String, String>{
  'preto e branco': 'black_and_white',
  'preto': 'black',
  'branco': 'white',
  'amarelo': 'yellow',
  'laranja': 'orange',
  'vermelho': 'red',
  'roxo': 'purple',
  'magenta': 'magenta',
  'verde': 'green',
  'verde-azulado': 'teal',
  'azul': 'blue',
  'black_and_white': 'black_and_white',
  'black': 'black',
  'white': 'white',
  'yellow': 'yellow',
  'orange': 'orange',
  'red': 'red',
  'purple': 'purple',
  'green': 'green',
  'teal': 'teal',
  'blue': 'blue',
};

class SearchFilters {
  final String query;
  final String format;
  final int? width;
  final int? height;
  final String color;
  final bool safe;
  final String order;
  const SearchFilters({
    this.query = '',
    this.format = 'Livre',
    this.width,
    this.height,
    this.color = '',
    this.safe = true,
    this.order = 'relevant',
  });

  String? get apiColor => supportedColors[color.trim().toLowerCase()];
  String get apiQuery =>
      categorySearchTerms[query.trim().toLowerCase()] ?? query.trim();
  String? get orientation {
    if (width != null && height != null) {
      return width == height
          ? 'squarish'
          : width! < height!
          ? 'portrait'
          : 'landscape';
    }
    return {'3:4': 'portrait', '4:3': 'landscape', '1:1': 'squarish'}[format];
  }

  double? get ratio => width != null && height != null
      ? width! / height!
      : {'3:4': 3 / 4, '4:3': 4 / 3, '1:1': 1.0}[format];

  Map<String, String> params(int page) => {
    'query': apiQuery,
    'page': '$page',
    'per_page': '20',
    'order_by': order,
    'content_filter': safe ? 'high' : 'low',
    'orientation': ?orientation,
    'color': ?apiColor,
  };

  SearchFilters copyWith({String? order, bool? safe}) => SearchFilters(
    query: query,
    format: format,
    width: width,
    height: height,
    color: color,
    safe: safe ?? this.safe,
    order: order ?? this.order,
  );
}
