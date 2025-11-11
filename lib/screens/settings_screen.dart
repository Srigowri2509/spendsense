// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_state.dart'; // formatCurrency + AppScope
import '../widgets/colorful_background.dart';
import 'sms_settings_screen.dart';
import 'subscriptions_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ColorfulBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
            Text('Settings', style: theme.textTheme.headlineMedium),

            const SizedBox(height: 12),

            // Profile
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(child: Text(app.userInitials)),
                title: Text(app.userDisplayName),
                subtitle: Text(app.userDisplayEmail),
                trailing: FilledButton(
                  onPressed: () => _push(context, const _SignInPage()),
                  child: Text(app.isSignedIn ? 'Edit' : 'Sign in'),
                ),
                onTap: () => _push(context, const _SignInPage()),
              ),
            ),

            const SizedBox(height: 8),

            // Appearance (inline toggle)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _ThemeSegment(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Notifications
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: const [
                  _NotifTile(
                    title: 'Budget alerts',
                    subtitle: 'Notify when nearing category limits',
                    which: _NotifKind.budget,
                  ),
                  Divider(height: 0),
                  _NotifTile(
                    title: 'Weekly insights',
                    subtitle: 'Summary of spending & tips',
                    which: _NotifKind.weekly,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Navigation rows
            _NavCard(children: [
              _NavRow(
                icon: Icons.tune_outlined,
                title: 'Budgets & Goals',
                onTap: () => _push(context, const _BudgetsSettingsPage()),
              ),
              _ListDivider(cs),
              _NavRow(
                icon: Icons.sms_outlined,
                title: 'SMS Import',
                subtitle: 'Auto-import from transaction SMS',
                onTap: () => _push(context, const SmsSettingsScreen()),
              ),
              _ListDivider(cs),
              _NavRow(
                icon: Icons.score_outlined,
                title: 'Scoreboard',
                onTap: () => _push(context, const _ScoreboardPage()),
              ),
              _ListDivider(cs),
              _NavRow(
                icon: Icons.subscriptions_outlined,
                title: 'Subscriptions',
                subtitle: 'Manage recurring payments',
                onTap: () => _push(context, const _SubscriptionsPage()),
              ),
              _ListDivider(cs),
              // TODO: Linked Banks - Future feature
              // _NavRow(
              //   icon: Icons.account_balance_outlined,
              //   title: 'Linked banks',
              //   onTap: () => _push(context, const _LinkedBanksPage()),
              // ),
            ]),

            const SizedBox(height: 8),

            // Logout
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                textColor: cs.error,
                iconColor: cs.error,
                onTap: () {
                  AppScope.of(context).signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out')),
                  );
                },
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- small reused bits ----------
class _NavCard extends StatelessWidget {
  final List<Widget> children;
  const _NavCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.title, this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ListDivider extends StatelessWidget {
  final ColorScheme cs;
  const _ListDivider(this.cs);
  @override
  Widget build(BuildContext context) => Divider(height: 0, thickness: 1, color: cs.outlineVariant);
}

// =====================================================
// THEME SEGMENT
// =====================================================
class _ThemeSegment extends StatefulWidget {
  const _ThemeSegment();
  @override
  State<_ThemeSegment> createState() => _ThemeSegmentState();
}

class _ThemeSegmentState extends State<_ThemeSegment> {
  String _mode = 'system';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    _mode = switch (app.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'system', label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
        ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
        ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
      ],
      selected: {_mode},
      onSelectionChanged: (s) {
        setState(() => _mode = s.first);
        final app = AppScope.of(context);
        app.setThemeMode(
          _mode == 'light' ? ThemeMode.light : _mode == 'dark' ? ThemeMode.dark : ThemeMode.system,
        );
      },
    );
  }
}

// =====================================================
// NOTIFICATIONS
// =====================================================
enum _NotifKind { budget, weekly }

class _NotifTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final _NotifKind which;
  const _NotifTile({required this.title, required this.subtitle, required this.which});

  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile> {
  bool? value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    value ??= widget.which == _NotifKind.budget ? app.notifBudgetAlerts : app.notifWeeklyInsights;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return SwitchListTile(
      value: value ?? false,
      onChanged: (v) {
        setState(() => value = v);
        if (widget.which == _NotifKind.budget) {
          app.toggleNotifBudget(v);
        } else {
          app.toggleWeeklyInsights(v);
        }
      },
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
    );
  }
}

// =====================================================
// Budgets & Goals editor
// =====================================================
class _BudgetsSettingsPage extends StatefulWidget {
  const _BudgetsSettingsPage();
  @override
  State<_BudgetsSettingsPage> createState() => _BudgetsSettingsPageState();
}

class _BudgetsSettingsPageState extends State<_BudgetsSettingsPage> {
  final TextEditingController _monthlyCtrl = TextEditingController();
  final Map<String, TextEditingController> _perCatCtrls = {};
  final Map<String, TextEditingController> _walletTargetCtrls = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final app = AppScope.of(context);

