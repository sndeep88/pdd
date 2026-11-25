import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class ExchangeTab extends StatefulWidget {
  final VoidCallback onLoggedOut;
  const ExchangeTab({super.key, required this.onLoggedOut});

  @override
  State<ExchangeTab> createState() => _ExchangeTabState();
}

class _ExchangeTabState extends State<ExchangeTab> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String _type = 'cash_to_crypto';
  String _region = 'Ireland';
  String _network = 'USDT_TRX';
  List<String> _regions = ['Ireland', 'UK', 'Spain'];
  List<Map<String, dynamic>> _networks = [];
  List<Map<String, dynamic>> _requests = [];
  String _feeCash = '5%–11%';
  String _feeCrypto = '3%–7%';
  String _helpTitle = '24/7 Help';
  String _helpHandle = '@Paddyitsupport';
  String _helpUrl = 'https://t.me/Paddyitsupport';

  final _amountCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _cityCtrl.dispose();
    _walletCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _networks.isEmpty;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('exchange');
      if (!mounted) return;
      final regions = (res['regions'] as List<dynamic>? ?? ['Ireland', 'UK', 'Spain'])
          .map((e) => e.toString())
          .toList();
      final nets = (res['networks'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final reqs = (res['requests'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _regions = regions;
        if (!regions.contains(_region) && regions.isNotEmpty) {
          _region = regions.first;
        }
        _networks = nets;
        if (nets.isNotEmpty && !nets.any((n) => n['code'].toString() == _network)) {
          _network = nets.first['code'].toString();
        }
        _requests = reqs;
        _feeCash = (res['fee_cash_to_crypto'] ?? '5%–11%').toString();
        _feeCrypto = (res['fee_crypto_to_cash'] ?? '3%–7%').toString();
        _helpTitle = (res['support_button_text'] ?? '24/7 Help').toString();
        _helpHandle = (res['support_telegram_handle'] ?? '@Paddyitsupport').toString();
        _helpUrl = (res['support_telegram_url'] ?? 'https://t.me/Paddyitsupport').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.post('exchange', {
        'exchange_type': _type,
        'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'city': _cityCtrl.text.trim(),
        'region': _region,
        'wallet_network': _network,
        'wallet_address': _walletCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      _amountCtrl.clear();
      _walletCtrl.clear();
      _notesCtrl.clear();
      setState(() => _submitting = false);
      await _load();

      final tgUrl = (res['telegram_url'] ?? '').toString();
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Exchange Request Submitted'),
          content: Text((res['message'] ?? 'Request saved.').toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (tgUrl.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Open Telegram'),
                onPressed: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse(tgUrl), mode: LaunchMode.externalApplication);
                },
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  Future<void> _logout() async {
    await ApiClient.instance.logout();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClient.instance.cachedUser ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange & Account'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.irishGreen,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Account card
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.irishGreen,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        (user['full_name'] ?? 'Paddyusdt User').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text((user['email'] ?? '').toString()),
                      trailing: OutlinedButton(
                        onPressed: _logout,
                        child: const Text('Sign Out'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Help (24/7 Telegram Support)
                  Card(
                    color: AppColors.irishGreen,
                    child: ListTile(
                      onTap: () => launchUrl(
                        Uri.parse(_helpUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: const Text(
                        'Help',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '$_helpTitle on Telegram ($_helpHandle)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Exchange Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Cash ↔ Crypto Exchange',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cash → Crypto: $_feeCash  ·  Crypto → Cash: $_feeCrypto',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'cash_to_crypto',
                                label: Text('Cash → Crypto'),
                              ),
                              ButtonSegment(
                                value: 'crypto_to_cash',
                                label: Text('Crypto → Cash'),
                              ),
                            ],
                            selected: {_type},
                            onSelectionChanged: (s) =>
                                setState(() => _type = s.first),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount (USDT · max 10,000)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _region,
                                  decoration: const InputDecoration(
                                    labelText: 'Region',
                                  ),
                                  items: _regions
                                      .map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(r),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _region = v ?? _region),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_networks.isNotEmpty)
                            DropdownButtonFormField<String>(
                              initialValue: _network,
                              decoration: const InputDecoration(
                                labelText: 'Wallet Network',
                              ),
                              items: _networks
                                  .map((n) => DropdownMenuItem(
                                        value: n['code'].toString(),
                                        child: Text(n['label'].toString()),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _network = v ?? _network),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _walletCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Wallet Address',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Submit Exchange Request'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'My Exchange Requests',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (_requests.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No exchange requests yet.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._requests.map((r) {
                      final label = r['exchange_type'] == 'cash_to_crypto'
                          ? 'Cash → Crypto'
                          : 'Crypto → Cash';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$label · ${formatUsdt((r['amount'] as num?) ?? 0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              statusPill((r['status'] ?? 'pending').toString()),
                            ],
                          ),
                          subtitle: Text(
                            '${r['city']} (${r['region']}) · ${r['created_at']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
