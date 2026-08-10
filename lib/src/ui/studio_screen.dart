import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../theme.dart';
import 'common.dart';
import 'manifest_preview.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  var _section = 0;
  var _mobilePreview = false;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final content = switch (_section) {
      1 => _LicensePanel(controller: widget.controller),
      2 => _AuditPanel(controller: widget.controller),
      _ => _BuildPanel(
        controller: widget.controller,
        desktop: desktop,
        mobilePreview: _mobilePreview,
        onMobileViewChanged: (value) => setState(() => _mobilePreview = value),
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              NavigationRail(
                backgroundColor: DiyColors.ink,
                minWidth: 82,
                selectedIndex: _section,
                onDestinationSelected: (value) =>
                    setState(() => _section = value),
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: const IconThemeData(color: DiyColors.orange),
                unselectedIconTheme: const IconThemeData(color: Colors.white54),
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
                leading: const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 26),
                  child: DiyBrand(compact: true),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IconButton(
                        tooltip: 'Sair',
                        color: Colors.white54,
                        onPressed: widget.controller.logout,
                        icon: const Icon(Icons.logout),
                      ),
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: Text('Construir'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.key_outlined),
                    selectedIcon: Icon(Icons.key),
                    label: Text('Licença'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: Text('Histórico'),
                  ),
                ],
              ),
            Expanded(child: content),
          ],
        ),
      ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: _section,
              onDestinationSelected: (value) =>
                  setState(() => _section = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Construir',
                ),
                NavigationDestination(
                  icon: Icon(Icons.key_outlined),
                  selectedIcon: Icon(Icons.key),
                  label: 'Licença',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Histórico',
                ),
              ],
            ),
    );
  }
}

class _BuildPanel extends StatelessWidget {
  const _BuildPanel({
    required this.controller,
    required this.desktop,
    required this.mobilePreview,
    required this.onMobileViewChanged,
  });
  final AppController controller;
  final bool desktop;
  final bool mobilePreview;
  final ValueChanged<bool> onMobileViewChanged;

  @override
  Widget build(BuildContext context) {
    final chat = _ConversationPanel(controller: controller);
    final preview = AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      child: ManifestPreview(
        key: ValueKey(controller.manifest?.revision ?? 0),
        manifest: controller.manifest,
      ),
    );
    return Column(
      children: [
        _StudioHeader(controller: controller),
        if (!desktop)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.chat_bubble_outline),
                  label: Text('Conversa'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.preview_outlined),
                  label: Text('Prévia ao vivo'),
                ),
              ],
              selected: {mobilePreview},
              onSelectionChanged: (value) => onMobileViewChanged(value.first),
            ),
          ),
        Expanded(
          child: desktop
              ? Row(
                  children: [
                    SizedBox(width: 470, child: chat),
                    const VerticalDivider(width: 1),
                    Expanded(child: preview),
                  ],
                )
              : mobilePreview
              ? preview
              : chat,
        ),
      ],
    );
  }
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final entitlement = controller.entitlement;
    return Container(
      color: DiyColors.paper,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: [
          if (MediaQuery.sizeOf(context).width < 900) ...[
            const DiyBrand(compact: true),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.manifest?.name ?? 'Sistema em construção',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  controller.state.admin?.name ?? 'Administrador',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PhaseTag(
            entitlement?.kind == 'license'
                ? '${entitlement?.tier?.toUpperCase()} ativo'
                : entitlement?.kind == 'trial'
                ? '${entitlement?.daysRemaining} dias de IA'
                : 'IA bloqueada',
            color: entitlement?.kind == 'expired'
                ? DiyColors.orange
                : DiyColors.algae,
          ),
          if (controller.manifest != null) ...[
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Abrir sistema',
              onPressed: controller.openSystem,
              icon: const Icon(Icons.open_in_new),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConversationPanel extends StatefulWidget {
  const _ConversationPanel({required this.controller});
  final AppController controller;

  @override
  State<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<_ConversationPanel> {
  final _answer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _answer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _answer.text;
    if (text.trim().isEmpty) return;
    _answer.clear();
    await widget.controller.sendAnswer(text);
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.controller.state.conversation;
    return Container(
      color: DiyColors.paper,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _MessageBubble(message: messages[index]),
            ),
          ),
          if (widget.controller.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ErrorBanner(widget.controller.error!),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: DiyColors.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _answer,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !widget.controller.busy,
                    decoration: const InputDecoration(
                      hintText: 'Conte como o sistema deve funcionar…',
                      helperText:
                          'O agente atualizará a prévia depois desta resposta.',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Enviar resposta',
                  onPressed: widget.controller.busy ? null : _send,
                  icon: widget.controller.busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final agent = message.role == MessageRole.agent;
    return Align(
      alignment: agent ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: agent ? const Color(0xFFE9EEFF) : DiyColors.ink,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(agent ? 4 : 16),
            bottomRight: Radius.circular(agent ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agent ? 'AGENTE' : 'VOCÊ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: agent ? DiyColors.cobalt : DiyColors.orange,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message.text,
              style: TextStyle(
                color: agent ? DiyColors.ink : Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LicensePanel extends StatefulWidget {
  const _LicensePanel({required this.controller});
  final AppController controller;

  @override
  State<_LicensePanel> createState() => _LicensePanelState();
}

class _LicensePanelState extends State<_LicensePanel> {
  final _license = TextEditingController();
  @override
  void dispose() {
    _license.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SettingsFrame(
    tag: 'Acesso à inteligência',
    title: 'Licença e uso da IA',
    body:
        'A chave da OpenAI permanece no gateway. Este aparelho guarda apenas a licença assinada.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RevisionRail(
          revision: widget.controller.manifest?.revision ?? 0,
          label: widget.controller.entitlement?.kind == 'license'
              ? 'Licença ${widget.controller.entitlement?.tier?.toUpperCase()}'
              : 'Avaliação · ${widget.controller.entitlement?.daysRemaining ?? 0} dias',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _license,
          onChanged: (_) => setState(() {}),
          minLines: 7,
          maxLines: 12,
          decoration: const InputDecoration(
            labelText: 'Conteúdo do arquivo de licença',
            hintText: '{ "payload": { … }, "signature": "…" }',
          ),
        ),
        if (widget.controller.error != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(widget.controller.error!),
        ],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: widget.controller.busy || _license.text.trim().isEmpty
              ? null
              : () => widget.controller.activateLicense(_license.text),
          child: Text(
            widget.controller.busy ? 'Validando…' : 'Ativar neste aparelho',
          ),
        ),
      ],
    ),
  );
}

class _AuditPanel extends StatelessWidget {
  const _AuditPanel({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => _SettingsFrame(
    tag: 'Rastro local',
    title: 'Histórico administrativo',
    body: 'As últimas 500 ações ficam armazenadas neste aparelho.',
    child: controller.state.audit.isEmpty
        ? const Center(child: Text('Nenhuma ação registrada.'))
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.state.audit.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = controller.state.audit.reversed.elementAt(index);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  entry.action,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(entry.detail),
                trailing: Text(
                  '${entry.at.toLocal().day.toString().padLeft(2, '0')}/${entry.at.toLocal().month.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            },
          ),
  );
}

class _SettingsFrame extends StatelessWidget {
  const _SettingsFrame({
    required this.tag,
    required this.title,
    required this.body,
    required this.child,
  });
  final String tag;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: PhaseTag(tag)),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: DiyColors.slate),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ],
        ),
      ),
    ),
  );
}
