import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/main.dart';

void main() {
  testWidgets('hiển thị màn hình ghi chú trống', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    expect(find.text('Ghi chú'), findsOneWidget);
    expect(find.text('Không có ghi chú nào'), findsOneWidget);
  });
}