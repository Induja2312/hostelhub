import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../services/ecampus_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'student';

  bool _ecampusLoading = false;

  Future<void> _ecampusLogin() async {
    final rollCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('eCampus Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rollCtrl,
              decoration: const InputDecoration(labelText: 'Roll Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dobCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Login')),
        ],
      ),
    );
    if (result != true) return;
    setState(() => _ecampusLoading = true);
    try {
      await ECampusAuthService().login(rollCtrl.text.trim(), dobCtrl.text.trim());
      if (mounted) {
        await context.read<AuthProvider>().ecampusLogin(rollCtrl.text.trim(), dobCtrl.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _ecampusLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'warden', child: Text('Warden')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: AppStrings.emailHint, border: OutlineInputBorder()),
                    validator: (v) => Validators.email(v, role: _role),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(labelText: AppStrings.passwordHint, border: OutlineInputBorder()),
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: AppStrings.loginButton,
                    isLoading: isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text("Don't have an account? Register"),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _ecampusLoading ? null : _ecampusLogin,
                    icon: _ecampusLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.school_outlined),
                    label: const Text('Login with eCampus'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
