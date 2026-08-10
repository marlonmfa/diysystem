import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../theme.dart';
import 'common.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  String? _screenId;
  bool _showForm = false;
  final Map<String, Object?> _values = {};

  @override
  Widget build(BuildContext context) {
    final manifest = widget.controller.manifest!;
    final screen =
        manifest.screens.where((item) => item.id == _screenId).firstOrNull ??
        manifest.screens.first;
    _screenId = screen.id;
    final desktop = MediaQuery.sizeOf(context).width >= 820;

    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              backgroundColor: DiyColors.paper,
              title: Text(
                manifest.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: 'Área administrativa',
                  onPressed: widget.controller.openStudio,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
      drawer: desktop
          ? null
          : _MobileDrawer(
              manifest: manifest,
              selectedId: screen.id,
              onSelect: (id) => setState(() {
                _screenId = id;
                _showForm = false;
              }),
            ),
      body: SafeArea(
        top: desktop,
        child: Row(
          children: [
            if (desktop)
              _DesktopNavigation(
                manifest: manifest,
                selectedId: screen.id,
                entitlement: widget.controller.entitlement,
                onSelect: (id) => setState(() {
                  _screenId = id;
                  _showForm = false;
                }),
                onAdmin: widget.controller.openStudio,
              ),
            Expanded(
              child: _Workspace(
                controller: widget.controller,
                screen: screen,
                showForm: _showForm,
                values: _values,
                onToggleForm: () => setState(() => _showForm = !_showForm),
                onCancel: () => setState(() {
                  _showForm = false;
                  _values.clear();
                }),
                onValue: (key, value) => _values[key] = value,
                onSaved: () => setState(() {
                  _showForm = false;
                  _values.clear();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.manifest,
    required this.selectedId,
    required this.entitlement,
    required this.onSelect,
    required this.onAdmin,
  });
  final SystemManifest manifest;
  final String selectedId;
  final Entitlement? entitlement;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) => Container(
    width: 246,
    color: DiyColors.ink,
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DiyColors.cobalt,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                manifest.name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                manifest.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'ÁREAS',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white38),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: manifest.screens.map((screen) {
              final selected = screen.id == selectedId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: ListTile(
                  selected: selected,
                  selectedTileColor: const Color(0xFF263653),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: selected
                        ? DiyColors.cobalt
                        : Colors.white10,
                    child: Text(
                      screen.title
                          .substring(0, screen.title.length.clamp(0, 2))
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    screen.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => onSelect(screen.id),
                ),
              );
            }).toList(),
          ),
        ),
        RevisionRail(
          revision: manifest.revision,
          label: entitlement?.kind == 'license'
              ? '${entitlement?.tier?.toUpperCase()} ativo'
              : '${entitlement?.daysRemaining ?? 0} dias de IA',
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
            alignment: Alignment.centerLeft,
          ),
          onPressed: onAdmin,
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Área administrativa'),
        ),
      ],
    ),
  );
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.manifest,
    required this.selectedId,
    required this.onSelect,
  });
  final SystemManifest manifest;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              manifest.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          ...manifest.screens.map(
            (screen) => ListTile(
              selected: screen.id == selectedId,
              leading: const Icon(Icons.table_rows_outlined),
              title: Text(screen.title),
              onTap: () {
                Navigator.pop(context);
                onSelect(screen.id);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.controller,
    required this.screen,
    required this.showForm,
    required this.values,
    required this.onToggleForm,
    required this.onCancel,
    required this.onValue,
    required this.onSaved,
  });
  final AppController controller;
  final ScreenDefinition screen;
  final bool showForm;
  final Map<String, Object?> values;
  final VoidCallback onToggleForm;
  final VoidCallback onCancel;
  final void Function(String, Object?) onValue;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final records =
        controller.state.records[screen.id] ?? const <StoredRecord>[];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              runSpacing: 16,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhaseTag(screen.singularLabel),
                      const SizedBox(height: 12),
                      Text(
                        screen.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        screen.description,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: DiyColors.slate),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onToggleForm,
                  icon: Icon(showForm ? Icons.close : Icons.add),
                  label: Text(
                    showForm
                        ? 'Fechar'
                        : 'Novo ${screen.singularLabel.toLowerCase()}',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (controller.error != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(child: ErrorBanner(controller.error!)),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          sliver: SliverToBoxAdapter(
            child: showForm
                ? _RecordForm(
                    controller: controller,
                    screen: screen,
                    values: values,
                    onValue: onValue,
                    onCancel: onCancel,
                    onSaved: onSaved,
                  )
                : records.isEmpty
                ? _EmptyState(screen: screen, onCreate: onToggleForm)
                : _RecordList(screen: screen, records: records),
          ),
        ),
      ],
    );
  }
}

