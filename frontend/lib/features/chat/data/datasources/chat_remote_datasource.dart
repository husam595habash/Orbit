import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/conversation_model.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _dio.get('/chat/conversations');
      final data = response.data as Map<String, dynamic>;
      return (data['conversations'] as List)
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getMessages({
    required String userAId,
    required String userBId,
    required int page,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/messages',
        queryParameters: {'user_a_id': userAId, 'user_b_id': userBId, 'page': '$page'},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAsRead(String senderId) async {
    try {
      await _dio.patch('/chat/messages/read', queryParameters: {'sender_id': senderId});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.watch(apiClientProvider));
});
