import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import '../../controllers/rules_controller.dart';
import '../../models/app_rule.dart';
import '../pages/app_picker_page.dart';
import '../pages/group_editor_page.dart';
import 'lock_options_sheet.dart';
import '../../models/lock_request.dart';

class FabAdd extends ConsumerWidget {
  const FabAdd({super.key});

  Future<void> _handleQuickLock(BuildContext context, WidgetRef ref) async {
    final picked = await Navigator.of(context).push<AppInfo>(
      MaterialPageRoute(builder: (_) => const AppPickerPage()),
    );
    if (picked == null || !context.mounted) return;

    String? message;
    if (context.mounted) {
      final wantMsg = await showDialog<bool>(
        context: context,
        builder: (_) => _AskMessageDialog(appName: picked.name),
      );

      if (wantMsg == true && context.mounted) {
        message = await showDialog<String>(
          context: context,
          builder: (_) => _EnterMessageDialog(appName: picked.name),
        );
        message = (message == null || message.trim().isEmpty) ? null : message.trim();
      }
    }

    if (!context.mounted) return;

    final res = await showModalBottomSheet<LockRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LockOptionsSheet(appName: picked.name),
    );

    if (res == null || !context.mounted) return;

    if (res.mode == LockMode.quick) {
      await ref.read(rulesProvider.notifier).addQuick(
            picked.packageName,
            picked.name,
            res.duration!,
            message,
          );
    } else {
      await ref.read(rulesProvider.notifier).addScheduled(
            picked.packageName,
            picked.name,
            res.schedule!,
            message,
          );
    }
  }

  Future<void> _handleGroupCreation(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GroupEditorPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Lock an app"),
                    onTap: () => Navigator.pop(ctx, 'quick'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_special_outlined),
                    title: const Text("Create a group schedule"),
                    onTap: () => Navigator.pop(ctx, 'group'),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!context.mounted) return;

        if (action == 'quick') {
          await _handleQuickLock(context, ref);
        } else if (action == 'group') {
          await _handleGroupCreation(context);
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class _AskMessageDialog extends StatelessWidget {
  final String appName;

  const _AskMessageDialog({required this.appName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Show a message?"),
      content: Text(
        "Do you want to display a message when $appName is opened during a lock?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("No"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes"),
        ),
      ],
    );
  }
}

class _EnterMessageDialog extends StatefulWidget {
  final String appName;

  const _EnterMessageDialog({required this.appName});

  @override
  State<_EnterMessageDialog> createState() => _EnterMessageDialogState();
}

class _EnterMessageDialogState extends State<_EnterMessageDialog> {
  final ctl = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Custom message"),
      content: TextField(
        controller: ctl,
        maxLength: 120,
        decoration: InputDecoration(
          hintText: 'e.g., "Stay focused ✨ Come back later."',
          labelText: "Message",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Skip"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, ctl.text.trim()),
          child: const Text("Save"),
        ),
      ],
    );
  }
}

// lock request is defined in models/lock_request.dart