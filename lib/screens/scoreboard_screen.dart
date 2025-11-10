// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_state.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // Demo peers + the user; sort by completed desc
    final players = <_Player>[
      _Player('Aarav', 7),
      _Player('Meera', 6),
      _Player('Sid', 5),
      _Player('You', app.puzzlesCompleted),
    ]..sort((a, b) => b.completed.compareTo(a.completed));

    // Top 3 for podium, rest below
    final podium = players.take(3).toList();
    final rest = players.length > 3 ? players.sublist(3) : <_Player>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoreboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite friends',
            onPressed: () => _showInviteDialog(context, app),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _MetricPill(
            icon: Icons.grid_4x4,
            label: 'Bingo / Puzzles completed',
            value: app.puzzlesCompleted.toString(),
          ),
          const SizedBox(height: 12),
          _MetricPill(
            icon: Icons.stars_rounded,
            label: 'Reward points',
            value: app.rewardPoints.toString(),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top finishers', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _showInviteDialog(context, app),
                icon: const Icon(Icons.share),
                label: const Text('Invite'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _PodiumRow(players: podium),

          if (rest.isNotEmpty) const SizedBox(height: 16),
          if (rest.isNotEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  for (final p in rest) ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(p.name),
                    trailing: Text('${p.completed}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricPill({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<_Player> players; // top 3 (already sorted)
  const _PodiumRow({required this.players});

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD54F);
    final silver = const Color(0xFFB0BEC5);
    final bronze = const Color(0xFFB87333);

    // ensure 3 slots
    final p = List<_Player?>.from(players);
    while (p.length < 3) { p.add(null); }

    Widget _col(_Player? pl, int place, Color color, double h) {
      return Expanded(
        child: Column(
          children: [
            Text(
              place == 1 ? '1st' : place == 2 ? '2nd' : '3rd',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: h,
              decoration: BoxDecoration(
                color: color.withOpacity(.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: color),
                    const SizedBox(height: 4),
                    Text(pl?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(pl != null ? '${pl.completed}' : '—'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _col(p[1], 2, silver, 110),
        const SizedBox(width: 8),
        _col(p[0], 1, gold, 140),
        const SizedBox(width: 8),
        _col(p[2], 3, bronze, 95),
      ],
    );
  }
}

class _Player {
  final String name;
  final int completed;
  _Player(this.name, this.completed);
}

Future<void> _showInviteDialog(BuildContext context, AppState app) async {
  final inviteText = 'Join me on SpendSense! I\'ve completed ${app.puzzlesCompleted} bingo challenges. Can you beat my score? Download the app and let\'s compete! 🎯';
  
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Invite Friends'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share SpendSense with your friends and compete on the scoreboard!'),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: inviteText),
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Invite message',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => _inviteFromContacts(context, inviteText),
          icon: const Icon(Icons.contacts),
          label: const Text('From Contacts'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final uri = Uri(
              scheme: 'sms',
              body: inviteText,
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              // Fallback to share
              final shareUri = Uri.parse('sms:?body=${Uri.encodeComponent(inviteText)}');
              if (await canLaunchUrl(shareUri)) {
                await launchUrl(shareUri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open messaging app')),
                );
              }
            }
          },
          icon: const Icon(Icons.message),
          label: const Text('Send SMS'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final uri = Uri(
              scheme: 'mailto',
              subject: 'Join me on SpendSense!',
              body: inviteText,
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open email app')),
              );
            }
          },
          icon: const Icon(Icons.email),
          label: const Text('Email'),
        ),
      ],
    ),
  );
}

Future<void> _inviteFromContacts(BuildContext context, String inviteText) async {
  Navigator.pop(context); // Close the first dialog
  
  // Request contacts permission using flutter_contacts
  final permissionGranted = await FlutterContacts.requestPermission();
  if (!permissionGranted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contacts permission is required to invite friends'),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
    return;
  }

  // Get contacts
  final contacts = await FlutterContacts.getContacts(withProperties: true);
  if (contacts.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts found')),
      );
    }
    return;
  }

  // Show contact selection dialog
  final selectedContacts = <Contact>[];
  
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Select Contacts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isSelected = selectedContacts.contains(contact);
              final displayName = contact.displayName.isNotEmpty
                  ? contact.displayName
                  : 'Unknown';
              final phone = contact.phones.isNotEmpty
                  ? contact.phones.first.number
                  : null;
              
              return CheckboxListTile(
                title: Text(displayName),
                subtitle: phone != null ? Text(phone) : null,
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedContacts.add(contact);
                    } else {
                      selectedContacts.remove(contact);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: selectedContacts.isEmpty
                ? null
                : () async {
                    Navigator.pop(context);
                    await _sendInvitesToContacts(context, selectedContacts, inviteText);
                  },
            child: Text('Invite ${selectedContacts.length}'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _sendInvitesToContacts(
  BuildContext context,
  List<Contact> contacts,
  String inviteText,
) async {
  int successCount = 0;
  int failCount = 0;

  for (final contact in contacts) {
    if (contact.phones.isEmpty) {
      failCount++;
      continue;
    }

    final phone = contact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) {
      failCount++;
      continue;
    }

    try {
      final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(inviteText)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        successCount++;
        // Small delay to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        failCount++;
      }
    } catch (e) {
      failCount++;
    }
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount > 0
              ? 'Invited $successCount contact${successCount > 1 ? 's' : ''}'
              : 'Failed to send invites',
        ),
      ),
    );
  }
}
