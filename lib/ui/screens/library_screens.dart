import 'package:flutter/material.dart';

import '../../models/library.dart';
import '../../models/photo.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

Future<PhotoFolder?> showNewFolder(
  BuildContext context,
  AppState state, {
  PhotoFolder? rename,
}) async {
  return showModalBottomSheet<PhotoFolder>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => NewFolderSheet(state: state, rename: rename),
  );
}

class NewFolderSheet extends StatefulWidget {
  final AppState state;
  final PhotoFolder? rename;
  const NewFolderSheet({super.key, required this.state, this.rename});
  @override
  State<NewFolderSheet> createState() => _NewFolderSheetState();
}

class _NewFolderSheetState extends State<NewFolderSheet> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.rename?.name ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      PhotoFolder folder;
      if (widget.rename != null) {
        await widget.state.renameFolder(widget.rename!, name.text);
        folder = widget.rename!;
      } else {
        folder = await widget.state.createFolder(name.text);
      }
      if (mounted) {
        Navigator.pop(context, folder);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.rename == null ? 'Nova pasta' : 'Renomear pasta',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconAction(
                      icon: 'X',
                      label: 'Fechar',
                      size: 32,
                      background: panelColor(context),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Organize as imagens com um nome.',
                  style: TextStyle(fontSize: 13, color: ImagoColors.muted),
                ),
                const SizedBox(height: 26),
                LabeledField(
                  'Nome da pasta',
                  controller: name,
                  hint: 'Ex.: Natureza',
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Digite o nome da pasta.'
                      : v!.trim().length > 80
                      ? 'Use até 80 caracteres.'
                      : null,
                  onSubmitted: (_) => save(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Você poderá adicionar fotos depois.',
                  style: TextStyle(fontSize: 12, color: ImagoColors.muted),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  InlineError(error!),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ImagoButton(
                    widget.rename == null ? 'Criar pasta' : 'Salvar nome',
                    icon: widget.rename == null ? 'Plus' : 'Check',
                    busy: busy,
                    onPressed: save,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: ImagoColors.muted, fontSize: 14),
                    ),
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

Future<void> showFolderPicker(
  BuildContext context,
  AppState state,
  List<Photo> photos,
) async {
  if (photos.isEmpty) {
    showMessage(context, 'Selecione pelo menos uma imagem.');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => FolderPickerSheet(state: state, photos: photos),
  );
}

class FolderPickerSheet extends StatefulWidget {
  final AppState state;
  final List<Photo> photos;
  const FolderPickerSheet({
    super.key,
    required this.state,
    required this.photos,
  });
  @override
  State<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<FolderPickerSheet> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Adicionar à pasta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              IconAction(
                icon: 'X',
                label: 'Fechar',
                size: 32,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.photos.length} ${widget.photos.length == 1 ? 'imagem selecionada' : 'imagens selecionadas'}',
            style: const TextStyle(fontSize: 13, color: ImagoColors.muted),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .45,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final folder in widget.state.folders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const LineIcon(
                        'Folder',
                        color: ImagoColors.brand,
                      ),
                      title: Text(
                        folder.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${folder.photoIds.length} imagens',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ImagoColors.muted,
                        ),
                      ),
                      trailing: const LineIcon('ChevronRight', size: 20),
                      onTap: busy
                          ? null
                          : () async {
                              setState(() {
                                busy = true;
                              });
                              try {
                                await widget.state.addToFolder(
                                  folder,
                                  widget.photos,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  showMessage(
                                    context,
                                    'Imagens adicionadas a ${folder.name}.',
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  showMessage(
                                    context,
                                    e.toString(),
                                    error: true,
                                  );
                                }
                              }
                            },
                    ),
                ],
              ),
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ImagoButton(
              'Nova pasta',
              icon: 'Plus',
              primary: false,
              onPressed: busy
                  ? null
                  : () async {
                      await showNewFolder(context, widget.state);
                      if (mounted) setState(() {});
                    },
            ),
          ),
        ],
      ),
    ),
  );
}

