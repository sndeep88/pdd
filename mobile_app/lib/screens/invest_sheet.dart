import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';

class InvestSheet extends StatefulWidget {
  final Map<String, dynamic> plan;
  const InvestSheet({super.key, required this.plan});

  @override
  State<InvestSheet> createState() => _InvestSheetState();
}

class _InvestSheetState extends State<InvestSheet> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _success;

  double _walletAvail = 0;
  bool _canFromWallet = false;
  List<Map<String, dynamic>> _coins = [];
  String _selectedCoin = 'USDT_TRX';
  bool _useWallet = false;

  Map<String, dynamic>? _activeDeposit;
  final _txCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void dispose() {
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.post('invest', {
        'action': 'plan_info',
        'plan_id': widget.plan['id'],
      });
      if (!mounted) return;
      final coins = (res['coins'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _walletAvail = (res['wallet_available'] as num? ?? 0).toDouble();
        _canFromWallet = res['can_invest_from_wallet'] == true;
        _coins = coins;
        if (coins.isNotEmpty) {
          _selectedCoin = coins.first['code'].toString();
        }
        if (res['open_deposit'] is Map) {
          _activeDeposit = Map<String, dynamic>.from(
            res['open_deposit'] as Map,
          );
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

  Future<void> _investFromWallet() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.post('invest', {
        'action': 'from_wallet',
        'plan_id': widget.plan['id'],
      });
      if (!mounted) return;
      if (res['ok'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investment created from wallet balance!'),
            backgroundColor: AppColors.irishGreen,
          ),
        );
      } else {
        setState(() {
          _error = (res['error'] ?? 'Unable to invest.').toString();
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _createDeposit({
    bool confirmCancel = false,
    int? pendingId,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.post('invest', {
        'action': 'create_deposit',
        'plan_id': widget.plan['id'],
        'currency': _selectedCoin,
        'use_wallet': _useWallet,
        if (confirmCancel) 'confirm_cancel': true,
        if (pendingId != null) 'pending_payment_id': pendingId,
      });
      if (!mounted) return;
      if (res['needs_cancel'] == true) {
        final pid = (res['pending_payment_id'] as num?)?.toInt();
        setState(() => _busy = false);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Replace pending deposit?'),
            content: Text(
              (res['message'] ??
                      'You have an open deposit on another network. Replace it?')
                  .toString(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep existing'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Replace'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await _createDeposit(confirmCancel: true, pendingId: pid);
        }
        return;
      }
      if (res['ok'] == true) {
        setState(() {
          _activeDeposit = {
            'id': res['payment_id'] ?? res['id'],
            'currency': res['currency'] ?? _selectedCoin,
            'expected_amount':
                res['amount_due'] ??
                res['expected_amount'] ??
                widget.plan['amount'],
            'deposit_address': res['address'] ?? res['deposit_address'] ?? '',
            'status': 'pending',
          };
          _busy = false;
        });
      } else {
        setState(() {
          _error = (res['error'] ?? 'Could not create deposit.').toString();
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _submitTx() async {
    final tx = _txCtrl.text.trim();
    if (tx.length < 16) {
      setState(
        () => _error = 'Please paste a valid blockchain transaction hash.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final res = await ApiClient.instance.post('invest', {
        'action': 'submit_tx',
        'payment_id': _activeDeposit!['id'],
        'tx_hash': tx,
      });
      if (!mounted) return;
      if (res['ok'] == true) {
        setState(() {
          _success = (res['message'] ?? 'Deposit verified and credited!')
              .toString();
          _busy = false;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      } else {
        setState(() {
          _error = (res['error'] ?? 'Transaction could not be verified yet.')
              .toString();
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amt = (widget.plan['amount'] as num? ?? 0).toDouble();
    final pct = (widget.plan['weekly_return_percent'] as num? ?? 0).toDouble();

    return SheetFrame(
      radius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            (widget.plan['name'] ?? 'Investment Plan').toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatUsdt(amt)}  ·  $pct% Weekly Return',
            style: const TextStyle(
              color: AppColors.irishGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Wallet available',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatUsdt(_walletAvail),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.irishGreenDeep,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _success!,
                  style: const TextStyle(
                    color: AppColors.irishGreenDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_canFromWallet) ...[
              ElevatedButton.icon(
                onPressed: _busy ? null : _investFromWallet,
                icon: const Icon(Icons.bolt),
                label: const Text('Invest Directly From Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_activeDeposit != null) ...[
              const Text(
                'Send exact amount & paste Tx Hash',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.irishGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Due: ${_activeDeposit!['expected_amount']} ${_activeDeposit!['currency']}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Deposit Wallet Address:',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            (_activeDeposit!['deposit_address'] ?? '')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: (_activeDeposit!['deposit_address'] ?? '')
                                    .toString(),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _txCtrl,
                decoration: const InputDecoration(
                  labelText: 'Blockchain Transaction Hash (TxID)',
                  hintText: 'Paste Tx Hash after sending',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _submitTx,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify Tx Hash'),
              ),
            ] else ...[
              const Text(
                'Choose Deposit Network',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _coins.map((c) {
                  final code = c['code'].toString();
                  final sel = code == _selectedCoin;
                  return ChoiceChip(
                    label: Text(c['label'].toString()),
                    selected: sel,
                    selectedColor: AppColors.irishGreen,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedCoin = code),
                  );
                }).toList(),
              ),
              if (_walletAvail > 0) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useWallet,
                  onChanged: (v) => setState(() => _useWallet = v == true),
                  title: const Text(
                    'Apply available wallet balance',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  activeColor: AppColors.irishGreen,
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : () => _createDeposit(),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue to Deposit'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
