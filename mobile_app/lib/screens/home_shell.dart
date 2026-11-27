import 'package:flutter/material.dart';
import '../services/notification_center.dart';
import '../services/push_service.dart';
import 'dashboard_tab.dart';
import 'wallet_tab.dart';
import 'investments_tab.dart';
import 'withdraw_tab.dart';
import 'exchange_tab.dart';
import 'paddypay_tab.dart';
import '../widgets/paddy_bottom_bar.dart';

class HomeShell extends StatefulWidget {
  final VoidCallback onLoggedOut;
  final Map<String, dynamic>? initialInvestPlan;

  const HomeShell({
    super.key,
    required this.onLoggedOut,
    this.initialInvestPlan,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    NotificationCenter.instance.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PushService.instance.onSignedIn(context);
    });
  }

  @override
  void dispose() {
    NotificationCenter.instance.stop();
    super.dispose();
  }

  void _goToTab(int idx) {
    setState(() => _index = idx);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        onNavigateTab: _goToTab,
        initialInvestPlan: widget.initialInvestPlan,
      ),
      const WalletTab(),
      InvestmentsTab(onWithdrawTap: () => _goToTab(3)),
      const WithdrawTab(),
      ExchangeTab(onLoggedOut: widget.onLoggedOut),
      const PaddyPayTab(), // index 5 (shown in the centre of the bar)
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: PaddyBottomBar(
        currentIndex: _index,
        onSelect: _goToTab,
        centerIndex: 5,
        left: const [
          PaddyBarItem(Icons.dashboard_outlined, Icons.dashboard, 'Home', 0),
          PaddyBarItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Wallet', 1),
          PaddyBarItem(Icons.trending_up_outlined, Icons.trending_up, 'Invest', 2),
        ],
        right: const [
          PaddyBarItem(Icons.outbox_outlined, Icons.outbox, 'Withdraw', 3),
          PaddyBarItem(Icons.swap_horiz_outlined, Icons.swap_horiz, 'More', 4),
        ],
      ),
    );
  }
}
