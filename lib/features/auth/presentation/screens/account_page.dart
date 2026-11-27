import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';

/// Account details are rendered from the shared AuthCubit session state.
/// Keeping this page provider-independent of fields makes security changes
/// immediately visible after the Cubit restores the server-backed user.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, LoadState<AuthUser?>>(
      builder: (context, auth) {
        final user = auth.value;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallback: '/dashboard'),
            title: const Text('My account'),
          ),
          body: ResponsiveLayout(
            mobileBuilder: (context) => ListView(
              padding: const EdgeInsets.all(16),
              children: _content(context, user),
            ),
            wideBuilder: (context) => Center(
              child: SizedBox(
                width: 720,
                child: ListView(
                  padding: const EdgeInsets.all(32),
                  children: _content(context, user),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, AuthUser user) => [
    Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    user.name.trim().isEmpty
                        ? '?'
                        : user.name.trim().characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(user.email),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detail(context, 'Account ID', user.id),
            const SizedBox(height: 16),
            Text('Roles', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (user.roles.isEmpty)
              const Text('No roles assigned')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in user.roles) Chip(label: Text(role)),
                ],
              ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 20),
    Card(
      child: ListTile(
        leading: Icon(
          user.twoFactorEnabled ? Icons.verified_user : Icons.security,
        ),
        title: const Text('Account security'),
        subtitle: Text(
          user.twoFactorEnabled
              ? 'Two-factor authentication is active'
              : 'Manage 2FA and account deletion',
        ),
        trailing: const Icon(Icons.chevron_right),
        // push preserves the account page so the Back button naturally returns
        // after a security setting changes.
        onTap: () => context.push('/account/security'),
      ),
    ),
  ];

  Widget _detail(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      SelectableText(value),
    ],
  );
}
