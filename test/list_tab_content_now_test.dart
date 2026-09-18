import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/constants/panchang_terms.dart';
import 'package:tithinow/widgets/list_item_tab_content.dart';
import 'package:tithinow/widgets/list_tab_content_now.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListTabContentNow Tests', () {
    testWidgets('Populates 3 CurrentItems: 1 Choghadiya and 2 Muhurtas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1 Choghadiya item
      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);

      // 2 Muhurta items
      expect(find.text('Abhijit Muhurta'), findsOneWidget);
      expect(find.text('Rahu Kalam'), findsOneWidget);
      expect(find.text('Muhurta'), findsNWidgets(2));

      // 3 items in total
      expect(find.byType(ListItemTabContent), findsNWidgets(3));
    });

    testWidgets('Supports Hindi localization', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              language: AppLanguage.hindi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('अमृत'), findsOneWidget);
      expect(find.text('चौघड़िया'), findsOneWidget);
      expect(find.text('अभिजीत मुहूर्त'), findsOneWidget);
      expect(find.text('राहु काल'), findsOneWidget);
      expect(find.text('मुहूर्त'), findsNWidgets(2));
    });

    testWidgets('Supports Gujarati localization', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              language: AppLanguage.gujarati,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('અમૃત'), findsOneWidget);
      expect(find.text('ચોઘડિયા'), findsOneWidget);
      expect(find.text('અભિજિત મુહૂર્ત'), findsOneWidget);
      expect(find.text('રાહુ કાળ'), findsOneWidget);
      expect(find.text('મુહૂર્ત'), findsNWidgets(2));
    });
  });
}
