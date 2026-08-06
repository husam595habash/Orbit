import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getNotifications({required int page}) async {
    try {
      final response = await _dio.get('/notification', queryParameters: {'page': '$page'});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> markAllAsRead({required int page}) async {
    try {
      final response = await _dio.patch('/notification/read', queryParameters: {'page': '$page'});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ref.watch(apiClientProvider));
});
