import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleDayApp());
}

class SimpleDayApp extends StatelessWidget {
  const SimpleDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Day',
      home: const HomePage(),
    );
  }
}

class Task {
  String title;
  bool isDone;

  Task({required this.title, this.isDone = false});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Task> tasks = [];
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 🔥 B2 — СЧЁТЧИК ВЫПОЛНЕННЫХ ЗАДАЧ
    final int completedCount =
        tasks.where((task) => task.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Day'),
      ),
      body: Column(
        children: [
          // 🔥 ВОТ ГДЕ ТЫ ВИДИШЬ СЧЁТЧИК (СВЕРХУ ЭКРАНА)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              completedCount == 0
                  ? 'Сегодня выполнено: 0 задач — начни с одной 💪'
                  : 'Сегодня выполнено: $completedCount задач',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Checkbox(
                    value: tasks[index].isDone,
                    onChanged: (value) {
                      setState(() {
                        tasks[index].isDone = value!;
                      });
                    },
                  ),
                  title: Text(
                    tasks[index].title,
                    style: TextStyle(
                      decoration: tasks[index].isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Новая задача',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    setState(() {
                      tasks.add(Task(title: controller.text.trim()));
                      controller.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
