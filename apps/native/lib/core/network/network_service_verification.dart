/// Verification script to smoke-test the network layer against a real API endpoint.
///
/// This is NOT part of the app itself — it's a standalone script for P0-4 verification.
/// Run via: `dart lib/core/network/network_service_verification.dart`
///
/// Requirements:
/// 1. A small PDF file to upload (e.g., test.pdf)
/// 2. Access to a real `/tools/<name>` endpoint (e.g., /tools/ocr at api.doclyvo.com)
/// 3. Valid API authentication if required

import 'dart:io';
import 'package:dio/dio.dart';

Future<void> verifyNetworkLayer() async {
  print('=== P0-4 Network Layer Verification ===\n');

  const apiBaseUrl = 'https://api.doclyvo.com';
  const toolEndpoint = '/tools/ocr';

  print('API Base URL: $apiBaseUrl');
  print('Tool Endpoint: $toolEndpoint');
  print('Full URL: $apiBaseUrl$toolEndpoint\n');

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 32),
      receiveTimeout: const Duration(seconds: 32),
      sendTimeout: const Duration(seconds: 32),
    ),
  );

  // Create a test PDF file with minimal content
  const testPdfContent = [
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, // %PDF-1.4\n
  ];

  final tempFile = File('/tmp/test_doclyvo.pdf');
  await tempFile.writeAsBytes(testPdfContent);

  print('Created test PDF: ${tempFile.path} (${testPdfContent.length} bytes)\n');

  try {
    print('Uploading file to $apiBaseUrl$toolEndpoint...\n');

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'file',
        await MultipartFile.fromFile(
          tempFile.path,
          filename: 'test.pdf',
        ),
      ),
    );

    // Add optional form fields for OCR tool
    formData.fields.addAll({
      MapEntry('language', 'tr'),
      MapEntry('format', 'pdf'),
    });

    final response = await dio.post<List<int>>(
      toolEndpoint,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    print('✓ Request succeeded with status: ${response.statusCode}\n');

    // Verify binary response
    print('Response Headers:');
    response.headers.forEach((name, values) {
      print('  $name: ${values.join(", ")}');
    });
    print('');

    // Check for common tool response headers
    final originalSize = response.headers.value('x-original-size');
    final compressedSize = response.headers.value('x-compressed-size');
    final contentLength = response.headers.value('content-length');

    print('Metadata Headers Found:');
    if (originalSize != null) print('  ✓ X-Original-Size: $originalSize');
    if (compressedSize != null) print('  ✓ X-Compressed-Size: $compressedSize');
    if (contentLength != null) print('  ✓ Content-Length: $contentLength');

    // Verify binary response
    final bytes = response.data ?? [];
    print('\nResponse Bytes: ${bytes.length} bytes received\n');

    if (bytes.isNotEmpty) {
      print('✓ Binary response received successfully');
      print('✓ First 10 bytes: ${bytes.take(10).toList()}\n');
    }

    print('=== Verification Complete ===');
    print('✓ Network layer successfully:');
    print('  1. Uploaded file with multipart/form-data');
    print('  2. Received raw bytes (FileResponse)');
    print('  3. Extracted custom response headers');
  } on DioException catch (e) {
    print('✗ DioException: ${e.message}');
    print('  Type: ${e.type}');
    print('  Status Code: ${e.response?.statusCode}');
    if (e.response?.data != null) {
      print('  Response: ${e.response!.data}');
    }
  } on Exception catch (e) {
    print('✗ Exception: $e');
  } finally {
    await tempFile.delete();
    print('\nCleaned up temporary file');
  }
}

void main() {
  verifyNetworkLayer();
}
