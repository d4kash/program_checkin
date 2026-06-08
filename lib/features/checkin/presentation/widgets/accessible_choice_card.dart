import 'package:flutter/material.dart';

class AccessibleChoiceCard<T> extends StatelessWidget {
  const AccessibleChoiceCard({
    super.key,
    this.semanticsKey,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
    this.icon,
  });

  final Key? semanticsKey;
  final T value;
  final T? groupValue;
  final String label;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      key: semanticsKey,
      container: true,
      label: label,
      selected: selected,
      button: true,
      enabled: true,
      onTap: () => onChanged(value),
      child: ExcludeSemantics(
        child: Material(
          color: selected ? scheme.primaryContainer : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onChanged(value),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    icon ?? Icons.check_circle_outline,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected) Icon(Icons.done_rounded, color: scheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
