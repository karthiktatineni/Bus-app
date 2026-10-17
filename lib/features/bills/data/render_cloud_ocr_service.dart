import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/ocr_service.dart';

class RenderCloudOcrService implements OcrService {
  RenderCloudOcrService({http.Client? client, String? serviceUrl})
      : _client = client ?? http.Client(),
        _serviceUrl = serviceUrl ??
            const String.fromEnvironment(
              'OCR_SERVICE_URL',
              defaultValue: 'https://fleetpulse-ocr.onrender.com',
            );

  final http.Client _client;
  final String _serviceUrl;

  @override
  Future<OcrResult> scanBill(String imagePath) async {
    if (_serviceUrl.isEmpty) {
      throw StateError('OCR_SERVICE_URL was not configured for this build.');
    }
    final image = File(imagePath);
    if (!await image.exists()) {
      throw ArgumentError.value(
          imagePath, 'imagePath', 'The selected image does not exist.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_serviceUrl/ocr/scan-bill'),
    )..files.add(await http.MultipartFile.fromPath(
        'file',
        imagePath,
        filename: p.basename(imagePath),
        contentType: MediaType('image', 'jpeg'),
      ));
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw StateError('A signed-in session is required to scan a bill.');
    }
    request.headers['Authorization'] = 'Bearer $accessToken';
    final streamed =
        await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = '';
      try {
        final error = jsonDecode(response.body);
        if (error is Map<String, dynamic> && error['detail'] is String) {
          detail = ': ${error['detail']}';
        } else if (error is Map<String, dynamic> && error['detail'] is List) {
          final messages = (error['detail'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => item['msg'])
              .whereType<String>()
              .where((message) => message.isNotEmpty)
              .toList();
          if (messages.isNotEmpty) detail = ': ${messages.join('; ')}';
        }
      } catch (_) {
        // Keep the status code when the server response is not JSON.
      }
      throw HttpException(
          'Bill scanning failed (${response.statusCode})$detail.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rawDate = payload['bill_date'] as String?;
    return OcrResult(
      vendor: payload['vendor'] as String?,
      billNo: payload['invoice_number'] as String?,
      billDate: rawDate == null ? null : DateTime.tryParse(rawDate),
      total: (payload['grand_total'] as num?)?.toDouble(),
      confidence: (payload['confidence'] as num?)?.toDouble() ?? 0,
      rawLines:
          (payload['raw_lines'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}
