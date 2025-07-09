// lib/widgets/round/primary_score_slider.dart

import 'package:flutter/material.dart';

class PrimaryScoreSlider extends StatelessWidget {
  final int currentScore;
  final ValueChanged<int> onChanged;

  const PrimaryScoreSlider({
    super.key,
    required this.currentScore,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Primaire',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
        Row(
          children: [
            // Affichage du chiffre à gauche du slider
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                currentScore.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: currentScore.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: currentScore.toString(),
                onChanged: (double value) {
                  onChanged(value.round());
                },
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}