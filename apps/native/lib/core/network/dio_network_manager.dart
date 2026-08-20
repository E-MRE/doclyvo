import 'dart:io';

import 'package:dio/dio.dart';

import 'package:doclyvo/core/error/response_exception.dart';
import 'package:doclyvo/core/models/api_response_model.dart';
import 'package:doclyvo/core/network/network_service.dart';

final class DioNetworkManager extends NetworkService {
  const DioNetworkManager(Dio dio) : _dio = dio, super();

  final Dio _dio;

  @override
  Future<ApiResponseModel<TData>> fetchData<TData>({
    required String endpoint,
    required TData Function(dynamic) parser,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParameters,
      );
      return ApiResponseModel<TData>.fromJson(
        response.data ?? {},
        parser,
      );
    } on Exception catch (e) {
      return ApiResponseModel<TData>(
        isSuccess: false,
        message: _getErrorMessage(e),
      );
    }
  }

  @override
  Future<ApiResponseModel<TData>> postData<TData>({
    required String endpoint,
    required Object body,
    required TData Function(dynamic) parser,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: body,
        queryParameters: queryParameters,
      );
      return ApiResponseModel<TData>.fromJson(
        response.data ?? {},
        parser,
      );
    } on Exception catch (e) {
      return ApiResponseModel<TData>(
        isSuccess: false,
        message: _getErrorMessage(e),
      );
    }
  }

  @override
  Future<FileUploadResponse> uploadFileAndGetBytes({
    required String endpoint,
    required File file,
    Map<String, dynamic>? formFields,
  }) async {
    try {
      final formData = FormData();
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );

      if (formFields != null) {
        formFields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post<List<int>>(
        endpoint,
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw ResponseException(
          'File upload failed with status code: $statusCode',
        );
      }

      return FileUploadResponse(
        bytes: response.data ?? [],
        headers: response.headers,
      );
    } on ResponseException {
      rethrow;
    } on Exception catch (e) {
      throw ResponseException(_getErrorMessage(e));
    }
  }

  String _getErrorMessage(Exception exception) {
    if (exception is DioException) {
      return exception.message ?? 'Network error occurred';
    }
    return exception.toString();
  }
}
