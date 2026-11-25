import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class WithdrawTab extends StatefulWidget {
  const WithdrawTab({super.key});

  @override
  State<WithdrawTab> createState() => _WithdrawTabState();
}

class _WithdrawTabState extends State<WithdrawTab> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _methods = [];
  List<Map<String, dynamic>> _history = [];

  String? _selectedSourceKey;
  String? _selectedMethod;
  final _amountCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _walletCtrl.dispose();
    _holderCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _currentSource {
    for (final s in _sources) {
      if (s['key'].toString() == _selectedSourceKey) return s;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = _methods.isEmpty;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('withdraw');
      if (!mounted) return;
      final sources = (res['sources'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final methods = (res['payout_methods'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final hist = (res['withdrawals'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _sources = sources;
        _methods = methods;
        _history = hist;
        if (sources.isNotEmpty &&
            !sources.any((s) => s['key'].toString() == _selectedSourceKey)) {
          _selectedSourceKey = sources.first['key'].toString();
          _syncAmountForSource();
        }
        if (methods.isNotEmpty && _selectedMethod == null) {
          _selectedMethod = methods.first['code'].toString();
        }
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

  void _syncAmountForSource() {
    final src = _currentSource;
    if (src != null) {
      _amountCtrl.text = (src['max'] as num? ?? 0).toDouble().toStringAsFixed(2);
    }
  }

  Future<void> _submit() async {
    if (_selectedSourceKey == null || _selectedMethod == null) {
      setState(() => _error = 'Please select a withdrawal source and payout method.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.post('withdraw', {
        'source_key': _selectedSourceKey,
        'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'wallet_network': _selectedMethod,
        'wallet_address': _walletCtrl.text.trim(),
        'bank_name': _holderCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
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
          title: const Text('Withdrawal Submitted'),
          content: Text((res['message'] ?? 'Request saved successfully.').toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
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

  @override
  Widget build(BuildContext context) {
    final src = _currentSource;
    final isFullOnly = src?['full_only'] == true;
    final method = _selectedMethod ?? 'USDT_TRX';

    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawals')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.irishGreen,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Request Withdrawal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Withdraw earned profit, uninvested deposit balance, or close an active investment principal.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
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
                          if (_sources.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.mist,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'No withdrawable balance available right now.',
                                style: TextStyle(
                                  color: AppColors.irishGreenDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else ...[
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSourceKey,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Source'),
                              items: _sources.map((s) {
                                final max = (s['max'] as num? ?? 0).toDouble();
                                return DropdownMenuItem(
                                  value: s['key'].toString(),
                                  child: Text(
                                    '${s['label']} (${formatUsdt(max)})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedSourceKey = v;
                                  _syncAmountForSource();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _amountCtrl,
                              readOnly: isFullOnly,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: isFullOnly
                                    ? 'Full Principal Amount (USDT)'
                                    : 'Amount (USDT)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payout Method',
                              ),
                              items: _methods.map((m) {
                                return DropdownMenuItem(
                                  value: m['code'].toString(),
                                  child: Text(
                                    '${m['label']} (min ${m['min_amount']} USDT)',
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedMethod = v),
                            ),
                            const SizedBox(height: 12),
                            if (method == 'BANK' || method == 'CASH') ...[
                              TextField(
                                controller: _holderCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Account Holder / Customer Name',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (method != 'CASH') ...[
                              TextField(
                                controller: _walletCtrl,
                                decoration: InputDecoration(
                                  labelText: method == 'BANK'
                                      ? 'IBAN'
                                      : 'Destination Wallet Address',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
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
                                    : const Text('Submit Withdrawal'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Withdrawal History',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(
                          child: Text(
                            'No withdrawals yet.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._history.map((w) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatUsdt((w['amount'] as num?) ?? 0),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              statusPill((w['status'] ?? 'pending').toString()),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '#${w['id']} · ${w['wallet_network']} · ${w['created_at']}',
                              style: const TextStyle(fontSize: 12),
                            ),
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
