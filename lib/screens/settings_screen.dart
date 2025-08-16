import 'package:flutter/material.dart';
import '../app_state.dart';
import 'linked_banks_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _savingsC;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _savingsC = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hydrated) {
      final state = AppScope.of(context);
      _savingsC.text = state.monthlySavingsTarget.toStringAsFixed(0);
      _hydrated = true;
    }
  }

  @override
  void dispose() {
    _savingsC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ===== Profile Header =====
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _Avatar(photoUrl: state.userPhotoUrl, initials: state.userInitials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.userDisplayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(state.userDisplayEmail, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (!state.isSignedIn)
                    FilledButton(onPressed: () => _showSignInSheet(context, state), child: const Text('Sign in'))
                  else
                    OutlinedButton(onPressed: () => state.signOut(), child: const Text('Sign out')),
                ],
              ),
            ),
          ),

          _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (s) => state.setThemeMode(s.first),
            ),
          ),

          _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Budget alerts'),
            subtitle: const Text('Notify when nearing category limits'),
            value: state.notifBudgetAlerts,
            onChanged: state.toggleNotifBudget,
          ),
          SwitchListTile(
            title: const Text('Weekly insights'),
            subtitle: const Text('Summary of spending & tips'),
            value: state.notifWeeklyInsights,
            onChanged: state.toggleWeeklyInsights,
          ),

          _SectionHeader('Savings & Fixed Money'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _savingsC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monthly savings target (₹)'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    final v = double.tryParse(_savingsC.text.trim());
                    if (v == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                      return;
                    }
                    state.setMonthlySavingsTarget(v);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Savings target updated')));
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Fixed commitments (from subscriptions)'),
            subtitle: Text(formatCurrency(state.fixedMonthlyTotal, symbol: state.currencySymbol)),
          ),
          ListTile(
            title: const Text('Target after fixed'),
            subtitle: Text(formatCurrency(state.savingsTargetAfterFixed, symbol: state.currencySymbol)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Count these as fixed', style: Theme.of(context).textTheme.titleSmall),
          ),
          ...state.subscriptions.map((s) => Card(
                child: SwitchListTile(
                  value: s.isFixed,
                  onChanged: (v) => state.setSubscriptionFixed(s.id, v),
                  title: Text(s.name),
                  subtitle: Text('₹${s.amount.toStringAsFixed(0)} • Day ${s.billingDay}'),
                ),
              )),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _showAddSubscriptionDialog(context, state),
              icon: const Icon(Icons.add),
              label: const Text('Add subscription'),
            ),
          ),

          _SectionHeader('Data & Accounts'),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Linked banks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, LinkedBanksScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear demo data'),
            subtitle: const Text('Reset transactions, rewards & puzzle'),
            onTap: () {
              state.clearDemoData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo data cleared')));
            },
          ),

          const SizedBox(height: 24),
          Center(child: Text('v1.0.0 • SpendSense', style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===== New: Pretty sign-in bottom sheet with providers + nickname =====
  void _showSignInSheet(BuildContext context, AppState state) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final nickC = TextEditingController();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sign in',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _ProviderIcon(bg: Color(0xFF4285F4), icon: Icons.g_mobiledata, label: 'Google'),
                SizedBox(width: 12),
                _ProviderIcon(bg: Colors.black, icon: Icons.apple, label: 'Apple'),
                SizedBox(width: 12),
                _ProviderIcon(bg: Color(0xFF1877F2), icon: Icons.facebook, label: 'Facebook'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameC),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Nickname (how we call you)'),
              controller: nickC,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final n = nameC.text.trim().isEmpty ? 'Guest' : nameC.text.trim();
                      final e = emailC.text.trim().isEmpty ? 'guest@example.com' : emailC.text.trim();
                      final nick = nickC.text.trim();
                      state.signInDemo(name: n, email: e, nick: nick);
                      Navigator.pop(context);
                    },
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Provider icons are placeholders. We’ll plug real Google/Apple/Facebook auth later.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context, AppState state) {
    final nameC = TextEditingController();
    final amtC = TextEditingController();
    final dayC = TextEditingController(text: '1');
    bool isFixed = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameC),
                const SizedBox(height: 8),
                TextField(decoration: const InputDecoration(labelText: 'Amount (₹)'), controller: amtC, keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(decoration: const InputDecoration(labelText: 'Billing day (1-28)'), controller: dayC, keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Count as fixed'),
                  value: isFixed,
                  onChanged: (v) => setLocal(() => isFixed = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = nameC.text.trim();
                final amt = double.tryParse(amtC.text.trim());
                final day = int.tryParse(dayC.text.trim());
                if (name.isEmpty || amt == null || amt <= 0 || day == null || day < 1 || day > 28) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid details')));
                  return;
                }
                state.addSubscription(name: name, amount: amt, billingDay: day, isFixed: isFixed);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  const _Avatar({required this.photoUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.primary.withValues(alpha: .12);
    final fg = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: 28,
      backgroundColor: bg,
      foregroundImage: (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(initials, style: TextStyle(color: fg, fontWeight: FontWeight.w700))
          : null,
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final String label;
  const _ProviderIcon({required this.bg, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 18, backgroundColor: bg, child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
