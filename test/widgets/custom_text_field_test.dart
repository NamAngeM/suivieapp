
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoe_church_visitors/widgets/form/custom_text_field.dart';

void main() {
  group('CustomTextField Widget Tests', () {
    testWidgets('Renders label and hint correctly', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            label: 'MY LABEL',
            hint: 'Enter text',
          ),
        ),
      ));

      expect(find.text('MY LABEL'), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);
    });

    testWidgets('Entering text updates controller', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            label: 'Name',
            hint: '...',
          ),
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'Hello World');
      
      expect(controller.text, 'Hello World');
    });

    testWidgets('Icon renders when provided', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            label: 'With Icon',
            hint: '...',
            icon: Icons.person,
          ),
        ),
      ));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
