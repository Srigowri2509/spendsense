import 'package:flutter/material.dart';
import '../../models/app_group.dart';
import '../theme.dart';

class GroupCard extends StatelessWidget {
  final AppGroup group;

  const GroupCard({super.key, required this.group});

  String _daysLabel() {
    final names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final picks = <String>[];
    for (var i = 0; i < 7; i++) {
      if ((group.schedule.daysMask & (1 << i)) != 0) {
        picks.add(names[i]);
      }
    }
    if (picks.length == 7) return "Everyday";
    if (picks.isEmpty) return "No days";
    return picks.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final s = group.schedule.start;
    final e = group.schedule.end;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 8),
          )
        ],
        borderRadius: BorderRadius.circular(26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              const Icon(Icons.folder_special, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_daysLabel()}  •  ${two(s.hour)}:${two(s.minute)}–${two(e.hour)}:${two(e.minute)}",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 140),
                      ),
                    ),
                    Text(
                      "${group.packages.length} apps",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 140),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}