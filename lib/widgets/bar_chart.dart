import 'package:flutter/material.dart';

class SimpleBarChart extends StatelessWidget {
  final List<double> values; // e.g., monthly spend
  final List<String> labels; // e.g., ['Feb','Mar',...]
  const SimpleBarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (i) {
            final v = values[i];
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: 18,
                        height: (v / max) * 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i], style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
