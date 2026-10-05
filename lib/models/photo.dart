import 'package:flutter/material.dart';

class Photo {
  final Map<String, dynamic> data;
  const Photo(this.data);
  String get id => data['id'] as String;
  String? get asset => data['asset'] as String?;
  int get width => (data['width'] as num?)?.toInt() ?? 1;
  int get height => (data['height'] as num?)?.toInt() ?? 1;
  Map<String, dynamic> get urls =>
      Map<String, dynamic>.from(data['urls'] ?? {});
  Map<String, dynamic> get user =>
      Map<String, dynamic>.from(data['user'] ?? {});
  Map<String, dynamic> get links =>
      Map<String, dynamic>.from(data['links'] ?? {});
  String get author => user['name'] as String? ?? 'Fotógrafo';
  String get title {
    if (data['display_title'] != null) return data['display_title'];
    final text =
        (data['description'] ?? data['alt_description'] ?? 'Sem descrição')
            .toString()
            .trim();
    if (text.isEmpty) return 'Sem descrição';
    final words = text.split(RegExp(r'\s+'));
    return words.length > 8 ? '${words.take(8).join(' ')}…' : text;
  }

  String get description {
    final text =
        data['display_description'] ??
        data['description'] ??
        data['alt_description'];
    return text == null || text.toString().trim().isEmpty
        ? 'Sem descrição'
        : text.toString();
  }

  Color get placeholder {
    final hex = (data['color'] as String? ?? '#E8E9EF').replaceFirst('#', '');
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFFE8E9EF);
  }

  String imageUrl({
    int width = 800,
    int? height,
    bool dataSaver = false,
    bool download = false,
  }) {
    final raw = urls['raw'] ?? urls['regular'] ?? urls['small'];
    if (raw == null) return '';
    final uri = Uri.parse(raw);
    final query = {
      ...uri.queryParameters,
      'w': '$width',
      'q': download
          ? '90'
          : dataSaver
          ? '60'
          : '80',
      'fm': 'jpg',
      'fit': height == null ? 'max' : 'crop',
      'auto': 'format',
    };
    if (height != null) query['h'] = '$height';
    if (download) query.remove('auto');
    return uri.replace(queryParameters: query).toString();
  }

  Photo withDetails(Photo other) => Photo({
    ...data,
    ...other.data,
    if (asset != null) 'asset': asset,
    if (data['display_title'] != null) 'display_title': data['display_title'],
    if (data['display_description'] != null)
      'display_description': data['display_description'],
  });
}
