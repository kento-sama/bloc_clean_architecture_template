import 'package:clean_bloc/features/roles/domain/entities/role.dart';

class RoleModel extends Role {
  const RoleModel({
    required super.id,
    required super.name,
    required super.permissions,
  });

  factory RoleModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id == null) {
      throw const FormatException(
        'A role returned by the API must have an id.',
      );
    }
    if (!json.containsKey('permissions')) {
      throw const FormatException(
        'The roles API must return assigned permissions.',
      );
    }
    return RoleModel(
      id: id.toString(),
      name: json['name']?.toString() ?? '',
      permissions: _requiredNames(json['permissions']),
    );
  }

  static List<String> _requiredNames(Object? values) {
    if (values is! List) {
      throw const FormatException(
        'The roles API must return permissions as a list.',
      );
    }
    return values
        .map(
          (value) => value is Map ? value['name']?.toString() ?? '' : '$value',
        )
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'permissions': permissions,
  };
}
