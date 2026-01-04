import 'package:flutter_test/flutter_test.dart';
import 'package:simple_day/main.dart';

void main() {
  testWidgets('Проверка текста на TodayScreen', (WidgetTester tester) async {
    // Рендерим наше приложение
    await tester.pumpWidget(const SimpleDayApp());

    // Проверяем наличие AppBar с текстом 'Simple Day'
    expect(find.text('Simple Day'), findsOneWidget);

    // Проверяем наличие текста в теле экрана
    expect(find.text('Сегодня\n\nМой первый день с Simple Day'), findsOneWidget);
  });
}
