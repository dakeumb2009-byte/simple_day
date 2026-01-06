import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SimpleDayApp());
}

class SimpleDayApp extends StatelessWidget {
  const SimpleDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Day',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// ---------------- HOME PAGE ----------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<Task> _tasks = [];

  /// текущая дата
  String get today {
    return DateFormat('EEEE, d MMMM', 'en_US').format(DateTime.now());
  }

  /// добавление задачи
  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _tasks.add(Task(title: text));
    });

    _controller.clear();
    _focusNode.requestFocus();
  }

  /// количество выполненных
  int get completedCount {
    return _tasks.where((t) => t.done).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Day'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// -------- DATE --------
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                today,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// -------- INPUT --------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _addTask(), // ENTER
                    decoration: const InputDecoration(
                      hintText: 'Add new task...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 32),
                  onPressed: _addTask,
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// -------- COUNTER --------
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Completed: $completedCount / ${_tasks.length}',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),

            const SizedBox(height: 8),

            /// -------- TASK LIST --------
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: task.done,
                              onChanged: (value) {
                                setState(() {
                                  task.done = value ?? false;
                                });
                              },
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _tasks.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- TASK MODEL ----------------

class Task {
  final String title;
  bool done;

  Task({
    required this.title,
    this.done = false,
  });
}
