import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_rule.dart';
import '../models/app_group.dart';

class RulesStore {
  static const _rulesKey = 'zensta_rules_v3';
  static const _groupsKey = 'zensta_groups_v1';

  Future<List<AppRule>> readRules() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_rulesKey) ?? [];
    return raw.map((s) => AppRule.fromJson(jsonDecode(s))).toList();
  }

  Future<List<AppGroup>> readGroups() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_groupsKey) ?? [];
    return raw.map((s) => AppGroup.fromJson(jsonDecode(s))).toList();
  }

  Future<void> writeAll(List<AppRule> rules, List<AppGroup> groups) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
      _rulesKey,
      rules.map((r) => jsonEncode(r.toJson())).toList(),
    );
    await sp.setStringList(
      _groupsKey,
      groups.map((g) => jsonEncode(g.toJson())).toList(),
    );
  }
}