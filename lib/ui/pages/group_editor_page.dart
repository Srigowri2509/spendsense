import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import '../../controllers/rules_controller.dart';
import '../../models/app_group.dart';
import '../../models/schedule.dart';
import '../theme.dart';

import 'app_picker_page.dart';

class GroupEditorPage extends ConsumerStatefulWidget {
  const GroupEditorPage({super.key});

  @override
  ConsumerState<GroupEditorPage> createState() => _GroupEditorPageState();
}

class _GroupEditorPageState extends ConsumerState<GroupEditorPage> {
  final nameCtl = TextEditingController();
  final msgCtl = TextEditingController();
  int daysMask = 0x7F;
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);

  final List<AppInfo> picked = [];

  Future<void> _pickApp() async {
    final app = await Navigator.of(context).push<AppInfo>(
      MaterialPageRoute(builder: (_) => const AppPickerPage()),
    );
    if (app != null &&
        picked.indexWhere((a) => a.packageName == app.packageName) < 0) {
      setState(() => picked.add(app));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Group")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameCtl,
            decoration: const InputDecoration(
              labelText: "Group name (e.g., Social)",
            ),
          ),
          const SizedBox(height: 10),
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
                  child: Text("Start ${two(start.hour)}:${two(start.minute)}"),
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
          const SizedBox(height: 8),
          TextField(
            controller: msgCtl,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: "Custom message (optional)",
              hintText: 'e.g., "You\'re doing great. Stay focused!"',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Apps",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...picked.map(
            (a) => ListTile(
              leading: CircleAvatar(
                child: Text(
                  a.name.isNotEmpty ? a.name[0].toUpperCase() : "?",
                ),
              ),
              title: Text(a.name),
              subtitle: Text(a.packageName),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(
                  () => picked.removeWhere(
                    (x) => x.packageName == a.packageName,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickApp,
            icon: const Icon(Icons.add),
            label: const Text("Add app"),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () async {
              if (nameCtl.text.trim().isEmpty || picked.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Add a name and at least one app"),
                  ),
                );
                return;
              }
              final sched = Schedule(
                daysMask: daysMask,
                start: start,
                end: end,
              );
              final id = nameCtl.text
                  .trim()
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                  .replaceAll(RegExp(r'^_+|_+$'), '');
              final pkg = picked.map((e) => e.packageName).toList();
              final names = {for (final a in picked) a.packageName: a.name};
              final g = AppGroup(
                id: id.isEmpty
                    ? 'group_${DateTime.now().millisecondsSinceEpoch}'
                    : id,
                title: nameCtl.text.trim(),
                packages: pkg,
                names: names,
                schedule: sched,
                customMessage: msgCtl.text.trim().isEmpty
                    ? null
                    : msgCtl.text.trim(),
              );
              // Capture navigator before awaiting to avoid using BuildContext
              // across async gaps (prevents use_build_context_synchronously)
              final nav = Navigator.of(context);
              await ref.read(rulesProvider.notifier).upsertGroup(g);
              if (!mounted) return;
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: const Text(
              "Save group",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
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