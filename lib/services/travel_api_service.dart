import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/trip_models.dart';
import 'api_service.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Travel API Service
// ══════════════════════════════════════════════════════════════

class TravelApiService {
  static final TravelApiService _instance = TravelApiService._internal();
  factory TravelApiService() => _instance;
  TravelApiService._internal();

  final _client = http.Client();

  Future<TripItinerary> generateTrip(TripRequest request) async {
    try {
      final response = await _client
          .post(
        Uri.parse(AppConstants.generateTripEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      )
          .timeout(const Duration(seconds: 45)); // trips take longer than looks

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return TripItinerary.fromJson(data);
        case 429:
          throw ApiException('Too many requests. Please wait and try again.', statusCode: 429);
        case 503:
          throw ApiException('Travel engine is warming up. Try again in 30 seconds.', statusCode: 503);
        default:
          throw ApiException('Something went wrong (${response.statusCode}).', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Check your connection.');
    }
  }
}