import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';
import 'package:clean_bloc/features/permissions/presentation/cubits/permission_cubit.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';

class PermissionFormPage extends StatefulWidget {
  const PermissionFormPage({this.permission, super.key});

  final Permission? permission;

  @override
  State<PermissionFormPage> createState() => _PermissionFormPageState();
}

class _PermissionFormPageState extends State<PermissionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.permission?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.value;
    final requiredPermission = widget.permission == null
        ? permissionCreatePermission
        : permissionUpdatePermission;
    if (user?.canAccess(requiredPermission) != true) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallback: permissionPath),
          title: const Text('Access denied'),
        ),
        body: const Center(
          child: Text('You are not authorized to manage this record.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: permissionPath),
        title: Text(
          '${widget.permission == null ? 'Create' : 'Edit'} permission',
        ),
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
                  labelText: 'Permission name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Permission name is required'
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
                label: Text(_isSaving ? 'Saving...' : 'Save permission'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    // A null model means creation; otherwise submit an update for its id.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final values = <String, Object?>{'name': _name.text.trim()};
    try {
      final cubit = context.read<PermissionCubit>();
      if (widget.permission == null) {
        await cubit.create(values);
      } else {
        await cubit.updatePermission(widget.permission!.id, values);
      }
      if (mounted) context.go(permissionPath);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }
}