class _RecordForm extends StatelessWidget {
  const _RecordForm({
    required this.controller,
    required this.screen,
    required this.values,
    required this.onValue,
    required this.onCancel,
    required this.onSaved,
  });
  final AppController controller;
  final ScreenDefinition screen;
  final Map<String, Object?> values;
  final void Function(String, Object?) onValue;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Novo ${screen.singularLabel.toLowerCase()}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 720
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: screen.fields
                    .map(
                      (field) => SizedBox(
                        width: width,
                        child: _DynamicField(
                          field: field,
                          onChanged: (value) => onValue(field.id, value),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: controller.busy
                    ? null
                    : () async {
                        await controller.createRecord(screen.id, values);
                        if (controller.error == null) onSaved();
                      },
                child: Text(controller.busy ? 'Salvando…' : 'Salvar registro'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DynamicField extends StatefulWidget {
  const _DynamicField({required this.field, required this.onChanged});
  final FieldDefinition field;
  final ValueChanged<Object?> onChanged;

  @override
  State<_DynamicField> createState() => _DynamicFieldState();
}

class _DynamicFieldState extends State<_DynamicField> {
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    if (field.type == FieldType.checkbox) {
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(field.label),
        subtitle: field.helpText == null ? null : Text(field.helpText!),
        value: checked,
        onChanged: (value) {
          setState(() => checked = value);
          widget.onChanged(value);
        },
      );
    }
    final keyboard = switch (field.type) {
      FieldType.number => TextInputType.number,
      FieldType.email => TextInputType.emailAddress,
      FieldType.phone => TextInputType.phone,
      FieldType.textarea => TextInputType.multiline,
      _ => TextInputType.text,
    };
    return TextField(
      minLines: field.type == FieldType.textarea ? 3 : 1,
      maxLines: field.type == FieldType.textarea ? 5 : 1,
      keyboardType: keyboard,
      onChanged: (value) => widget.onChanged(
        field.type == FieldType.number ? num.tryParse(value) : value,
      ),
      decoration: InputDecoration(
        labelText: '${field.label}${field.required ? ' *' : ''}',
        helperText: field.helpText,
        suffixIcon: field.type == FieldType.date
            ? const Icon(Icons.calendar_today_outlined, size: 18)
            : null,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.screen, required this.onCreate});
  final ScreenDefinition screen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 50, color: DiyColors.cobalt),
          const SizedBox(height: 18),
          Text(
            'Nenhum registro ainda',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crie o primeiro ${screen.singularLabel.toLowerCase()} desta área.',
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Criar primeiro registro'),
          ),
        ],
      ),
    ),
  );
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.screen, required this.records});
  final ScreenDefinition screen;
  final List<StoredRecord> records;

  @override
  Widget build(BuildContext context) {
    final fields = screen.fields.take(4).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F4F6)),
          columns: fields
              .map((field) => DataColumn(label: Text(field.label)))
              .toList(),
          rows: records
              .map(
                (record) => DataRow(
                  cells: fields
                      .map(
                        (field) => DataCell(
                          SizedBox(
                            width: 160,
                            child: Text(
                              '${record.values[field.id] ?? '—'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
