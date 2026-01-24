import 'package:flutter/material.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация уведомлений
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotificationService _notificationService = NotificationService();

  int _notificationId = 0;

  void _sendTestNotification() async {
    await _notificationService.showInstantNotification(
      title: 'Simple Day 👋',
      body: 'Это тестовое уведомление',
    );
  }

  void _scheduleNotification() async {
    final DateTime scheduledTime =
        DateTime.now().add(const Duration(minutes: 1));

    await _notificationService.scheduleNotification(
      id: _notificationId++,
      title: '⏰ Напоминание',
      body: 'Пора выполнить задачу',
      dateTime: scheduledTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Уведомление поставлено через 1 минуту'),
      ),
    );
  }

  void _cancelAllNotifications() async {
    await _notificationService.cancelAll();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Все уведомления отменены'),
      ),
    );
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Уведомления работают ✅',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _sendTestNotification,
              child: const Text('Показать уведомление сейчас'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _scheduleNotification,
              child: const Text('Поставить напоминание (1 мин)'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _cancelAllNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Отменить все уведомления'),
            ),
          ],
        ),
      ),
    );
  }
}