class FoldersScreen extends StatelessWidget {
  final AppState state;
  const FoldersScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ContentWidth(
      maxWidth: 1000,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading('Minhas pastas', 'Sua inspiração, organizada.'),
            const SizedBox(height: 20),
            Row(
              children: [
                const LineIcon('Folder', size: 20, color: ImagoColors.muted),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${state.folders.length} ${state.folders.length == 1 ? 'pasta' : 'pastas'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ImagoColors.muted,
                    ),
                  ),
                ),
                ImagoButton(
                  'Nova pasta',
                  primary: false,
                  icon: 'Plus',
                  height: 40,
                  onPressed: () async {
                    final folder = await showNewFolder(context, state);
                    if (folder != null && context.mounted) {
                      showMessage(context, 'Pasta criada.');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (state.folders.isEmpty)
              const EmptyState(
                icon: 'Folder',
                title: 'Sua coleção começa aqui',
                message:
                    'Crie uma pasta e guarde as imagens que inspiram você.',
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 650
                    ? 3
                    : constraints.maxWidth > 470
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.folders.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 18,
                    mainAxisExtent: 164,
                  ),
                  itemBuilder: (context, index) {
                    final folder = state.folders[index];
                    final preview = state.folderPhotos(folder).take(3).toList();
                    return Material(
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => state.openFolder(folder),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 98,
                              child: Row(
                                children: [
                                  for (var i = 0; i < 3; i++) ...[
                                    if (i > 0) const SizedBox(width: 2),
                                    Expanded(
                                      child: i < preview.length
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: PhotoImage(
                                                preview[i],
                                                dataSaver: state.dataSaver,
                                                imageWidth: 300,
                                              ),
                                            )
                                          : ColoredBox(
                                              color: panelColor(context),
                                              child: const Center(
                                                child: LineIcon(
                                                  'Image',
                                                  color: ImagoColors.muted,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          folder.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.2,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${folder.photoIds.length} imagens',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: ImagoColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const LineIcon(
                                    'ChevronRight',
                                    size: 20,
                                    color: ImagoColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Suas pastas ficam neste dispositivo.',
              style: TextStyle(fontSize: 11, color: ImagoColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class SavedPhotosScreen extends StatefulWidget {
  final AppState state;
  final PhotoFolder? folder;
  const SavedPhotosScreen({super.key, required this.state, this.folder});
  @override
  State<SavedPhotosScreen> createState() => _SavedPhotosScreenState();
}

class _SavedPhotosScreenState extends State<SavedPhotosScreen> {
  final Set<String> selected = {};
  bool selecting = false;
  List<Photo> get photos => widget.folder == null
      ? widget.state.savedPhotos
      : widget.state.folderPhotos(widget.folder!);
  void select(Photo photo) => setState(() {
    selecting = true;
    if (!selected.remove(photo.id)) selected.add(photo.id);
  });
  Future<void> deleteFolder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir pasta?'),
        content: const Text(
          'As imagens continuam na galeria e nos seus favoritos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) await widget.state.deleteFolder(widget.folder!);
  }

  @override
  Widget build(BuildContext context) {
    selected.removeWhere((id) => !photos.any((p) => p.id == id));
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeading(
                      widget.folder?.name ?? 'Favoritos',
                      widget.folder == null
                          ? '${photos.length} imagens salvas neste dispositivo'
                          : '${photos.length} imagens · Pasta local',
                    ),
                    const SizedBox(height: 18),
                    if (widget.folder != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  widget.state.navigate(AppPage.folders),
                              style: TextButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Voltar às pastas',
                                style: TextStyle(
                                  color: ImagoColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          ImagoButton(
                            'Adicionar',
                            icon: 'Plus',
                            primary: false,
                            height: 40,
                            onPressed: () => showPhotoPicker(
                              context,
                              widget.state,
                              widget.folder!,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opções da pasta',
                            icon: const LineIcon('MoreHorizontal', size: 20),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Renomear pasta'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir pasta'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'rename') {
                                showNewFolder(
                                  context,
                                  widget.state,
                                  rename: widget.folder,
                                );
                              } else {
                                deleteFolder();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (photos.isNotEmpty)
                      Row(
                        children: [
                          FilterChipButton(
                            selecting
                                ? '${selected.length} ${selected.length == 1 ? 'selecionada' : 'selecionadas'}'
                                : 'Selecionar',
                            selected: true,
                            onTap: () => setState(() {
                              selecting = true;
                            }),
                          ),
                          const Spacer(),
                          if (selecting)
                            TextButton(
                              onPressed: () => setState(() {
                                selecting = false;
                                selected.clear();
                              }),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ImagoColors.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (selecting)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value:
                                    selected.length == photos.length &&
                                    photos.isNotEmpty,
                                onChanged: (all) => setState(() {
                                  selected.clear();
                                  if (all == true) {
                                    selected.addAll(photos.map((p) => p.id));
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Selecionar todas',
                              style: TextStyle(
                                fontSize: 12,
                                color: ImagoColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    if (photos.isEmpty)
                      EmptyState(
                        icon: widget.folder == null ? 'Star' : 'Folder',
                        title: widget.folder == null
                            ? 'Guarde suas inspirações'
                            : 'Esta pasta está vazia',
                        message: widget.folder == null
                            ? 'Toque na estrela de uma foto para encontrá-la aqui.'
                            : 'Adicione imagens para começar sua coleção.',
                        action: ImagoButton(
                          widget.folder == null
                              ? 'Explorar imagens'
                              : 'Adicionar imagens',
                          icon: 'Plus',
                          onPressed: () => widget.folder == null
                              ? widget.state.navigate(AppPage.discover)
                              : showPhotoPicker(
                                  context,
                                  widget.state,
                                  widget.folder!,
                                ),
                        ),
                      ),
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
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns;
                        final imageHeight = width * 168 / 146;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: photos.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 12,
                                mainAxisExtent: imageHeight + 70,
                              ),
                          itemBuilder: (context, i) => PhotoCard(
                            photos[i],
                            state: widget.state,
                            compact: true,
                            imageHeight: imageHeight,
                            selected: selected.contains(photos[i].id),
                            selecting: selecting,
                            onSelect: () => select(photos[i]),
                            onLongPress: () => select(photos[i]),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (photos.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: ContentWidth(
              child: SizedBox(
                width: double.infinity,
                child: ImagoButton(
                  widget.folder == null
                      ? 'Adicionar à pasta${selected.isEmpty ? '' : ' (${selected.length})'}'
                      : 'Remover da pasta',
                  primary: widget.folder == null,
                  icon: widget.folder == null ? 'FolderPlus' : 'Trash2',
                  onPressed: () async {
                    if (selected.isEmpty) {
                      setState(() {
                        selecting = true;
                      });
                      showMessage(context, 'Selecione as imagens primeiro.');
                      return;
                    }
                    if (widget.folder != null) {
                      await widget.state.removeFromFolder(
                        widget.folder!,
                        selected,
                      );
                      if (context.mounted) {
                        setState(() {
                          selected.clear();
                          selecting = false;
                        });
                        showMessage(context, 'Imagens removidas da pasta.');
                      }
                    } else {
                      await showFolderPicker(
                        context,
                        widget.state,
                        photos.where((p) => selected.contains(p.id)).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showPhotoPicker(
  BuildContext context,
  AppState state,
  PhotoFolder folder,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 800),
    builder: (context) => PhotoPickerSheet(state: state, folder: folder),
  );
}

class PhotoPickerSheet extends StatefulWidget {
  final AppState state;
  final PhotoFolder folder;
  const PhotoPickerSheet({
    super.key,
    required this.state,
    required this.folder,
  });
  @override
  State<PhotoPickerSheet> createState() => _PhotoPickerSheetState();
}

class _PhotoPickerSheetState extends State<PhotoPickerSheet> {
  final Set<String> selected = {};
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final photos = widget.state.photos.values
        .where((p) => !widget.folder.photoIds.contains(p.id))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Adicionar imagens',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconAction(
                    icon: 'X',
                    label: 'Fechar',
                    size: 32,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: photos.isEmpty
                    ? const EmptyState(
                        icon: 'Image',
                        title: 'Tudo já está nesta pasta',
                        message:
                            'Encontre novas imagens na galeria ou na busca.',
                      )
                    : GridView.builder(
                        itemCount: photos.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 200,
                            ),
                        itemBuilder: (context, i) => PhotoCard(
                          photos[i],
                          state: widget.state,
                          compact: true,
                          imageHeight: 130,
                          selected: selected.contains(photos[i].id),
                          selecting: true,
                          onSelect: () => setState(() {
                            if (!selected.remove(photos[i].id)) {
                              selected.add(photos[i].id);
                            }
                          }),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ImagoButton(
                  'Adicionar (${selected.length})',
                  icon: 'Plus',
                  busy: busy,
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          setState(() {
                            busy = true;
                          });
                          try {
                            await widget.state.addToFolder(
                              widget.folder,
                              photos.where((p) => selected.contains(p.id)),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              showMessage(
                                context,
                                'Imagens adicionadas à pasta.',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              showMessage(context, e.toString(), error: true);
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
