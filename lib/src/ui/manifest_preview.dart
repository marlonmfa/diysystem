import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme.dart';
import 'common.dart';

class ManifestPreview extends StatelessWidget {
  const ManifestPreview({required this.manifest, super.key});
  final SystemManifest? manifest;

  @override
  Widget build(BuildContext context) {
    final value = manifest;
    if (value == null) {
      return Container(
        color: const Color(0xFFE5EBEF),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: DiyColors.line),
                  ),
                  child: const Icon(
                    Icons.view_quilt_outlined,
                    size: 34,
                    color: DiyColors.cobalt,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'A primeira versão aparecerá aqui.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Responda ao agente. Cada conversa produz uma prévia utilizável, sem reiniciar o aplicativo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final screen = value.screens.first;
    return Container(
      color: const Color(0xFFE5EBEF),
      padding: const EdgeInsets.all(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DiyColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x160B1824),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: DiyColors.ink,
              child: Row(
                children: [
                  ...[DiyColors.orange, DiyColors.cobalt, DiyColors.algae].map(
                    (color) => Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'PRÉVIA AO VIVO',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 122,
                    color: const Color(0xFFF4F7F8),
                    padding: const EdgeInsets.fromLTRB(12, 16, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...value.screens
                            .take(6)
                            .map(
                              (item) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: item.id == screen.id
                                      ? const Color(0xFFDCE4FF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: item.id == screen.id
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        const Spacer(),
                        RevisionRail(
                          revision: value.revision,
                          label: '${value.screens.length} áreas',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PhaseTag(screen.singularLabel),
                          const SizedBox(height: 12),
                          Text(
                            screen.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            screen.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: DiyColors.slate,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 1 : 2,
                                    mainAxisExtent: 44,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: screen.fields.take(8).length,
                              itemBuilder: (context, index) {
                                final field = screen.fields[index];
                                return Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: DiyColors.line),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    field.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
