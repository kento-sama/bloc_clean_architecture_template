import 'package:dio/dio.dart';
import 'package:clean_bloc/core/config/api_endpoints.dart';
import 'package:clean_bloc/features/permissions/data/models/permission_model.dart';

/// Translates permission operations to the Laravel REST endpoints.
class PermissionRemoteDataSource {
  const PermissionRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<PermissionModel>> list() async {
    final response = await _dio.get<Object?>(ApiEndpoints.permissions);
    final payload = _unwrap(response.data);
    if (payload is! List) {
      throw const FormatException(
        'The permissions API returned an invalid list.',
      );
    }
    // Validate each record before converting the API list into domain objects.
    return payload.map(_asMap).map(PermissionModel.fromJson).toList();
  }

  Future<void> create(Map<String, Object?> values) async {
    await _dio.post<Object?>(ApiEndpoints.permissions, data: values);
  }

  Future<void> update(String id, Map<String, Object?> values) async {
    await _dio.put<Object?>(ApiEndpoints.permission(id), data: values);
  }

  Future<void> delete(String id) async {
    await _dio.delete<Object?>(ApiEndpoints.permission(id));
  }

  Object? _unwrap(Object? value) =>
      value is Map && value.containsKey('data') ? value['data'] : value;

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException(
      'The permissions API returned an invalid record.',
    );
  }
}
