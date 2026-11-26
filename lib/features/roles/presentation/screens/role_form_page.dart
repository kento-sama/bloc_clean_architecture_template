import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/roles/domain/entities/role.dart';
import 'package:clean_bloc/features/roles/presentation/cubits/role_cubit.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/roles/role_config.dart';

class RoleFormPage extends StatefulWidget {
  const RoleFormPage({this.role, super.key});

  final Role? role;

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.role?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.value;
    final requiredPermission = widget.role == null
        ? roleCreatePermission
        : roleUpdatePermission;
    if (user?.canAccess(requiredPermission) != true) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallback: rolePath),
          title: const Text('Access denied'),
        ),
        body: const Center(
          child: Text('You are not authorized to manage this record.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: rolePath),
        title: Text('${widget.role == null ? 'Create' : 'Edit'} role'),
      ),
      body: ResponsiveFormLayout(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Role name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Role name is required'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save role'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    // The presence of a role selects update; no role means a new record.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final values = <String, Object?>{'name': _name.text.trim()};
    try {
      final cubit = context.read<RoleCubit>();
      if (widget.role == null) {
        await cubit.create(values);
      } else {
        await cubit.updateRole(widget.role!.id, values);
      }
      if (mounted) context.go(rolePath);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }
}
