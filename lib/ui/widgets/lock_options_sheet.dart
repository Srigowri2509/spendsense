import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_rule.dart';
import '../../models/schedule.dart';
import '../../models/lock_request.dart';
import '../theme.dart';

class LockOptionsSheet extends StatefulWidget {
  final String appName;

  const LockOptionsSheet({super.key, required this.appName});

  @override
  State<LockOptionsSheet> createState() => _LockOptionsSheetState();
}

class _LockOptionsSheetState extends State<LockOptionsSheet> {
  LockMode mode = LockMode.quick;
  Duration? d = const Duration(minutes: 30);

  int daysMask = 0x7F; // everyday
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);

  Widget _chip(String label, Duration dur) => ChoiceChip(
        label: Text(label),
        selected: d == dur,
        onSelected: (_) => setState(() => d = dur),
        selectedColor: AppColors.chipBg,
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 24)
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Lock ${widget.appName}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<LockMode>(
                segments: const [
                  ButtonSegment(value: LockMode.quick, label: Text("Quick")),
                  ButtonSegment(
                      value: LockMode.scheduled, label: Text("Schedule")),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setState(() => mode = s.first),
              ),
              const SizedBox(height: 12),
              if (mode == LockMode.quick) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _chip("10m", const Duration(minutes: 10)),
                    _chip("20m", const Duration(minutes: 20)),
                    _chip("30m", const Duration(minutes: 30)),
                    _chip("1h", const Duration(hours: 1)),
                    _chip("2h", const Duration(hours: 2)),
                    _chip("4h", const Duration(hours: 4)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 6),
                _DaysPicker(
                  initialMask: daysMask,
                  onChanged: (m) => setState(() => daysMask = m),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: start,
                          );
                          if (t != null) setState(() => start = t);
                        },
                        child: Text(
                          "Start ${two(start.hour)}:${two(start.minute)}",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: end,
                          );
                          if (t != null) setState(() => end = t);
                        },
                        child: Text("End ${two(end.hour)}:${two(end.minute)}"),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (mode == LockMode.quick) {
                      final dur = d ?? const Duration(minutes: 30);
                      Navigator.pop(context, LockRequest.quick(dur));
                    } else {
                      final sched = Schedule(
                        daysMask: daysMask,
                        start: start,
                        end: end,
                      );
                      Navigator.pop(context, LockRequest.scheduled(sched));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text(
                    "Lock",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysPicker extends StatefulWidget {
  final int initialMask;
  final ValueChanged<int> onChanged;

  const _DaysPicker({required this.initialMask, required this.onChanged});

  @override
  State<_DaysPicker> createState() => _DaysPickerState();
}

class _DaysPickerState extends State<_DaysPicker> {
  late int mask;
  final labels = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  void initState() {
    super.initState();
    mask = widget.initialMask;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        final on = (mask & (1 << i)) != 0;
        return ChoiceChip(
          label: Text(labels[i]),
          selected: on,
          onSelected: (_) {
            setState(() {
              mask = on ? (mask & ~(1 << i)) : (mask | (1 << i));
            });
            widget.onChanged(mask);
          },
          selectedColor: AppColors.chipBg,
        );
      }),
    );
  }
}

// moved to models/lock_request.dart