import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/lookbook_models.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — API Service
//  Handles all communication with the Node.js backend.
//  Backend now uses Pexels (not Unsplash) for images.
// ══════════════════════════════════════════════════════════════

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();

  // ── Generate Lookbook ─────────────────────────────────────
  Future<LookbookResponse> generateLookbook(LookRequest request) async {
    try {
      final response = await _client
          .post(
        Uri.parse(AppConstants.generateLookEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      )
          .timeout(const Duration(seconds: AppConstants.requestTimeoutS));

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return LookbookResponse.fromJson(data);

        case 429:
          throw ApiException(
            'Too many requests. Please wait a moment and try again.',
            statusCode: 429,
          );

        case 400:
          throw ApiException(
            'Invalid request. Check your inputs and try again.',
            statusCode: 400,
          );

        case 503:
          throw ApiException(
            'Service temporarily unavailable. Try again shortly.',
            statusCode: 503,
          );

        default:
          throw ApiException(
            'Something went wrong (${response.statusCode}). Please try again.',
            statusCode: response.statusCode,
          );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Check your connection and try again.');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}