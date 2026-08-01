import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/cloudinary_config.dart';
import '../../../../core/network/api_exception.dart';

class CloudinaryDataSource {
  CloudinaryDataSource(this._dio);

  final Dio _dio;

  Future<String> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'upload_preset': CloudinaryConfig.uploadPreset,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
        data: formData,
      );
      return response.data!['secure_url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final cloudinaryDataSourceProvider = Provider<CloudinaryDataSource>((ref) {
  return CloudinaryDataSource(Dio());
});
