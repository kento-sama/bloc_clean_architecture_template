import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.permissions,
    required super.roles,
  });

  factory AuthUserModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id == null) {
      throw const FormatException('The authenticated user must have an id.');
    }
    return AuthUserModel(
      id: id.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      permissions: _names(json['permissions']),
      roles: _names(json['roles']),
    );
  }

  static Set<String> _names(Object? values) {
    if (values is! List) return const {};
    return values
        .map((value) {
          if (value is Map) return value['name']?.toString() ?? '';
          return value.toString();
        })
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'permissions': permissions.toList(),
    'roles': roles.toList(),
  };
}
