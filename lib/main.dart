import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await NotificationService().init();
  runApp(const SimpleDayApp());
}

class SimpleDayApp extends StatelessWidget {
  const SimpleDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const TodayScreen(),
    );
  }
}

enum TaskPriority { high, medium, low }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_priority_channel',
      'High Priority Tasks',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final TextEditingController controller = TextEditingController();
  Map<String, List<Map<String, dynamic>>> tasksByDate = {};
  DateTime selectedDate = DateTime.now();
  String filterCategory = 'Все';
  final List<String> categories = ['Все', 'Работа', 'Учёба', 'Личное', 'Покупки'];

  String get selectedKey => DateFormat('yyyy-MM-dd').format(selectedDate);

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasksByDate');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        tasksByDate = decoded.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
      });
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasksByDate', jsonEncode(tasksByDate));
  }

  void addTask(String title, String category, TaskPriority priority) {
    if (title.trim().isEmpty) return;
    final dayTasks = tasksByDate[selectedKey] ?? [];
    setState(() {
      dayTasks.add({
        'title': title.trim(),
        'category': category,
        'priority': priority.index,
        'done': false
      });
      tasksByDate[selectedKey] = dayTasks;
    });
    saveTasks();
    if (priority == TaskPriority.high) {
      NotificationService().showNotification('Важная задача', '$title ($category)');
    }
  }

  void toggleTask(int index) {
    setState(() {
      tasksByDate[selectedKey]![index]['done'] = !tasksByDate[selectedKey]![index]['done'];
    });
    saveTasks();
  }

  void deleteTask(int index) {
    setState(() {
      tasksByDate[selectedKey]!.removeAt(index);
    });
    saveTasks();
  }

  void previousDay() => setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
  void nextDay() => setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));

  Color priorityColor(int index) {
    switch (TaskPriority.values[index]) {
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
    List<Map<String, dynamic>> dayTasks = tasksByDate[selectedKey] ?? [];
    if (filterCategory != 'Все') {
      dayTasks = dayTasks.where((t) => t['category'] == filterCategory).toList();
    }
    dayTasks.sort((a, b) => b['priority'].compareTo(a['priority']));
    final dayLabel = DateFormat('dd MMMM yyyy', 'ru').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Day'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('ru'),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: previousDay),
                Text(dayLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.arrow_forward), onPressed: nextDay),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((cat) {
                  final isSelected = filterCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(label: Text(cat), selected: isSelected, onSelected: (_) => setState(() => filterCategory = cat)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: dayTasks.isEmpty
                  ? const Center(child: Text('Дел нет'))
                  : ListView.builder(
                      itemCount: dayTasks.length,
                      itemBuilder: (context, index) {
                        final task = dayTasks[index];
                        return Dismissible(
                          key: Key(task['title'] + index.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => deleteTask(index),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: IconButton(
                                icon: Icon(
                                  task['done'] ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: task['done'] ? Colors.green : Colors.grey,
                                ),
                                onPressed: () => toggleTask(index),
                              ),
                              title: Text(task['title']),
                              subtitle: Text(task['category']),
                              trailing: CircleAvatar(radius: 8, backgroundColor: priorityColor(task['priority'])),
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
        onPressed: () {
          String selectedCategory = categories[1];
          TaskPriority selectedPriority = TaskPriority.medium;

          showModalBottomSheet(
            context: context,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onSubmitted: (_) {
                      addTask(controller.text, selectedCategory, selectedPriority);
                      controller.clear();
                      Navigator.pop(context);
                    },
                    decoration: const InputDecoration(hintText: 'Название задачи'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: categories.where((c) => c != 'Все').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) {
                      if (value != null) selectedCategory = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<TaskPriority>(
                    value: selectedPriority,
                    items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                    onChanged: (value) {
                      if (value != null) selectedPriority = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      addTask(controller.text, selectedCategory, selectedPriority);
                      controller.clear();
                      Navigator.pop(context);
                    },
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
