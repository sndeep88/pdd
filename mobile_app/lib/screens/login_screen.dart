import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'security_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.login(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      if (res['needs_setup'] == true) {
        // Same gate as the website: new password and/or 2FA setup before first use.
        setState(() => _loading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SecuritySetupScreen(
              setupToken: (res['setup_token'] ?? '').toString(),
              email: (res['email'] ?? _emailCtrl.text).toString(),
              mustChangePassword: res['must_change_password'] == true,
              onDone: widget.onLoginSuccess,
            ),
          ),
        );
        return;
      }
      if (res['needs_2fa'] == true) {
        final challenge = (res['challenge_token'] ?? '').toString();
        setState(() => _loading = false);
        await _show2faDialog(challenge);
        return;
      }
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _show2faDialog(String challengeToken) async {
    final codeCtrl = TextEditingController();
    String? dialogErr;
    bool verifying = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.irishGreen),
              SizedBox(width: 8),
              Text('Two-Factor Auth'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the 6-digit code from your authenticator app or a recovery code.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: '2FA Code',
                  hintText: '123456',
                ),
              ),
              if (dialogErr != null) ...[
                const SizedBox(height: 10),
                Text(
                  dialogErr!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: verifying ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: verifying
                  ? null
                  : () async {
                      setModalState(() {
                        verifying = true;
                        dialogErr = null;
                      });
                      try {
                        await ApiClient.instance.verify2fa(
                          challengeToken,
                          codeCtrl.text,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        widget.onLoginSuccess();
                      } catch (e) {
                        setModalState(() {
                          dialogErr = e.toString();
                          verifying = false;
                        });
                      }
                    },
              child: verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.irishGreenDeep,
              AppColors.irishGreen,
              AppColors.bg,
              AppColors.bg,
            ],
            stops: [0.0, 0.42, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (Navigator.of(context).canPop())
                Positioned(
                  top: 6,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              Center(
                child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.goldLight.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text('☘️', style: TextStyle(fontSize: 34)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Paddyusdt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Crypto Exchange & Investment',
                      style: TextStyle(
                        color: AppColors.goldLight.withValues(alpha: 0.95),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Card(
                      elevation: 6,
                      shadowColor: AppColors.irishGreenDeep.withValues(alpha: 0.16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Sign in with your Paddyusdt account',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 20),
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
                                const SizedBox(height: 14),
                              ],
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty || !v.contains('@')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Sign In'),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'New to Paddyusdt? ',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => RegisterScreen(
                                            onRegisterSuccess: () {
                                              Navigator.of(context).pop();
                                              widget.onLoginSuccess();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: AppColors.irishGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Connected to live paddyusdt.com',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
