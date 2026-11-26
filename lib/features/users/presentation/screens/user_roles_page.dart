import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/responsive_choice_list.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/roles/presentation/cubits/role_cubit.dart';
import 'package:clean_bloc/features/roles/role_config.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/presentation/cubits/user_cubit.dart';
import 'package:clean_bloc/features/users/user_config.dart';

class UserRolesPage extends StatefulWidget {
  const UserRolesPage({required this.user, super.key});

  final User user;

  @override
  State<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends State<UserRolesPage> {
  // The selected set reflects this user's assigned roles.
  late final Set<String> _selected = widget.user.roles.toSet();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthCubit>().state.value;
    if (currentUser?.canAccess(userAssignRolesPermission) != true ||
        currentUser?.canAccess(roleViewPermission) != true) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallback: userPath),
          title: Text('Roles for ${widget.user.name}'),
        ),
        body: const Center(
          child: Text('You are not authorized to manage user roles.'),
        ),
      );
    }

    final roles = context.watch<RoleCubit>().state;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: userPath),
        title: Text('Roles for ${widget.user.name}'),
      ),
      body: roles.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roles.hasError
          ? _LoadError(
              message: errorMessage(roles.error!),
              onRetry: () => context.read<RoleCubit>().load(),
            )
          : Builder(
              builder: (_) {
                final items = roles.value ?? const [];
                // Retain assignments that are no longer in the available role list
                // so they can still be removed.
                final names = {
                  ...items.map((role) => role.name),
                  ..._selected,
                }.toList()..sort();
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Changes are applied immediately.'),
                    ),
                    Expanded(
                      child: names.isEmpty
                          ? const Center(child: Text('No roles available.'))
                          : ResponsiveChoiceList(
                              choices: names,
                              isSelected: _selected.contains,
                              isSaving: _isSaving,
                              onChanged: _changeRole,
                            ),
                    ),
                    if (_isSaving) const LinearProgressIndicator(),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _changeRole(String name, bool assign) async {
    setState(() => _isSaving = true);
    try {
      final cubit = context.read<UserCubit>();
      if (assign) {
        await cubit.assignRoles(widget.user.id, [name]);
      } else {
        await cubit.unassignRoles(widget.user.id, [name]);
      }
      if (!mounted) return;
      setState(() {
        if (assign) {
          _selected.add(name);
        } else {
          _selected.remove(name);
        }
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
