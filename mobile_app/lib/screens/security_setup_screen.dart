import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';

enum _Step { password, authenticator, recovery, code }

/// Mandatory security setup, same steps and rules as the website:
/// 1. set a new password (only if the account requires it)
/// 2. enable two-factor authentication with an authenticator app
/// 3. save one-time recovery codes
///
/// [onDone] is called once the user is signed in; the caller closes the screen.
class SecuritySetupScreen extends StatefulWidget {
  final String setupToken;
  final String email;
  final bool mustChangePassword;
  final VoidCallback onDone;

  const SecuritySetupScreen({
    super.key,
    required this.setupToken,
    required this.email,
    required this.mustChangePassword,
    required this.onDone,
  });

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  late _Step _step;
  bool _loading = false;
  bool _expired = false;
  String? _error;

  // password step
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  // authenticator step
  final _otpCtrl = TextEditingController();
  String _enrollToken = '';
  String _manualKey = '';
  String _otpauthUri = '';

  // recovery step
  String _completeToken = '';
  List<String> _codes = const [];
  bool _savedConfirmed = false;

  // existing-2FA step (account already had an authenticator)
  String _challengeToken = '';

  @override
  void initState() {
    super.initState();
    if (widget.mustChangePassword) {
      _step = _Step.password;
    } else {
      _step = _Step.authenticator;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAuthenticator());
    }
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _error = e.toString();
      _loading = false;
      if (e is ApiException && e.statusCode == 401) _expired = true;
    });
  }

  Future<void> _submitPassword() async {
    final current = _currentCtrl.text;
    final pw = _newCtrl.text;
    final pw2 = _confirmCtrl.text;
    if (current.isEmpty || pw.isEmpty || pw2.isEmpty) {
      setState(() => _error = 'Please fill in all password fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.setupPassword(
        setupToken: widget.setupToken,
        currentPassword: current,
        password: pw,
        passwordConfirm: pw2,
      );
      if (!mounted) return;
      if (res['needs_2fa'] == true) {
        setState(() {
          _challengeToken = (res['challenge_token'] ?? '').toString();
          _step = _Step.code;
          _loading = false;
        });
        return;
      }
      setState(() {
        _step = _Step.authenticator;
        _loading = false;
      });
      await _startAuthenticator();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _startAuthenticator() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.setup2faStart(widget.setupToken);
      if (!mounted) return;
      setState(() {
        _enrollToken = (res['enroll_token'] ?? '').toString();
        _manualKey = (res['manual_key'] ?? '').toString();
        _otpauthUri = (res['otpauth_uri'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _openAuthenticatorApp() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(_otpauthUri),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No authenticator app found. Install Google Authenticator, then use the setup key below.',
          ),
        ),
      );
    }
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyAuthenticator() async {
    final code = _otpCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your authenticator app.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.setup2faVerify(_enrollToken, code);
      if (!mounted) return;
      setState(() {
        _codes = ((res['recovery_codes'] as List?) ?? const [])
            .map((c) => c.toString())
            .toList();
        _completeToken = (res['complete_token'] ?? '').toString();
        _step = _Step.recovery;
        _loading = false;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _complete() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.setup2faComplete(_completeToken);
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _verifyExistingCode() async {
    final code = _otpCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter your authenticator code or a recovery code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.verify2fa(_challengeToken, code);
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      _fail(e);
    }
  }

  // ---------------------------------------------------------------- UI

  int get _stepNumber {
    switch (_step) {
      case _Step.password:
        return 1;
      case _Step.authenticator:
      case _Step.code:
        return 2;
      case _Step.recovery:
        return 3;
    }
  }

  Widget _stepper() {
    Widget chip(int n, String label) {
      final active = _stepNumber == n;
      final done = _stepNumber > n;
      return Expanded(
        child: Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: done || active ? AppColors.irishGreen : AppColors.mist,
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.muted,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (widget.mustChangePassword) chip(1, 'Password'),
        chip(2, 'Authenticator'),
        chip(3, 'Recovery'),
      ],
    );
  }

  Widget _errorBox() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
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
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }

  Widget _heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _passwordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Set a new password',
          'As part of our routine security update, enter your current password and choose a new one.',
        ),
        _errorBox(),
        TextField(
          controller: _currentCtrl,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            labelText: 'Current password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _newCtrl,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_reset),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: Icon(Icons.lock_reset),
          ),
          onSubmitted: (_) => _submitPassword(),
        ),
        const SizedBox(height: 8),
        const Text(
          'At least 8 characters with one uppercase letter, one number and one special character (e.g. !@#\$%&).',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        _primaryButton('Save password', _submitPassword),
      ],
    );
  }

  Widget _authenticatorStep() {
    final ready = _enrollToken.isNotEmpty;
    final keyGroups = _manualKey.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Set up two-factor authentication',
          'Add a 6-digit app code to every sign-in. A password alone will no longer be enough.',
        ),
        _errorBox(),
        if (!ready && _error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!ready && _error != null && !_expired)
          OutlinedButton.icon(
            onPressed: _loading ? null : _startAuthenticator,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        if (ready) ...[
          const Text(
            '1. Install an authenticator app',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Google Authenticator, Microsoft Authenticator or Authy all work.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          const Text(
            '2. Add your Paddyusdt account',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _openAuthenticatorApp,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in authenticator app'),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.mist, width: 2),
              ),
              child: QrImageView(
                data: _otpauthUri,
                size: 176,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Using another device? Scan this code with the authenticator app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Or type this setup key manually:',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      for (final g in keyGroups)
                        Text(
                          g,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy setup key',
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copy(
                    _manualKey.replaceAll(RegExp(r'\s+'), ''),
                    'Setup key copied',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '3. Enter the 6-digit code',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              counterText: '',
            ),
            onSubmitted: (_) => _verifyAuthenticator(),
          ),
          const SizedBox(height: 14),
          _primaryButton('Verify & Enable 2FA', _verifyAuthenticator),
        ],
      ],
    );
  }

  Widget _recoveryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Save your recovery codes',
          'Two-factor authentication is on. These codes let you in if you lose your phone or cannot get an app code.',
        ),
        _errorBox(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Important: save these codes somewhere safe now. Each code works once, and they will not be shown again.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _codes)
                Container(
                  width: 128,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    c,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _copy(_codes.join('\n'), 'Recovery codes copied'),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy all codes'),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _savedConfirmed,
          onChanged: (v) => setState(() => _savedConfirmed = v ?? false),
          title: const Text(
            'I have securely saved my recovery codes and understand they will not be shown again.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        _primaryButton(
          "I've saved my codes - Continue",
          _savedConfirmed ? _complete : null,
        ),
      ],
    );
  }

  Widget _codeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Two-factor authentication',
          'Your password is updated. Enter the 6-digit code from your authenticator app or a recovery code.',
        ),
        _errorBox(),
        TextField(
          controller: _otpCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '2FA code', hintText: '123456'),
          onSubmitted: (_) => _verifyExistingCode(),
        ),
        const SizedBox(height: 18),
        _primaryButton('Verify', _verifyExistingCode),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_step) {
      case _Step.password:
        body = _passwordStep();
      case _Step.authenticator:
        body = _authenticatorStep();
      case _Step.recovery:
        body = _recoveryStep();
      case _Step.code:
        body = _codeStep();
    }

    return PopScope(
      // The recovery codes are shown once: do not let a stray back gesture lose them.
      canPop: _step != _Step.recovery,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Security setup'),
          automaticallyImplyLeading: _step != _Step.recovery,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step != _Step.code) ...[
                      _stepper(),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: body,
                      ),
                    ),
                    if (_expired) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to sign in'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
