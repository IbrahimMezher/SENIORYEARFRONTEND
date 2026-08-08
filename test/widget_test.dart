import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertest/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
