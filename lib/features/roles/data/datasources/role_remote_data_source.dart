import 'package:dio/dio.dart';
import 'package:clean_bloc/core/config/api_endpoints.dart';
import 'package:clean_bloc/features/roles/data/models/role_model.dart';

/// Handles role CRUD plus the separate role-permission relationship endpoint.
class RoleRemoteDataSource {
  const RoleRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<RoleModel>> list() async {
    final response = await _dio.get<Object?>(ApiEndpoints.roles);
    final payload = _unwrap(response.data);
    if (payload is! List) {
      throw const FormatException('The roles API returned an invalid list.');
    }
    return payload.map(_asMap).map(RoleModel.fromJson).toList();
  }

  Future<void> create(Map<String, Object?> values) async {
    await _dio.post<Object?>(ApiEndpoints.roles, data: values);
  }

  Future<void> update(String id, Map<String, Object?> values) async {
    await _dio.put<Object?>(ApiEndpoints.role(id), data: values);
  }

  Future<void> grantPermissions(String id, List<String> permissions) async {
    // Relationship changes use the collection endpoint and a list of names.
    await _dio.post<Object?>(
      ApiEndpoints.rolePermissions(id),
      data: {'permissions': permissions},
    );
  }

  Future<void> revokePermissions(String id, List<String> permissions) async {
    await _dio.delete<Object?>(
      ApiEndpoints.rolePermissions(id),
      data: {'permissions': permissions},
    );
  }

  Future<void> delete(String id) async {
    await _dio.delete<Object?>(ApiEndpoints.role(id));
  }

  Object? _unwrap(Object? value) =>
      value is Map && value.containsKey('data') ? value['data'] : value;

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException('The roles API returned an invalid record.');
  }
}
