import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dagaabook/core/app_owner.dart';
import 'package:dagaabook/main.dart';
import 'package:dagaabook/providers/auth_provider.dart';
import 'package:dagaabook/services/local_store.dart';

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

  test('Helper logout removes the owner data from the phone', () async {
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    await LocalStore.saveList(LocalStore.customersKey, [
      {'id': 'c1'}
    ]);

    await auth.startHelperSession(id: 'helper_1', name: 'Neema');
    expect(auth.isHelper, isTrue);
    expect(auth.isLoggedIn, isTrue);

    await auth.logout();
    expect(auth.isHelper, isFalse);
    expect(await LocalStore.loadString(LocalStore.customersKey), isNull);
  });

  testWidgets('Login screen links to helper login', (WidgetTester tester) async {
    await tester.pumpWidget(const DagaaBookApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wewe ni msaidizi? Ingia hapa'));
    await tester.pumpAndSettle();
    expect(find.text('Ingia kama Msaidizi'), findsOneWidget);
  });

  test('Login saved by an older version keeps working', () async {
    SharedPreferences.setMockInitialValues({'flutter.login_phone': '0712345678', 'flutter.login_password': 'zamani1'});
    final auth = AuthProvider();
    await auth.loadData();

    expect(await auth.login(phone: '0712345678', password: 'zamani1'), isTrue);
    expect(await LocalStore.loadString(LocalStore.loginPasswordKey), isNull);
    final account = (await LocalStore.loadList(LocalStore.accountKey, (j) => j)).single;
    expect(account.containsKey('password_hash'), isTrue);
    expect(account.values, isNot(contains('zamani1')));
  });

  test('Password set in the database replaces the old one', () async {
    await LocalStore.saveList(LocalStore.accountKey, [
      {'id': 'owner', 'phone': '0799999999', 'new_password': 'kutokaDB1', 'updated_at': '2026-11-06T10:00:00.000Z'}
    ]);
    final auth = AuthProvider();
    await auth.loadData();

    expect(await auth.login(phone: AppOwner.defaultPhone, password: AppOwner.defaultPassword), isFalse);
    expect(await auth.login(phone: '0799 999 999', password: 'kutokaDB1'), isTrue);
    final account = (await LocalStore.loadList(LocalStore.accountKey, (j) => j)).single;
    expect(account.containsKey('new_password'), isFalse);
  });
}
