import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../home_shell.dart';

/// Demo login — no real authentication (matches the on-device / offline model).
/// "Log in" simply enters the onboarding flow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'demo@companion.health');
  final _password = TextEditingController(text: '••••••••');
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _enter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: c.heroGradient),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: c.accent.withValues(alpha: 0.45),
                          blurRadius: 26,
                          offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 18),
                Text('COMPANION CONSOLE',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: c.ink)),
                const SizedBox(height: 4),
                Text('Personal Health Companion',
                    style: TextStyle(fontSize: 13.5, color: c.muted)),
                const SizedBox(height: 30),
                _Field(
                  controller: _email,
                  hint: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _password,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  trailing: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                        size: 19, color: c.faint),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(label: 'Log in', icon: Icons.login, onTap: _enter),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _enter,
                  style: TextButton.styleFrom(foregroundColor: c.accent),
                  child: const Text('Create an account'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 13, color: c.faint),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Your health data stays on this device. Nothing is uploaded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: c.faint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: c.ink, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.faint),
        prefixIcon: Icon(icon, color: c.faint, size: 20),
        suffixIcon: trailing,
        filled: true,
        fillColor: c.panel,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.accent, width: 1.6),
        ),
      ),
    );
  }
}