    _monthlyCtrl.text = app.monthlyBudget.toStringAsFixed(0);

    for (final c in app.categories) {
      _perCatCtrls[c.name] = TextEditingController(text: c.monthlyBudget.toStringAsFixed(0));
    }
    for (final w in app.wallets) {
      _walletTargetCtrls[w.id] = TextEditingController(text: w.target.toStringAsFixed(0));
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _monthlyCtrl.dispose();
    for (final c in _perCatCtrls.values) c.dispose();
    for (final c in _walletTargetCtrls.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets & Goals')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall monthly budget
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Monthly spending budget', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _monthlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 50000',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          // Per-category budgets
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const ListTile(
                  title: Text('Per-category budgets', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                for (final c in app.categories) ...[
                  ListTile(
                    leading: Icon(Icons.label_outline, color: c.color),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _perCatCtrls[c.name],
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        // Delete button for custom categories
                        if (c.type == CategoryType.custom && c.customId != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category?'),
                                  content: Text('Remove "${c.name}" category?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        app.removeCustomCategory(c.customId!);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Deleted ${c.name}')),
                                        );
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (c != app.categories.last) const Divider(height: 0),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Wallet goals (targets)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const ListTile(
                  title: Text('Wallet goals (targets)', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                for (final w in app.wallets) ...[
                  ListTile(
                    leading: Icon(w.icon, color: w.color),
                    title: Text(w.name),
                    subtitle: Text('Current: ${formatCurrency(w.balance)}'),
                    trailing: SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _walletTargetCtrls[w.id],
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  if (w != app.wallets.last) const Divider(height: 0),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _saveBudgets,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveBudgets() {
    final app = AppScope.of(context);

    final overall = int.tryParse(_monthlyCtrl.text.trim());
    if (overall != null) app.setMonthlyBudget(overall);

    _perCatCtrls.forEach((name, ctrl) {
      final v = int.tryParse(ctrl.text.trim());
      if (v != null) app.setCategoryBudget(name, v);
    });

    _walletTargetCtrls.forEach((id, ctrl) {
      final v = double.tryParse(ctrl.text.trim());
      if (v != null) app.setWalletTarget(id, v);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budgets & goals saved')),
    );
  }
}

// =====================================================
// Wallets page (Deposit / Withdraw / Set goal)
// =====================================================
class _WalletsSettingsPage extends StatelessWidget {
  const _WalletsSettingsPage();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    String money(num n) => formatCurrency(n, symbol: app.currencySymbol);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: app.wallets.length,
        itemBuilder: (context, i) {
          final w = app.wallets[i];
          final pct = w.target <= 0 ? 0.0 : (w.balance / w.target).clamp(0.0, 1.0).toDouble();
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(w.icon, color: w.color),
                  title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: pct, minHeight: 8),
                      const SizedBox(height: 4),
                      Text('Balance: ${money(w.balance)} • Goal: ${money(w.target)}'),
                    ],
                  ),
                ),
                const Divider(height: 0),
                ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.call_received_outlined),
                      label: const Text('Deposit'),
                      onPressed: () async {
                        final amt = await _askAmountWallet(context, label: 'Deposit amount');
                        if (amt != null) {
                          app.depositToWallet(w.id, amt);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deposited ${money(amt)} to ${w.name}')),
                          );
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.call_made_outlined),
                      label: const Text('Withdraw to bank'),
                      onPressed: () async {
                        final res = await _askWithdrawWallet(context);
                        if (res == null) return;
                        final (amount, bankId) = res;
                        app.withdrawFromWallet(w.id, amount);
                        final bank = app.banks.firstWhere((b) => b.id == bankId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Transferred ${money(amount)} from ${w.name} to ${bank.name}')),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Set goal'),
                      onPressed: () async {
                        final amt = await _askAmountWallet(context, label: 'Wallet goal (target)');
                        if (amt != null) {
                          app.setWalletTarget(w.id, amt);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Goal set to ${money(amt)}')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

// dialogs for wallets page (unique names to avoid clashes)
Future<double?> _askAmountWallet(BuildContext context, {required String label}) async {
  final ctrl = TextEditingController();
  return showDialog<double>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(label),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text.trim())),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<(double, String)?> _askWithdrawWallet(BuildContext context) async {
  final app = AppScope.of(context);
  double? amount;
  String? bankId = app.banks.isNotEmpty ? app.banks.first.id : null;

  return showDialog<(double, String)>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Withdraw to bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount'),
              onChanged: (t) => amount = double.tryParse(t.trim()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: bankId,
              items: app.banks
                  .map((b) => DropdownMenuItem(value: b.id, child: Text('${b.name} (${b.type})')))
                  .toList(),
              onChanged: (v) => setState(() => bankId = v),
              decoration: const InputDecoration(labelText: 'Bank account'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (amount != null && bankId != null) Navigator.pop(context, (amount!, bankId!));
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    ),
  );
}

// =====================================================
// SIMPLE SIGN-IN (profile editor)
// =====================================================
class _SignInPage extends StatefulWidget {
  const _SignInPage();
  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final nickCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    nickCtrl.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final app = AppScope.of(context);
  return Scaffold(
    appBar: AppBar(title: const Text('Profile / Sign in')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nickCtrl,
          decoration: const InputDecoration(labelText: 'Nickname (optional)'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            app.signInDemo(
              name: nameCtrl.text.trim().isEmpty ? 'Guest' : nameCtrl.text.trim(),
              email: emailCtrl.text.trim().isEmpty ? 'guest@example.com' : emailCtrl.text.trim(),
              nick: nickCtrl.text.trim(),
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    ),
  );
}

}

// =====================================================
// Linked banks
// =====================================================
class _LinkedBanksPage extends StatelessWidget {
  const _LinkedBanksPage();
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Linked banks')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: app.banks.length,
        itemBuilder: (_, i) {
          final b = app.banks[i];
          return Card(
            elevation: 0,
            child: SwitchListTile(
              value: b.linked,
              onChanged: (_) => app.toggleBank(b.id),
              title: Text(b.name),
              subtitle: Text(b.type),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// Scoreboard (podium + rest)
// =====================================================
class _SubscriptionsPage extends StatelessWidget {
  const _SubscriptionsPage();
  @override
  Widget build(BuildContext context) {
    return const SubscriptionsScreen();
  }
}

class _ScoreboardPage extends StatelessWidget {
  const _ScoreboardPage();
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    final players = <_Player>[
      _Player('You', app.puzzlesCompleted),
      _Player('Aarav', 7),
      _Player('Meera', 6),
      _Player('Sid', 5),
      _Player('Kia', 4),
      _Player('Zoe', 3),
    ]..sort((a, b) => b.completed.compareTo(a.completed));

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
        padding: const EdgeInsets.all(16),
        children: [
          _Stat('Bingo / Puzzles completed', app.puzzlesCompleted.toString(), Icons.grid_4x4),
          const SizedBox(height: 10),
          _Stat('Reward points', app.rewardPoints.toString(), Icons.stars_outlined),

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

          _PodiumRow(podium),

          if (rest.isNotEmpty) const SizedBox(height: 12),
          if (rest.isNotEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  for (final p in rest)
                    ListTile(
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

class _Player {
  final String name;
  final int completed;
  _Player(this.name, this.completed);
}

class _PodiumRow extends StatelessWidget {
  final List<_Player> top3; // already sorted desc
  const _PodiumRow(this.top3);

  @override
  Widget build(BuildContext context) {
    final gold   = const Color(0xFFFFD54F);
    final silver = const Color(0xFFB0BEC5);
    final bronze = const Color(0xFFB87333);

    final p = List<_Player?>.from(top3);
    while (p.length < 3) p.add(null);

    Widget col(_Player? pl, String place, Color color, double h) {
      return Expanded(
        child: Column(
          children: [
            Text(place, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: h,
              decoration: BoxDecoration(
                color: color.withOpacity(.22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(.55)),
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
        col(p[1], '2nd', silver, 110),
        const SizedBox(width: 8),
        col(p[0], '1st', gold, 140),
        const SizedBox(width: 8),
        col(p[2], '3rd', bronze, 95),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String title; final String value; final IconData icon;
  const _Stat(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value),
      ]),
    );
  }
}

// Alias so either name works
typedef SettingsScreen = SettingsPage;

// helper
void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

// Invite dialog for scoreboard
Future<void> _showInviteDialog(BuildContext context, AppState app) async {
  final inviteText = '🎯 Join me on SpendSense Bingo Leaderboard! 🎯\n\n'
      'I\'ve completed ${app.puzzlesCompleted} bingo challenges and earned ${app.rewardPoints} reward points!\n\n'
      'Download SpendSense app and compete with me on the leaderboard. '
      'Track expenses, complete bingo challenges, and see who can reach the top! 🏆\n\n'
      'Can you beat my score? Let\'s compete! 💪';
  
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Invite to Bingo Leaderboard'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invite your friends to download SpendSense and join the bingo leaderboard!'),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: inviteText),
            maxLines: 8,
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
            final uri = Uri.parse('sms:?body=${Uri.encodeComponent(inviteText)}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open messaging app')),
              );
            }
          },
          icon: const Icon(Icons.message),
          label: const Text('Send SMS'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final subject = Uri.encodeComponent('Join me on SpendSense Bingo Leaderboard!');
            final body = Uri.encodeComponent(inviteText);
            final uri = Uri.parse('mailto:?subject=$subject&body=$body');
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
              ? 'Invited $successCount contact${successCount > 1 ? 's' : ''} to join the leaderboard!'
              : 'Failed to send invites',
        ),
      ),
    );
  }
}
