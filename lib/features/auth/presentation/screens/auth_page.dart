import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({required this.isSignup, super.key});
  final bool isSignup;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Text controllers store form input; the AuthCubit owns application session
  // state and is reused by routing and all account-related screens.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  String? _challengeToken;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, LoadState<AuthUser?>>(
      builder: (context, auth) {
        final busy = auth.isLoading;
        return Scaffold(
          body: ResponsiveLayout(
            mobileBuilder: (_) => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(child: _authForm(context, auth, busy)),
                ),
              ),
            ),
            wideBuilder: (_) => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.checklist,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Clean BLoC',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Manage users, roles, and permissions '
                                  'from one secure workspace.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(child: _authForm(context, auth, busy)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _authForm(
    BuildContext context,
    LoadState<AuthUser?> auth,
    bool busy,
  ) => Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            widget.isSignup ? Icons.person_add_alt_1 : Icons.lock,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _challengeToken != null
                ? 'Two-factor authentication'
                : widget.isSignup
                ? 'Create account'
                : 'Sign in',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          if (auth.hasError) ...[
            Text(
              errorMessage(auth.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (_challengeToken != null) ...[
            const Text(
              'Enter the six-digit code from your authenticator app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otp,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                labelText: 'Authentication code',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 6
                  ? 'Enter a valid authentication code'
                  : null,
            ),
            const SizedBox(height: 20),
          ] else ...[
            if (widget.isSignup) ...[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
          ],
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _challengeToken != null
                        ? 'Verify code'
                        : widget.isSignup
                        ? 'Sign up'
                        : 'Sign in',
                  ),
          ),
          if (_challengeToken != null)
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      _challengeToken = null;
                      _otp.clear();
                    }),
              child: const Text('Use different credentials'),
            ),
          if (_challengeToken == null)
            TextButton(
              onPressed: busy
                  ? null
                  : () => context.go(widget.isSignup ? '/login' : '/signup'),
              child: Text(
                widget.isSignup
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
        ],
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    try {
      if (_challengeToken != null) {
        await cubit.completeTwoFactorLogin(_challengeToken!, _otp.text.trim());
      } else if (widget.isSignup) {
        await cubit.signup(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        final result = await cubit.login(_email.text.trim(), _password.text);
        if (result.requiresTwoFactor) {
          if (!mounted) return;
          setState(() {
            _challengeToken = result.challengeToken;
            _otp.clear();
          });
          return;
        }
      }
      if (mounted) context.go('/dashboard');
    } catch (_) {}
  }
}
