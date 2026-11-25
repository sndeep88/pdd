import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_tab.dart';
import 'wallet_tab.dart';
import 'investments_tab.dart';
import 'withdraw_tab.dart';
import 'exchange_tab.dart';

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
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mist,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.irishGreen),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.irishGreen),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up, color: AppColors.irishGreen),
            label: 'Invest',
          ),
          NavigationDestination(
            icon: Icon(Icons.outbox_outlined),
            selectedIcon: Icon(Icons.outbox, color: AppColors.irishGreen),
            label: 'Withdraw',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz, color: AppColors.irishGreen),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
