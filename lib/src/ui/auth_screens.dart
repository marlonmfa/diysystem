import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme.dart';
import 'common.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthFrame(
    introduction: const _Introduction(
      tag: 'Primeira abertura',
      title: 'Antes de construir, proteja a oficina.',
      body:
          'Este será o único acesso capaz de conversar com o agente, alterar a estrutura e consultar o histórico.',
    ),
    form: _FormCard(
      title: 'Criar administrador',
      error: widget.controller.error,
      children: [
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Nome do administrador'),
        ),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Senha',
            helperText: 'Mínimo de 10 caracteres',
          ),
        ),
        TextField(
          controller: _confirmation,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar senha'),
        ),
        FilledButton.icon(
          onPressed: widget.controller.busy
              ? null
              : () => widget.controller.createAdmin(
                  name: _name.text,
                  email: _email.text,
                  password: _password.text,
                  confirmation: _confirmation.text,
                ),
          icon: widget.controller.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: Text(
            widget.controller.busy
                ? 'Protegendo o acesso…'
                : 'Criar acesso e conversar',
          ),
        ),
      ],
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email.text = widget.controller.state.admin?.email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthFrame(
    introduction: _Introduction(
      tag: widget.controller.manifest == null
          ? 'Oficina vazia'
          : 'Sistema local',
      title: widget.controller.manifest == null
          ? 'Seu agente está esperando.'
          : widget.controller.manifest!.name,
      body: widget.controller.manifest == null
          ? 'Entre para começar a descrever o sistema que você precisa.'
          : 'Os dados continuam neste aparelho. Entre para abrir e administrar o sistema.',
    ),
    form: _FormCard(
      title: 'Entrar como administrador',
      error: widget.controller.error,
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          onSubmitted: (_) =>
              widget.controller.login(_email.text, _password.text),
          decoration: const InputDecoration(labelText: 'Senha'),
        ),
        FilledButton(
          onPressed: widget.controller.busy
              ? null
              : () => widget.controller.login(_email.text, _password.text),
          child: Text(widget.controller.busy ? 'Verificando…' : 'Entrar'),
        ),
      ],
    ),
  );
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({required this.introduction, required this.form});
  final Widget introduction;
  final Widget form;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DiyBrand(),
                const SizedBox(height: 42),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 760) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          introduction,
                          const SizedBox(height: 28),
                          form,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: introduction),
                        const SizedBox(width: 72),
                        SizedBox(width: 430, child: form),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Introduction extends StatelessWidget {
  const _Introduction({
    required this.tag,
    required this.title,
    required this.body,
  });
  final String tag;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PhaseTag(tag, color: DiyColors.orange),
      const SizedBox(height: 20),
      Text(title, style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 18),
      Text(
        body,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: DiyColors.slate),
      ),
      const SizedBox(height: 24),
      const Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: DiyColors.algae),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Senha protegida e dados armazenados somente neste aparelho.',
            ),
          ),
        ],
      ),
    ],
  );
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children, this.error});
  final String title;
  final List<Widget> children;
  final String? error;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 22),
          ...children.expand((child) => [child, const SizedBox(height: 14)]),
          if (error != null) ErrorBanner(error!),
        ],
      ),
    ),
  );
}
