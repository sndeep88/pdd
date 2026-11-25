import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'screens/explore_plans_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  runApp(const PaddyusdtApp());
}

class PaddyusdtApp extends StatefulWidget {
  const PaddyusdtApp({super.key});

  @override
  State<PaddyusdtApp> createState() => _PaddyusdtAppState();
}

class _PaddyusdtAppState extends State<PaddyusdtApp> {
  bool _showSplash = true;
  bool _authenticated = ApiClient.instance.isLoggedIn;
  Map<String, dynamic>? _pendingPlan;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.onUnauthorized = () {
      if (mounted) {
        setState(() {
          _authenticated = false;
          _pendingPlan = null;
        });
      }
    };
  }

  void _onAuthenticated({Map<String, dynamic>? pendingPlan}) {
    setState(() {
      _pendingPlan = pendingPlan;
      _authenticated = true;
    });
  }

  void _onLoggedOut() {
    setState(() {
      _authenticated = false;
      _pendingPlan = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paddyusdt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _showSplash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onFinished: () => setState(() => _showSplash = false),
              )
            : _authenticated
                ? HomeShell(
                    key: const ValueKey('home'),
                    onLoggedOut: _onLoggedOut,
                    initialInvestPlan: _pendingPlan,
                  )
                : ExplorePlansScreen(
                    key: const ValueKey('explore'),
                    onAuthenticated: _onAuthenticated,
                  ),
      ),
    );
  }
}
