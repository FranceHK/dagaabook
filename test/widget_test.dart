import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dagaabook/core/app_owner.dart';
import 'package:dagaabook/main.dart';
import 'package:dagaabook/providers/auth_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Login screen has no register or offline buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const DagaaBookApp());
    await tester.pumpAndSettle();

    expect(find.text('Ingia'), findsOneWidget);
    expect(find.textContaining('Jisajili'), findsNothing);
    expect(find.textContaining('Offline'), findsNothing);
  });

  test('Only the owner credentials log in', () async {
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);

    expect(await auth.login(phone: '0711111111', password: 'wrong'), isFalse);
    expect(auth.isLoggedIn, isFalse);

    expect(await auth.login(phone: AppOwner.defaultPhone, password: AppOwner.defaultPassword), isTrue);
    expect(auth.isLoggedIn, isTrue);
  });

  test('Changed password replaces the old one', () async {
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);

    expect(await auth.changeLogin(currentPassword: 'bad', newPhone: '0712345678', newPassword: 'mpya1'), isFalse);
    expect(await auth.changeLogin(currentPassword: AppOwner.defaultPassword, newPhone: '0712345678', newPassword: 'mpya1'), isTrue);
    await auth.logout();

    expect(await auth.login(phone: AppOwner.defaultPhone, password: AppOwner.defaultPassword), isFalse);
    expect(await auth.login(phone: '0712 345 678', password: 'mpya1'), isTrue);
  });
}
