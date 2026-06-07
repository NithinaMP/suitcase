import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/lookbook_models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();

  // ── Prompt-based lookbook generation ─────────────────────
  Future<LookbookResponse> generateFromPrompt(Map<String, dynamic> body) async {
    try {
      final response = await _client.post(
        Uri.parse(AppConstants.generateLookEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: AppConstants.requestTimeoutS));

      switch (response.statusCode) {
        case 200:
          return LookbookResponse.fromJson(
              jsonDecode(response.body) as Map<String, dynamic>);
        case 429:
          throw ApiException('Too many requests. Please wait.', statusCode: 429);
        case 400:
          throw ApiException('Invalid request.', statusCode: 400);
        default:
          throw ApiException('Error ${response.statusCode}.', statusCode: response.statusCode);
      }
    } on ApiException { rethrow; }
    catch (e) { throw ApiException('Network error. Check your connection.'); }
  }

  // ── Legacy method kept for compatibility ──────────────────
  Future<LookbookResponse> generateLookbook(LookRequest request) async {
    return generateFromPrompt(request.toJson());
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}