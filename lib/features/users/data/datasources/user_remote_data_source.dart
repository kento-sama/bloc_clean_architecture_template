import 'package:dio/dio.dart';
import 'package:clean_bloc/core/config/api_endpoints.dart';
import 'package:clean_bloc/features/users/data/models/user_model.dart';

/// Maps user CRUD and relationship changes to Laravel API requests.
class UserRemoteDataSource {
  const UserRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<UserModel>> list() async {
    final response = await _dio.get<Object?>(ApiEndpoints.users);
    final payload = _unwrap(response.data);
    if (payload is! List) {
      throw const FormatException('The users API returned an invalid list.');
    }
    return payload.map(_asMap).map(UserModel.fromJson).toList();
  }

  Future<void> create(Map<String, Object?> values) async {
    await _dio.post<Object?>(ApiEndpoints.users, data: values);
  }

  Future<void> update(String id, Map<String, Object?> values) async {
    await _dio.put<Object?>(ApiEndpoints.user(id), data: values);
  }

  Future<void> assignRoles(String id, List<String> roles) async {
    // Roles and direct permissions have separate endpoints and payload keys.
    await _dio.post<Object?>(
      ApiEndpoints.userRoles(id),
      data: {'roles': roles},
    );
  }

  Future<void> unassignRoles(String id, List<String> roles) async {
    await _dio.delete<Object?>(
      ApiEndpoints.userRoles(id),
      data: {'roles': roles},
    );
  }

  Future<void> grantPermissions(String id, List<String> permissions) async {
    await _dio.post<Object?>(
      ApiEndpoints.userPermissions(id),
      data: {'permissions': permissions},
    );
  }

  Future<void> revokePermissions(String id, List<String> permissions) async {
    await _dio.delete<Object?>(
      ApiEndpoints.userPermissions(id),
      data: {'permissions': permissions},
    );
  }

  Future<void> delete(String id) async {
    await _dio.delete<Object?>(ApiEndpoints.user(id));
  }

  Object? _unwrap(Object? value) =>
      value is Map && value.containsKey('data') ? value['data'] : value;

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException('The users API returned an invalid record.');
  }
}
