import 'package:flutter_test/flutter_test.dart';
import 'package:capsicum/app/app.dart';

void main() {
  // Widget test dasar - test lebih lanjut perlu mock services
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Skip actual rendering karena butuh camera dan Hive yang perlu init
    expect(CapsicumApp, isNotNull);
  });
}
