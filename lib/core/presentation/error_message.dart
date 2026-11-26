import 'package:dio/dio.dart';

/// Converts transport and parsing failures into messages suitable for the UI.
String errorMessage(Object error) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    if (error.response?.statusCode == 403) {
      return 'The server denied this action. Check the user permissions.';
    }
    if (error.response?.statusCode == 401) {
      return 'Your session expired. Please sign in again.';
    }
    return error.message ?? 'Could not reach the Laravel API.';
  }
  if (error is FormatException) return error.message;
  return error.toString();
}
