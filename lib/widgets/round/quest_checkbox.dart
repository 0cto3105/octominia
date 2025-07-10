// lib/widgets/round/quest_checkbox.dart

import 'package:flutter/material.dart';

class QuestCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool)? onChanged;
  final bool isEnabled;
  final bool isPreCompleted;

  const QuestCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.isEnabled,
    this.isPreCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    // La case est interactive si elle est activée ET qu'elle n'est pas une quête d'un tour précédent
    final bool isInteractive = isEnabled && !isPreCompleted;

    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: isInteractive
              ? (bool? newValue) {
            if (onChanged != null) {
              onChanged!(newValue ?? false);
            }
          }
              : null,
          checkColor: Colors.white,
          // La couleur de la coche quand la case est active
          activeColor: isPreCompleted
              ? Colors.grey.shade600 // Couleur grisée si complétée à un tour précédent
              : Theme.of(context).primaryColor,
          // Gère la couleur du bord de la case quand elle est désactivée
          side: WidgetStateBorderSide.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(color: Colors.grey.shade700);
              }
              return null; // Style par défaut sinon
            },
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isInteractive
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Theme.of(context).disabledColor,
              fontStyle: isPreCompleted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}