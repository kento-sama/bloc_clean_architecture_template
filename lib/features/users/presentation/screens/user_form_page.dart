import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/presentation/cubits/user_cubit.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/users/user_config.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({this.user, super.key});

  final User? user;

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user?.name ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.value;
    final requiredPermission = widget.user == null
        ? userCreatePermission
        : userUpdatePermission;
    if (user?.canAccess(requiredPermission) != true) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallback: userPath),
          title: const Text('Access denied'),
        ),
        body: const Center(
          child: Text('You are not authorized to manage this record.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: userPath),
        title: Text('${widget.user == null ? 'Create' : 'Edit'} user'),
      ),
      body: ResponsiveFormLayout(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _field(_name, 'Name', required: true),
              _field(
                _email,
                'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
                validateEmail: true,
              ),
              _field(
                _password,
                widget.user == null ? 'Password' : 'New password',
                required: widget.user == null,
                obscureText: true,
                helperText: widget.user == null
                    ? null
                    : 'Leave blank to keep the current password',
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save user'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool obscureText = false,
    bool validateEmail = false,
    String? helperText,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: !_isSaving,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        if (validateEmail &&
            value != null &&
            value.isNotEmpty &&
            !value.contains('@')) {
          return 'Enter a valid email address';
        }
        return null;
      },
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final values = <String, Object?>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
    };
    // An empty password on edit means "leave unchanged"; creation requires it.
    if (_password.text.isNotEmpty) values['password'] = _password.text;

    try {
      final cubit = context.read<UserCubit>();
      if (widget.user == null) {
        await cubit.create(values);
      } else {
        await cubit.updateUser(widget.user!.id, values);
      }
      if (mounted) context.go(userPath);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }
}
