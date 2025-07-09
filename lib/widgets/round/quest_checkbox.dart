// lib/widgets/round/quest_checkbox.dart

import 'package:flutter/material.dart';

class QuestCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool)? onChanged;
  final bool isEnabled;

  const QuestCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: isEnabled
              ? (bool? newValue) {
            if (onChanged != null) {
              onChanged!(newValue ?? false);
            }
          }
              : null,
          checkColor: Colors.white,
          activeColor: Theme.of(context).primaryColor,
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isEnabled
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ],
    );
  }
}