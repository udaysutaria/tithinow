import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/main.dart';
import 'package:tithinow/views/view_today.dart';

void main() {
  testWidgets('MyApp smoke test renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(
      showSplash: false,
      home: TodayView(),
    ));
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(TodayView), findsOneWidget);
  });
}
