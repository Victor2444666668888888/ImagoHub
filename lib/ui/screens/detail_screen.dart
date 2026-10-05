import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../models/photo.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'library_screens.dart';

class DetailScreen extends StatefulWidget {
  final AppState state;
  const DetailScreen({super.key, required this.state});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Photo photo;
  bool loading = true;
  bool downloading = false;
  String? error;
  String size = 'filtered';
  @override
  void initState() {
    super.initState();
    photo = widget.state.currentPhoto!;
    fetch();
  }

  Future<void> fetch() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final detail = photo.withDetails(await widget.state.api.detail(photo.id));
      if (!mounted) return;
      setState(() {
        photo = detail;
      });
      widget.state.photos[photo.id] = photo;
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String get filteredLabel {
    final f = widget.state.filters;
    if (f.width != null && f.height != null) {
      return '${f.format} · ${f.width} × ${f.height} px';
    }
    if (f.ratio != null) {
      return '${f.format} · 1200 × ${(1200 / f.ratio!).round()} px';
    }
    return 'Original · ${photo.width} × ${photo.height} px';
  }

  Future<void> download() async {
    setState(() {
      downloading = true;
    });
    try {
      final filters = widget.state.filters;
      final width = size == 'original'
          ? photo.width
          : size == 'small'
          ? 800
          : filters.width ?? (filters.ratio != null ? 1200 : photo.width);
      final height = size == 'original'
          ? null
          : size == 'small'
          ? null
          : filters.height ??
                (filters.ratio != null
                    ? (width / filters.ratio!).round()
                    : null);
      await widget.state.api.trackDownload(photo);
      final bytes = await widget.state.api.photoBytes(
        photo,
        width: width,
        height: height,
      );
      final result = await FilePicker.saveFile(
        dialogTitle: 'Salvar imagem',
        fileName: 'ImagoHub-${photo.id}.jpg',
        type: FileType.custom,
        allowedExtensions: ['jpg'],
        bytes: bytes,
      );
      if (mounted && (result != null || kIsWeb)) {
        showMessage(context, kIsWeb ? 'Download iniciado.' : 'Imagem salva.');
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) {
        setState(() {
          downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ContentWidth(
      maxWidth: 820,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).width > 700 ? 420 : 262,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoImage(
                      photo,
                      dataSaver: widget.state.dataSaver,
                      imageWidth: 1400,
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: IconAction(
                        icon: 'Star',
                        label: 'Favoritar foto',
                        size: 32,
                        iconSize: 22,
                        color: ImagoColors.ink,
                        background: widget.state.favorites.contains(photo.id)
                            ? ImagoColors.star
                            : Colors.white,
                        onTap: () async {
                          try {
                            await widget.state.toggleFavorite(photo);
                          } catch (_) {
                            if (context.mounted) {
                              showMessage(
                                context,
                                'Favorito salvo. O registro na Unsplash ficou indisponível.',
                                error: true,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const FilterChipButton('Fotografia'),
                const Spacer(),
                Text(
                  '${photo.width} × ${photo.height} px',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ImagoColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              photo.title,
              style: const TextStyle(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              photo.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ImagoColors.muted,
              ),
            ),
            const SizedBox(height: 26),
            InkWell(
              onTap: () => openCredit(context, photo.user['links']?['html']),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: softColor(context),
                    child: Text(
                      photo.author
                          .split(' ')
                          .take(2)
                          .map((s) => s.isEmpty ? '' : s[0])
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ImagoColors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.author,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              openCredit(context, 'https://unsplash.com'),
                          child: const Text(
                            'na Unsplash ↗',
                            style: TextStyle(
                              fontSize: 12,
                              color: ImagoColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (error != null) ...[
              const SizedBox(height: 18),
              InlineError(
                'Os detalhes atualizados estão indisponíveis. $error',
                retry: fetch,
              ),
            ],
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 18),
            const Text(
              'Tamanho para baixar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: panelColor(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: size,
                  isExpanded: true,
                  icon: const LineIcon(
                    'ChevronDown',
                    size: 20,
                    color: ImagoColors.muted,
                  ),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'filtered',
                      child: Text(
                        filteredLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'original',
                      child: Text(
                        'Original · ${photo.width} × ${photo.height} px',
                      ),
                    ),
                    const DropdownMenuItem(
                      value: 'small',
                      child: Text('Leve · 800 px de largura'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    size = value ?? 'filtered';
                  }),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ImagoButton(
                'Baixar imagem',
                icon: 'Download',
                busy: downloading,
                onPressed: download,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ImagoButton(
                'Adicionar à pasta',
                icon: 'FolderPlus',
                primary: false,
                height: 44,
                onPressed: () =>
                    showFolderPicker(context, widget.state, [photo]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
