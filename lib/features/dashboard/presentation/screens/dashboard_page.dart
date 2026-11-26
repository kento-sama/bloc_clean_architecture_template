import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/app_modules.dart';
import 'package:clean_bloc/core/presentation/app_feature.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  try {
                    await context.read<AuthCubit>().logout();
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage(error))),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: ResponsiveLayout(
            mobileBuilder: (context) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _welcome(context, user),
                const SizedBox(height: 20),
                Text(
                  'Available modules',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final feature in appModules)
                  if (user.canAccess(feature.viewPermission))
                    _moduleCard(context, feature),
                if (appModules.every(
                  (feature) => !user.canAccess(feature.viewPermission),
                ))
                  _noModulesMessage(),
                const SizedBox(height: 16),
                _authorizationNote(context),
              ],
            ),
            wideBuilder: (context) {
              final modules = appModules
                  .where((feature) => user.canAccess(feature.viewPermission))
                  .toList();
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  _welcome(context, user),
                  const SizedBox(height: 24),
                  Text(
                    'Available modules',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (modules.isEmpty)
                    _noModulesMessage()
                  else
                    GridView.extent(
                      maxCrossAxisExtent: 360,
                      mainAxisExtent: 110,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final feature in modules)
                          _moduleCard(context, feature),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _authorizationNote(context),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _welcome(BuildContext context, AuthUser user) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(user.email),
          const SizedBox(height: 8),
          Text('Roles: ${user.roles.isEmpty ? 'none' : user.roles.join(', ')}'),
        ],
      ),
    ),
  );

  Widget _moduleCard(BuildContext context, AppFeature feature) => Card(
    child: ListTile(
      leading: Icon(feature.icon),
      title: Text(feature.title),
      subtitle: Text('Requires ${feature.viewPermission}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(feature.path),
    ),
  );

  Widget _noModulesMessage() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Text(
      'No modules are available for this account. Ask an '
      'administrator to assign permissions.',
    ),
  );

  Widget _authorizationNote(BuildContext context) => Text(
    'The app hides unavailable features for usability. Laravel must '
    'still enforce every permission on each API request.',
    style: Theme.of(context).textTheme.bodySmall,
  );
}
