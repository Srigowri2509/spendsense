import 'schedule.dart';

class AppGroup {
  final String id;
  final String title;
  final List<String> packages;
  final Map<String, String> names;
  final Schedule schedule;
  final String? customMessage;

  AppGroup({
    required this.id,
    required this.title,
    required this.packages,
    required this.names,
    required this.schedule,
    this.customMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pkgs': packages,
        'names': names,
        'schedule': schedule.toJson(),
        'msg': customMessage,
      };

  factory AppGroup.fromJson(Map<String, dynamic> j) => AppGroup(
        id: j['id'],
        title: j['title'],
        packages: (j['pkgs'] as List).cast<String>(),
        names: (j['names'] as Map).cast<String, String>(),
        schedule: Schedule.fromJson(j['schedule']),
        customMessage: j['msg'],
      );
}