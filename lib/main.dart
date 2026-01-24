import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await NotificationService.init();
  runApp(const SimpleDayApp());
}

class SimpleDayApp extends StatelessWidget {
  const SimpleDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Day',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TodayScreen(),
    );
  }
}

enum TaskPriority { high, medium, low }

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final TextEditingController controller = TextEditingController();
  Map<String, List<Map<String, dynamic>>> tasksByDate = {};

  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  int timerSeconds = 0;
  bool timerRunning = false;

  String get keyDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasks');
    if (raw == null) return;

    setState(() {
      tasksByDate = Map<String, List<Map<String, dynamic>>>.from(
        jsonDecode(raw).map(
          (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)),
        ),
      );
    });
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(tasksByDate));
  }

  void addTask(String title, TaskPriority priority) {
    if (title.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final list = tasksByDate[keyDate] ?? [];

    DateTime? alarmTime;
    if (selectedTime != null) {
      alarmTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      NotificationService.schedule(
        id: id,
        title: '⏰ Simple Day',
        body: title,
        dateTime: alarmTime,
      );
    }

    list.add({
      'id': id,
      'title': title,
      'priority': priority.index,
      'done': false,
      'time': selectedTime == null
          ? null
          : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
    });

    setState(() {
      tasksByDate[keyDate] = list;
      controller.clear();
      selectedTime = null;
    });

    saveTasks();
  }

  void toggleTask(int index) {
    setState(() {
      tasksByDate[keyDate]![index]['done'] =
          !tasksByDate[keyDate]![index]['done'];
    });
    saveTasks();
  }

  void deleteTask(int index) {
    setState(() {
      tasksByDate[keyDate]!.removeAt(index);
    });
    saveTasks();
  }

  Color priorityColor(int i) {
    switch (TaskPriority.values[i]) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = tasksByDate[keyDate] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Day'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () {
              setState(() {
                timerSeconds = 25 * 60;
                timerRunning = true;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (timerRunning)
              Text(
                '⏱ ${(timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(timerSeconds % 60).toString().padLeft(2, '0')}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (_, i) {
                  final t = tasks[i];
                  return Dismissible(
                    key: Key(t['id'].toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => deleteTask(i),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child:
                          const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          t['done']
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                        ),
                        onPressed: () => toggleTask(i),
                      ),
                      title: Text(t['title']),
                      subtitle:
                          t['time'] != null ? Text('⏰ ${t['time']}') : null,
                      trailing: CircleAvatar(
                        radius: 6,
                        backgroundColor:
                            priorityColor(t['priority']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          TaskPriority priority = TaskPriority.medium;

          showModalBottomSheet(
            context: context,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(hintText: 'Задача'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                    },
                    child: const Text('Выбрать время'),
                  ),
                  DropdownButton<TaskPriority>(
                    value: priority,
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (v) => priority = v!,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      addTask(controller.text, priority);
                      Navigator.pop(context);
                    },
                    child: const Text('Добавить'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
