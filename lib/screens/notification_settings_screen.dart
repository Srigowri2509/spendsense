// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_state.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    final app = AppScope.of(context);
    final granted = await app.notificationService.requestPermissions();
    
    setState(() => _hasPermission = granted);
    
    if (granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission granted')),
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
        title: const Text('Notification Permission Required'),
        content: const Text(
          'SpendSense needs notification permission to remind you about upcoming subscription payments.\n\n'
          'You can enable this in your device settings.',
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

  Future<void> _sendTestNotification() async {
    final app = AppScope.of(context);
    
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    try {
      await app.notificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final app = AppScope.of(context);
    final settings = app.notificationSettings;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              _hasPermission ? Icons.check_circle : Icons.warning,
              color: _hasPermission ? Colors.green : Colors.orange,
            ),
            title: const Text('Notification Permission'),
            subtitle: Text(_hasPermission ? 'Granted' : 'Not granted'),
            trailing: _hasPermission
                ? null
                : FilledButton(
                    onPressed: _requestPermission,
                    child: const Text('Grant'),
                  ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Enable Subscription Notifications'),
            subtitle: const Text('Get reminders for upcoming payments'),
            value: settings.enabled,
            onChanged: (value) async {
              final updated = NotificationSettings(
                enabled: value,
                notify3DaysBefore: settings.notify3DaysBefore,
                notify1DayBefore: settings.notify1DayBefore,
                notifyOnDueDate: settings.notifyOnDueDate,
                notifyRenewalReminders: settings.notifyRenewalReminders,
              );
              await app.updateNotificationSettings(updated);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notification Timing',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: const Text('3 Days Before'),
            subtitle: const Text('Notify 3 days before payment'),
            value: settings.notify3DaysBefore,
            onChanged: settings.enabled
                ? (value) async {
                    final updated = NotificationSettings(
                      enabled: settings.enabled,
                      notify3DaysBefore: value,
                      notify1DayBefore: settings.notify1DayBefore,
                      notifyOnDueDate: settings.notifyOnDueDate,
                      notifyRenewalReminders: settings.notifyRenewalReminders,
                    );
                    await app.updateNotificationSettings(updated);
                  }
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.event),
            title: const Text('1 Day Before'),
            subtitle: const Text('Notify 1 day before payment'),
            value: settings.notify1DayBefore,
            onChanged: settings.enabled
                ? (value) async {
                    final updated = NotificationSettings(
                      enabled: settings.enabled,
                      notify3DaysBefore: settings.notify3DaysBefore,
                      notify1DayBefore: value,
                      notifyOnDueDate: settings.notifyOnDueDate,
                      notifyRenewalReminders: settings.notifyRenewalReminders,
                    );
                    await app.updateNotificationSettings(updated);
                  }
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.today),
            title: const Text('On Due Date'),
            subtitle: const Text('Notify on payment day'),
            value: settings.notifyOnDueDate,
            onChanged: settings.enabled
                ? (value) async {
                    final updated = NotificationSettings(
                      enabled: settings.enabled,
                      notify3DaysBefore: settings.notify3DaysBefore,
                      notify1DayBefore: settings.notify1DayBefore,
                      notifyOnDueDate: value,
                      notifyRenewalReminders: settings.notifyRenewalReminders,
                    );
                    await app.updateNotificationSettings(updated);
                  }
                : null,
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.autorenew),
            title: const Text('Renewal Reminders'),
            subtitle: const Text('Get advance notice for subscription renewals'),
            value: settings.notifyRenewalReminders,
            onChanged: settings.enabled
                ? (value) async {
                    final updated = NotificationSettings(
                      enabled: settings.enabled,
                      notify3DaysBefore: settings.notify3DaysBefore,
                      notify1DayBefore: settings.notify1DayBefore,
                      notifyOnDueDate: settings.notifyOnDueDate,
                      notifyRenewalReminders: value,
                    );
                    await app.updateNotificationSettings(updated);
                  }
                : null,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
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
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'About Notifications',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Notifications help you stay on top of subscription payments\n'
                      '• You can customize when you receive reminders\n'
                      '• Renewal reminders give you time to review subscriptions\n'
                      '• All notifications are processed locally on your device',
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
