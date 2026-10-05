import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

String? emailValidator(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())
    ? null
    : 'Digite um e-mail válido.';
String? passwordValidator(String? value) => (value ?? '').runes.length < 8
    ? 'Use pelo menos 8 caracteres.'
    : value!.runes.length > 256
    ? 'Use até 256 caracteres.'
    : null;

class AuthScreen extends StatefulWidget {
  final AppState state;
  final bool register;
  const AuthScreen({super.key, required this.state, this.register = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool visible = false;
  bool confirmVisible = false;
  bool remember = false;
  bool busy = false;
  bool attempted = false;
  String? error;
  @override
  void initState() {
    super.initState();
    for (final controller in [name, username, email, password, confirmation]) {
      controller.addListener(fieldsChanged);
    }
  }

  void fieldsChanged() {
    if (mounted) setState(() => error = null);
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    setState(() => attempted = true);
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.register) {
        await widget.state.register(
          name.text.trim(),
          email.text.trim(),
          password.text,
          username: username.text.trim(),
        );
        if (mounted) {
          showMessage(context, 'Conta criada. Bem-vindo ao ImagoHub!');
        }
      } else {
        await widget.state.login(email.text.trim(), password.text, remember);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Widget passwordActions(
    TextEditingController controller,
    bool show,
    VoidCallback toggle,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (controller.text.isNotEmpty)
        IconButton(
          tooltip: controller == confirmation
              ? 'Limpar confirmação'
              : 'Limpar senha',
          onPressed: controller.clear,
          icon: const Icon(
            Icons.close_rounded,
            size: 18,
            color: ImagoColors.muted,
          ),
        ),
      IconButton(
        tooltip: show ? 'Ocultar senha' : 'Mostrar senha',
        onPressed: toggle,
        icon: Icon(
          show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: ImagoColors.muted,
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: SingleChildScrollView(
      child: ContentWidth(
        maxWidth: 512,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
          child: Form(
            key: form,
            autovalidateMode: attempted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.register ? 'COMECE SUA COLEÇÃO' : 'BEM-VINDO DE VOLTA',
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: ImagoColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.register ? 'Crie sua conta' : 'Entre na sua conta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 11),
                Text(
                  widget.register
                      ? 'Organize imagens e guarde suas ideias.'
                      : 'Suas imagens e ideias, em um só lugar.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: ImagoColors.muted,
                  ),
                ),
                SizedBox(height: widget.register ? 32 : 51),
                if (widget.register) ...[
                  LabeledField(
                    'Nome completo',
                    controller: name,
                    hint: 'Seu nome completo',
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => (v ?? '').trim().length < 2
                        ? 'Digite seu nome completo.'
                        : v!.trim().length > 100
                        ? 'Use até 100 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    'Nome de usuário',
                    controller: username,
                    hint: 'Ex.: Victor, fotógrafo',
                    autofillHints: const [AutofillHints.nickname],
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Escolha um nome de usuário.'
                        : v!.runes.length > 100
                        ? 'Use até 100 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                ],
                LabeledField(
                  'E-mail',
                  controller: email,
                  hint: 'seuemail@exemplo.com',
                  keyboard: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: emailValidator,
                ),
                SizedBox(height: widget.register ? 18 : 25),
                LabeledField(
                  'Senha',
                  controller: password,
                  hint: widget.register ? 'Crie uma senha' : 'Digite sua senha',
                  obscure: !visible,
                  autofillHints: [
                    widget.register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  suffix: passwordActions(
                    password,
                    visible,
                    () => setState(() {
                      visible = !visible;
                    }),
                  ),
                  validator: widget.register
                      ? passwordValidator
                      : (v) => (v ?? '').isEmpty ? 'Digite sua senha.' : null,
                  onSubmitted: widget.register ? null : (_) => submit(),
                ),
                if (widget.register) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Use pelo menos 8 caracteres na senha.',
                    style: TextStyle(fontSize: 11, color: ImagoColors.muted),
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    'Confirmar senha',
                    controller: confirmation,
                    hint: 'Repita a senha',
                    obscure: !confirmVisible,
                    autofillHints: const [AutofillHints.newPassword],
                    suffix: passwordActions(
                      confirmation,
                      confirmVisible,
                      () => setState(() {
                        confirmVisible = !confirmVisible;
                      }),
                    ),
                    validator: (v) => v != password.text
                        ? 'As senhas devem ser iguais.'
                        : null,
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'As senhas devem ser iguais.',
                    style: TextStyle(fontSize: 12, color: ImagoColors.muted),
                  ),
                  const SizedBox(height: 28),
                ] else ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 24,
                        child: Checkbox(
                          value: remember,
                          onChanged: busy
                              ? null
                              : (v) => setState(() {
                                  remember = v ?? false;
                                }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            remember = !remember;
                          }),
                          child: const Text(
                            'Lembrar de mim',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (context) => PasswordResetDialog(
                                  state: widget.state,
                                  email: email.text,
                                ),
                              ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 24),
                        ),
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                ],
                if (error != null) ...[
                  InlineError(error!),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ImagoButton(
                    widget.register ? 'Criar conta' : 'Entrar',
                    busy: busy,
                    onPressed: submit,
                  ),
                ),
                SizedBox(height: widget.register ? 28 : 40),
                if (!widget.register) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                ],
                Center(
                  child: Text(
                    widget.register
                        ? 'Já tem uma conta?'
                        : 'Ainda não tem uma conta?',
                    style: const TextStyle(
                      fontSize: 13,
                      color: ImagoColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ImagoButton(
                    widget.register ? 'Entrar' : 'Criar conta',
                    primary: false,
                    height: widget.register ? 44 : 48,
                    onPressed: busy
                        ? null
                        : () => widget.state.navigate(
                            widget.register ? AppPage.login : AppPage.register,
                          ),
                  ),
                ),
                if (!widget.register) ...[
                  const SizedBox(height: 44),
                  const Center(
                    child: Text(
                      'Fotos que inspiram. Ideias que ficam.',
                      style: TextStyle(fontSize: 12, color: ImagoColors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PasswordResetDialog extends StatefulWidget {
  final AppState state;
  final String email;
  const PasswordResetDialog({
    super.key,
    required this.state,
    required this.email,
  });
  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController email;
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool confirm = false;
  bool busy = false;
  String? error;
  String? message;
  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      final result = await widget.state.api.request(
        confirm ? '/auth/password-reset/confirm' : '/auth/password-reset',
        method: 'POST',
        body: {
          'email': email.text.trim(),
          if (confirm) 'code': code.text.trim(),
          if (confirm) 'password': password.text,
        },
      );
      if (!mounted) return;
      if (confirm) {
        Navigator.pop(context);
        showMessage(context, result['message']);
        return;
      }
      setState(() {
        message = result['message'];
        if (result['local_code'] != null &&
            result['local_code'].toString().isNotEmpty) {
          code.text = result['local_code'];
          confirm = true;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recuperar acesso',
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
                const SizedBox(height: 12),
                Text(
                  confirm
                      ? 'Informe o código e escolha uma nova senha.'
                      : 'Informe o e-mail da sua conta.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ImagoColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                LabeledField(
                  'E-mail',
                  controller: email,
                  hint: 'seuemail@exemplo.com',
                  keyboard: TextInputType.emailAddress,
                  validator: emailValidator,
                ),
                if (confirm) ...[
                  const SizedBox(height: 18),
                  LabeledField(
                    'Código de recuperação',
                    controller: code,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Informe o código.' : null,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    'Nova senha',
                    controller: password,
                    obscure: true,
                    validator: passwordValidator,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    'Confirmar nova senha',
                    controller: confirmation,
                    obscure: true,
                    validator: (v) => v != password.text
                        ? 'As senhas devem ser iguais.'
                        : null,
                  ),
                ],
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ImagoColors.muted,
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  InlineError(error!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ImagoButton(
                    confirm ? 'Redefinir senha' : 'Enviar instruções',
                    busy: busy,
                    onPressed: submit,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            confirm = !confirm;
                            error = null;
                            message = null;
                          }),
                    child: Text(
                      confirm ? 'Solicitar novo código' : 'Já tenho um código',
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
