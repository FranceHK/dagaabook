import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/helper_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/language_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/helper/helper_shell.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(const DagaaBookApp());
}

class DagaaBookApp extends StatelessWidget {
  const DagaaBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => HelperProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) => SyncProvider()
            ..reloaders = [
              ctx.read<CustomerProvider>().loadData,
              ctx.read<InventoryProvider>().loadData,
              ctx.read<SalesProvider>().loadData,
              ctx.read<SettingsProvider>().loadData,
              ctx.read<HelperProvider>().loadData,
            ],
        ),
      ],
      child: MaterialApp(
        title: 'DagaaBook',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isLoggedIn) {
      return auth.isHelper ? const HelperShell() : const MainShell();
    }

    return const LoginScreen();
  }
}
