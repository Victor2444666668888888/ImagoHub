import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/library.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController username;
  late final TextEditingController email;
  late final TextEditingController bio;
  String? avatar;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final p = widget.state.profile;
    name = TextEditingController(text: p.name);
    username = TextEditingController(text: p.username);
    email = TextEditingController(text: p.email);
    bio = TextEditingController(text: p.bio);
    avatar = p.avatar;
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    email.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (file == null) return;
      final length = await file.length();
      if (length == null || length > 5 * 1024 * 1024) {
        if (mounted) {
          showMessage(context, 'Escolha uma imagem de até 5 MB.', error: true);
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 256);
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (mounted && png != null) {
        setState(() {
          avatar = base64Encode(png.buffer.asUint8List());
        });
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Não foi possível abrir esta imagem. Use PNG ou JPG.',
          error: true,
        );
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
    });
    try {
      final userName = username.text.trim();
      await widget.state.saveProfile(
        UserProfile(
          name: name.text.trim(),
          email: email.text.trim().toLowerCase(),
          username: userName,
          bio: bio.text.trim(),
          avatar: avatar,
        ),
      );
      if (mounted) showMessage(context, 'Perfil atualizado.');
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  void cancel() {
    final p = widget.state.profile;
    setState(() {
      name.text = p.name;
      username.text = p.username;
      email.text = p.email;
      bio.text = p.bio;
      avatar = p.avatar;
    });
    FocusScope.of(context).unfocus();
    showMessage(context, 'Alterações descartadas.');
  }

  Widget caption(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      color: ImagoColors.muted,
      fontWeight: FontWeight.w700,
    ),
  );
  Widget preferences() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      caption('APARÊNCIA'),
      const SizedBox(height: 14),
      Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: panelColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            LineIcon(widget.state.dark ? 'Moon' : 'Sun', size: 22),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tema',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.state.dark ? 'Escuro' : 'Claro',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ImagoColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: widget.state.dark,
                icon: const LineIcon(
                  'ChevronDown',
                  size: 20,
                  color: ImagoColors.muted,
                ),
                selectedItemBuilder: (context) => const [
                  SizedBox.shrink(),
                  SizedBox.shrink(),
                ],
                items: const [
                  DropdownMenuItem(value: false, child: Text('Claro')),
                  DropdownMenuItem(value: true, child: Text('Escuro')),
                ],
                onChanged: (value) {
                  if (value != null) widget.state.setPreference('dark', value);
                },
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      preferenceRow(
        'Economia de dados',
        'Fotos leves na galeria.',
        widget.state.dataSaver,
        (value) => widget.state.setPreference('dataSaver', value),
      ),
      const SizedBox(height: 18),
      const Divider(height: 1),
      const SizedBox(height: 22),
      caption('BUSCA'),
      const SizedBox(height: 20),
      preferenceRow(
        'Busca segura',
        'Reduz conteúdo sensível.',
        widget.state.safeSearch,
        (value) => widget.state.setPreference('safeSearch', value),
      ),
      const SizedBox(height: 18),
      const Divider(height: 1),
      const SizedBox(height: 22),
      caption('BIBLIOTECA'),
      const SizedBox(height: 20),
      InkWell(
        onTap: () => widget.state.navigate(AppPage.folders),
        child: Row(
          children: [
            const LineIcon('Folder', color: ImagoColors.brand),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Salvos neste aparelho',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.state.favorites.length} favoritos · ${widget.state.folders.length} pastas',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ImagoColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Seus favoritos e pastas são guardados neste dispositivo.',
        style: TextStyle(fontSize: 12, height: 1.5, color: ImagoColors.muted),
      ),
    ],
  );
  Widget preferenceRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: ImagoColors.muted),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 44,
        child: FittedBox(
          child: Switch(value: value, onChanged: onChanged),
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ContentWidth(
      maxWidth: 560,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              'Configurações',
              'Deixe o ImagoHub com a sua cara.',
            ),
            const SizedBox(height: 32),
            preferences(),
            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 22),
            const PageHeading('Perfil', 'Seu perfil, do seu jeito.'),
            const SizedBox(height: 30),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: softColor(context),
                        backgroundImage: avatar == null
                            ? null
                            : MemoryImage(base64Decode(avatar!)),
                        child: avatar == null
                            ? Text(
                                UserProfile(name: name.text).initials,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: ImagoColors.brand,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Foto de perfil',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Material(
                              color: softColor(context),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: pickAvatar,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LineIcon(
                                        'Image',
                                        size: 18,
                                        color: ImagoColors.brand,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Alterar foto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ImagoColors.brand,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'PNG ou JPG · até 5 MB',
                              style: TextStyle(
                                fontSize: 10,
                                color: ImagoColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  LabeledField(
                    'Nome',
                    controller: name,
                    hint: 'Seu nome',
                    validator: (v) => (v ?? '').trim().length < 2
                        ? 'Digite um nome válido.'
                        : v!.length > 100
                        ? 'Use até 100 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    'Nome de usuário',
                    controller: username,
                    hint: 'Ex.: Victor, fotógrafo',
                    validator: (v) => (v ?? '').runes.length > 100
                        ? 'Use até 100 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    'E-mail',
                    controller: email,
                    hint: 'seuemail@exemplo.com',
                    keyboard: TextInputType.emailAddress,
                    validator: (v) =>
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch((v ?? '').trim())
                        ? 'Digite um e-mail válido.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    'Biografia',
                    controller: bio,
                    hint: 'Conte um pouco sobre você.',
                    maxLength: 160,
                    maxLines: 3,
                    keyboard: TextInputType.multiline,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ImagoButton(
                      'Salvar alterações',
                      icon: 'Check',
                      busy: busy,
                      onPressed: save,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ImagoButton(
                      'Cancelar',
                      primary: false,
                      height: 44,
                      onPressed: busy ? null : cancel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 20),
            if (widget.state.isAuthenticated) ...[
              Text(
                'Conectado como ${widget.state.user!['email']}',
                style: const TextStyle(fontSize: 12, color: ImagoColors.muted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ImagoButton(
                  'Sair da conta',
                  primary: false,
                  onPressed: () => widget.state.logout(),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
