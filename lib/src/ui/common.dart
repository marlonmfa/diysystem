import 'package:flutter/material.dart';

import '../theme.dart';

class DiyBrand extends StatelessWidget {
  const DiyBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: DiyColors.ink,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 18, height: 3, color: DiyColors.orange),
              Transform.rotate(
                angle: 1.5708,
                child: Container(width: 18, height: 3, color: DiyColors.cobalt),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DIY SYSTEM',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: DiyColors.ink),
            ),
            if (!compact)
              Text(
                'oficina de software',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ],
    );
  }
}

class PhaseTag extends StatelessWidget {
  const PhaseTag(this.text, {super.key, this.color = DiyColors.cobalt});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECE5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DiyColors.orange.withValues(alpha: .5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 20, color: DiyColors.orange),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class RevisionRail extends StatelessWidget {
  const RevisionRail({required this.revision, required this.label, super.key});
  final int revision;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: DiyColors.ink,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: DiyColors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'R${revision.toString().padLeft(2, '0')}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFBFC9D2), fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
