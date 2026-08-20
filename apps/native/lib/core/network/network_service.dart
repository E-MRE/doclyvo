import 'dart:io';

import 'package:dio/dio.dart';

import 'package:doclyvo/core/error/response_exception.dart';
import 'package:doclyvo/core/models/api_response_model.dart';

abstract class NetworkService {
  const NetworkService();

  /// Fetch data with JSON response and automatic deserialization.
  ///
  /// Used for standard API endpoints that return JSON.
  /// Throws [ResponseException] if response.isSuccess is false.
  Future<ApiResponseModel<TData>> fetchData<TData>({
    required String endpoint,
    required TData Function(dynamic) parser,
    Map<String, dynamic>? queryParameters,
  });

  /// Post data with JSON response and automatic deserialization.
  ///
  /// Used for standard API endpoints that accept JSON and return JSON.
  /// Throws [ResponseException] if response.isSuccess is false.
  Future<ApiResponseModel<TData>> postData<TData>({
    required String endpoint,
    required Object body,
    required TData Function(dynamic) parser,
    Map<String, dynamic>? queryParameters,
  });

  /// Upload a file and receive raw bytes response with metadata headers.
  ///
  /// Used for tool-processing endpoints (/tools/<name>) that:
  /// - Accept: multipart/form-data with file + optional form fields
  /// - Return: raw file bytes (FileResponse) + custom headers (X-Original-Size, etc.)
  ///
  /// [endpoint] - API endpoint path
  /// [file] - File to upload
  /// [formFields] - Additional form fields for tool settings (optional)
  ///
  /// Returns response with [bytes] (the processed file) and [headers] (metadata).
  /// Throws [ResponseException] if response status code indicates failure.
  Future<FileUploadResponse> uploadFileAndGetBytes({
    required String endpoint,
    required File file,
    Map<String, dynamic>? formFields,
  });
}

/// Response from file upload endpoints that return raw bytes + metadata headers.
final class FileUploadResponse {
  const FileUploadResponse({
    required this.bytes,
    required this.headers,
  });

  /// The raw processed file bytes.
  final List<int> bytes;

  /// Response headers containing metadata (e.g., X-Original-Size, X-Compressed-Size).
  final Headers headers;

  /// Helper to get a specific header value.
  String? getHeader(String name) => headers.value(name);
}
