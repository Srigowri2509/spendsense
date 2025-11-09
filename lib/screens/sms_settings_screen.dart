// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sms_service.dart';
import '../services/sms_parser.dart';
import '../services/transaction_import_service.dart';
import '../app_state.dart';
import 'sms_import_screen.dart';

class SmsSettingsScreen extends StatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  State<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends State<SmsSettingsScreen> {
  bool _hasPermission = false;
  bool _isEnabled = true;
  int _daysBack = 90;
  DateTime? _lastImportDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final smsService = SmsService();
    final hasPermission = await smsService.hasPermission();
    
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('sms_import_enabled') ?? true;
    final daysBack = prefs.getInt('sms_days_back') ?? 90;
    
    final app = AppScope.of(context);
    final importService = TransactionImportService(smsService, SmsParser(), app);
    final lastImport = await importService.getLastImportDate();

    setState(() {
      _hasPermission = hasPermission;
      _isEnabled = isEnabled;
      _daysBack = daysBack;
      _lastImportDate = lastImport;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    final smsService = SmsService();
    final granted = await smsService.requestPermission();
    
    if (granted) {
      setState(() => _hasPermission = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission granted')),
        );
      }
    } else {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'SpendWise needs SMS permission to read transaction messages and automatically import your expenses.\n\n'
          'We only read transaction-related SMS from payment apps and banks. Your SMS data is processed locally and never shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_import_enabled', value);
    setState(() => _isEnabled = value);
  }

  Future<void> _setDaysBack(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sms_days_back', days);
    setState(() => _daysBack = days);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Import History?'),
        content: const Text('This will allow previously imported SMS to be imported again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final app = AppScope.of(context);
      final smsService = SmsService();
      final importService = TransactionImportService(smsService, SmsParser(), app);
      await importService.clearImportHistory();
      
      setState(() => _lastImportDate = null);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import history cleared')),
        );
      }
    }
  }

  void _navigateToImport() {
    if (!_hasPermission) {
      _requestPermission();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmsImportScreen(daysBack: _daysBack),
      ),
    ).then((_) => _loadSettings());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('SMS Import')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Import')),
      body: ListView(
        children: [
          // Permission Status
          ListTile(
            leading: Icon(
              _hasPermission ? Icons.check_circle : Icons.warning,
              color: _hasPermission ? Colors.green : Colors.orange,
            ),
            title: const Text('SMS Permission'),
            subtitle: Text(_hasPermission ? 'Granted' : 'Not granted'),
            trailing: _hasPermission
                ? null
                : FilledButton(
                    onPressed: _requestPermission,
                    child: const Text('Grant'),
                  ),
          ),

          const Divider(),

          // Enable/Disable
          SwitchListTile(
            secondary: const Icon(Icons.sms),
            title: const Text('Enable SMS Import'),
            subtitle: const Text('Automatically import transactions from SMS'),
            value: _isEnabled,
            onChanged: _toggleEnabled,
          ),

          const Divider(),

          // Date Range
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Scan Period'),
            subtitle: Text('Last $_daysBack days'),
            trailing: DropdownButton<int>(
              value: _daysBack,
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 60, child: Text('60 days')),
                DropdownMenuItem(value: 90, child: Text('90 days')),
              ],
              onChanged: (value) {
                if (value != null) _setDaysBack(value);
              },
            ),
          ),

          // Last Import
          if (_lastImportDate != null)
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Last Import'),
              subtitle: Text(
                '${_lastImportDate!.day}/${_lastImportDate!.month}/${_lastImportDate!.year} at ${_lastImportDate!.hour}:${_lastImportDate!.minute.toString().padLeft(2, '0')}',
              ),
            ),

          const Divider(),

          // Import Now Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _isEnabled ? _navigateToImport : null,
              icon: const Icon(Icons.download),
              label: const Text('Import Now'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),

          // Clear History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear Import History'),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy Notice
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.privacy_tip_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Privacy & Security',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• We only read transaction SMS from payment apps and banks\n'
                      '• SMS content is processed locally on your device\n'
                      '• Only transaction details (amount, merchant, date) are stored\n'
                      '• Full SMS content is never stored or transmitted\n'
                      '• You can disable this feature anytime',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
