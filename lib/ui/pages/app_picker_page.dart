
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../theme.dart';
import '../../utils/app_name_formatter.dart';

class AppPickerPage extends StatefulWidget {
  const AppPickerPage({super.key});

  @override
  State<AppPickerPage> createState() => _AppPickerPageState();
}

class _AppPickerPageState extends State<AppPickerPage> {
  List<AppInfo> _apps = [], _filtered = [];
  final _searchCtl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtl.addListener(() {
      final q = _searchCtl.text.toLowerCase();
      setState(() {
        _filtered = _apps
            .where((a) {
              final cleanName = AppNameFormatter.getCleanName(a).toLowerCase();
              return cleanName.contains(q) || a.name.toLowerCase().contains(q);
            })
            .toList();
      });
    });
  }

  Future<void> _load() async {
    final all = await InstalledApps.getInstalledApps(true, true);
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      _apps = all;
      _filtered = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select app")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchCtl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search apps",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final app = _filtered[i];
                      final iconBytes = app.icon;
                      final ImageProvider<Object>? iconProvider =
                          (iconBytes != null && iconBytes.isNotEmpty)
                              ? MemoryImage(iconBytes)
                              : null;

                      final cleanName = AppNameFormatter.getCleanName(app);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: AppColors.card,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.mint.withValues(alpha: 51),
                                backgroundImage: iconProvider,
                                child: iconProvider == null
                                    ? Text(
                                        cleanName.isNotEmpty
                                            ? cleanName[0].toUpperCase()
                                            : "?",
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                cleanName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.pop(context, app),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}