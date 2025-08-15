import 'package:flutter/material.dart';

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const Section({super.key, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (trailing != null) trailing!,
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          titleRow,
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}

  