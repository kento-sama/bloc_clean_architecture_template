import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  final _setupCode = TextEditingController();
  // Enrollment data is temporary state only. It is cleared after activation
  // and is never written to secure or ordinary local storage.
  TwoFactorSetup? _setup;
  bool _busy = false;

  @override
  void dispose() {
    _setupCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, LoadState<AuthUser?>>(
      builder: (context, auth) {
        final enabled = auth.value?.twoFactorEnabled ?? false;
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallback: '/account'),
            title: const Text('Account security'),
          ),
          body: ResponsiveLayout(
            mobileBuilder: (context) => ListView(
              padding: const EdgeInsets.all(16),
              children: _content(context, enabled),
            ),
            wideBuilder: (context) => Center(
              child: SizedBox(
                width: 720,
                child: ListView(
                  padding: const EdgeInsets.all(32),
                  children: _content(context, enabled),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, bool enabled) => [
    Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  enabled ? Icons.verified_user : Icons.security,
                  color: enabled ? Theme.of(context).colorScheme.primary : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Two-factor authentication',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(enabled ? 'Active' : 'Inactive')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              enabled
                  ? 'Your account requires a one-time code when you sign in.'
                  : 'Protect your account with a one-time code from an '
                        'authenticator app.',
            ),
            if (_setup != null) ...[
              const SizedBox(height: 20),
              const Text('1. Add this secret to your authenticator app.'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: SelectableText(_setup!.secret)),
                  IconButton(
                    tooltip: 'Copy secret',
                    onPressed: _copySecret,
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Authenticator setup URI'),
                children: [SelectableText(_setup!.provisioningUri)],
              ),
              if (_setup!.recoveryCodes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Save these recovery codes securely:'),
                for (final code in _setup!.recoveryCodes) SelectableText(code),
              ],
              const SizedBox(height: 16),
              const Text('2. Enter a code to finish activation.'),
              const SizedBox(height: 8),
              TextField(
                controller: _setupCode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(
                  labelText: 'Authentication code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _confirmSetup,
                child: const Text('Activate 2FA'),
              ),
            ] else ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : enabled
                    ? _disable
                    : _beginSetup,
                child: Text(enabled ? 'Deactivate 2FA' : 'Set up 2FA'),
              ),
            ],
          ],
        ),
      ),
    ),
    const SizedBox(height: 20),
    Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Permanently delete this account and all data owned by it. '
              'This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _busy ? null : () => _deleteAccount(enabled),
              child: const Text('Delete my account'),
            ),
          ],
        ),
      ),
    ),
  ];

  Future<void> _beginSetup() async {
    setState(() => _busy = true);
    try {
      final setup = await context.read<AuthCubit>().beginTwoFactorSetup();
      if (mounted) setState(() => _setup = setup);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSetup() async {
    final code = _setupCode.text.trim();
    if (code.length < 6) {
      _showError('Enter a valid authentication code.');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthCubit>().confirmTwoFactorSetup(code);
      if (mounted) {
        setState(() {
          _setup = null;
          _setupCode.clear();
        });
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final credentials = await _credentialsDialog(
      title: 'Deactivate 2FA?',
      action: 'Deactivate',
      requiresCode: true,
    );
    if (credentials == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthCubit>().disableTwoFactor(
        password: credentials.password,
        code: credentials.code!,
      );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount(bool requiresCode) async {
    final credentials = await _credentialsDialog(
      title: 'Delete your account?',
      action: 'Delete account',
      requiresCode: requiresCode,
      destructive: true,
    );
    if (credentials == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthCubit>().deleteAccount(
        password: credentials.password,
        code: credentials.code,
      );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<({String password, String? code})?> _credentialsDialog({
    required String title,
    required String action,
    required bool requiresCode,
    bool destructive = false,
  }) async {
    final password = TextEditingController();
    final code = TextEditingController();
    final result = await showDialog<({String password, String? code})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            if (requiresCode) ...[
              const SizedBox(height: 12),
              TextField(
                controller: code,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(
                  labelText: 'Authentication code',
                ),
              ),
            ],
            if (destructive) ...[
              const SizedBox(height: 16),
              const Text(
                'This permanently removes your account and cannot be undone.',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (password.text.isEmpty ||
                  (requiresCode && code.text.trim().length < 6)) {
                return;
              }
              Navigator.pop(context, (
                password: password.text,
                code: requiresCode ? code.text.trim() : null,
              ));
            },
            child: Text(action),
          ),
        ],
      ),
    );
    password.dispose();
    code.dispose();
    return result;
  }

  Future<void> _copySecret() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _setup!.secret));
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Secret copied.')));
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(error))));
  }
}
