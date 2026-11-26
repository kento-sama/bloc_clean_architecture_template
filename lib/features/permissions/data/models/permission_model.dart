import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';

class PermissionModel extends Permission {
  const PermissionModel({
    required super.id,
    required super.name,
    required super.guardName,
  });

  factory PermissionModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id == null) {
      throw const FormatException(
        'A permission returned by the API must have an id.',
      );
    }
    return PermissionModel(
      id: id.toString(),
      name: json['name']?.toString() ?? '',
      guardName: json['guard_name']?.toString() ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'guard_name': guardName,
  };
}
