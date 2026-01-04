import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  tz.initializeTimeZones();
  await NotificationService().init();
  runApp(const SimpleDayApp());
}

class SimpleDayApp extends StatelessWidget {
  const SimpleDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      title: 'Simple Day',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const TodayScreen(),
    );
  }
}

enum TaskPriority { high, medium, low }

class Task {
  String title;
  String category;
  TaskPriority priority;
  bool done;
  DateTime? reminder;

  Task({
    required this.title,
    required this.category,
    required this.priority,
    this.done = false,
    this.reminder,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'priority': priority.index,
        'done': done,
        'reminder': reminder?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        category: json['category'],
        priority: TaskPriority.values[json['priority']],
        done: json['done'],
        reminder: json['reminder'] != null
            ? DateTime.parse(json['reminder'])
            : null,
      );
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  Future<void> scheduleNotification(
      int id, String title, String body, DateTime time) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks',
          'Task reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final controller = TextEditingController();
  List<Task> tasks = [];
  TaskPriority priority = TaskPriority.medium;
  String category = 'Личное';
  DateTime? reminder;

  final categories = ['Работа', 'Учёба', 'Личное', 'Покупки'];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasks');
    if (raw == null) return;

    final list = jsonDecode(raw) as List;
    setState(() {
      tasks = list.map((e) => Task.fromJson(e)).toList();
    });
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tasks',
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    );
  }

  void addTask() {
    if (controller.text.trim().isEmpty) return;

    final task = Task(
      title: controller.text.trim(),
      category: category,
      priority: priority,
      reminder: reminder,
    );

    setState(() {
      tasks.add(task);
    });

    if (reminder != null) {
      NotificationService().scheduleNotification(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Напоминание',
        task.title,
        reminder!,
      );
    }

    controller.clear();
    reminder = null;
    saveTasks();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final today =
        DateFormat('dd MMMM yyyy', 'ru').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text('Сегодня · $today')),
      body: tasks.isEmpty
          ? const Center(child: Text('Задач нет'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final t = tasks[i];
                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: t.done,
                      onChanged: (v) {
                        setState(() => t.done = v!);
                        saveTasks();
                      },
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(
                        decoration: t.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(t.category),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() => tasks.removeAt(i));
                        saveTasks();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => Padding(
              padding: MediaQuery.of(context).viewInsets.add(
                    const EdgeInsets.all(16),
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => addTask(), // ENTER 🔥
                    decoration:
                        const InputDecoration(labelText: 'Название'),
                  ),
                  DropdownButton<String>(
                    value: category,
                    items: categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  DropdownButton<TaskPriority>(
                    value: priority,
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => priority = v!),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.alarm),
                    label: Text(reminder == null
                        ? 'Добавить напоминание'
                        : DateFormat('HH:mm').format(reminder!)),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        final now = DateTime.now();
                        reminder = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          time.hour,
                          time.minute,
                        );
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: addTask,
                    child: const Text('Добавить'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
