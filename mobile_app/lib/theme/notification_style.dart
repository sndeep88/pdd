import 'package:flutter/material.dart';

/// Visual identity of a notification type (colour, icon, label).
class NotifStyle {
  final Color color;
  final Color deep;
  final IconData icon;
  final String label;
  final bool sparkle;

  const NotifStyle(this.color, this.deep, this.icon, this.label, {this.sparkle = false});
}

const _info = NotifStyle(Color(0xFF0E7490), Color(0xFF164E63), Icons.notifications_active_rounded, 'Update');
const _promo = NotifStyle(Color(0xFFC9A227), Color(0xFF7A5C0A), Icons.card_giftcard_rounded, 'Offer', sparkle: true);
const _profit = NotifStyle(Color(0xFF10B981), Color(0xFF047857), Icons.trending_up_rounded, 'Profit', sparkle: true);
const _payment = NotifStyle(Color(0xFF006B3C), Color(0xFF003D1F), Icons.paid_rounded, 'Payment', sparkle: true);
const _success = NotifStyle(Color(0xFF16A34A), Color(0xFF166534), Icons.check_circle_rounded, 'Success');
const _alert = NotifStyle(Color(0xFFDC2626), Color(0xFF7F1D1D), Icons.warning_amber_rounded, 'Important');
const _security = NotifStyle(Color(0xFF7C3AED), Color(0xFF4C1D95), Icons.shield_rounded, 'Security');
const _exchange = NotifStyle(Color(0xFF0369A1), Color(0xFF0C4A6E), Icons.swap_horiz_rounded, 'Exchange');
const _withdraw = NotifStyle(Color(0xFFB45309), Color(0xFF78350F), Icons.outbox_rounded, 'Withdrawal');

/// Works for both admin-chosen styles (info/promo/profit/...) and the automatic
/// notification types created by the website (payment_success, weekly_profit, ...).
NotifStyle notifStyleFor(String type) {
  final t = type.toLowerCase();
  bool has(List<String> keys) => keys.any(t.contains);

  if (has(['profit', 'return'])) return _profit;
  if (has(['promo', 'announcement', 'offer'])) return _promo;
  if (has(['security', '2fa', 'password'])) return _security;
  if (has(['alert', 'reject', 'fail', 'suspend', 'debited'])) return _alert;
  if (has(['exchange'])) return _exchange;
  if (has(['withdraw'])) return _withdraw;
  if (has(['payment', 'deposit', 'wallet', 'invest'])) return _payment;
  if (has(['success', 'approved', 'verified'])) return _success;
  return _info;
}
