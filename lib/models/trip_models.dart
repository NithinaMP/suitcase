import 'lookbook_models.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Trip Models v2
//  Pack items now categorised: The Base / The Layers / The Accents
//  Locations now include golden_hour_time and golden_hour_tip
// ══════════════════════════════════════════════════════════════

class TripRequest {
  final String destination;
  final String month;
  final int durationDays;
  final String stylePreference;
  final bool sustainable;

  const TripRequest({
    required this.destination,
    required this.month,
    required this.durationDays,
    required this.stylePreference,
    this.sustainable = false,
  });

  Map<String, dynamic> toJson() => {
    'destination': destination,
    'month': month,
    'duration_days': durationDays,
    'style_preference': stylePreference,
    'sustainable': sustainable,
  };
}

// ─── Pack Category (The Base / The Layers / The Accents) ──────
class PackCategory {
  final String category;
  final List<String> items;

  const PackCategory({required this.category, required this.items});

  factory PackCategory.fromJson(Map<String, dynamic> j) => PackCategory(
    category: j['category'] ?? '',
    items: List<String>.from(j['items'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'category': category,
    'items': items,
  };
}

// ─── Curated Location ─────────────────────────────────────────
class CuratedLocation {
  final String placeName;
  final String streetAddress;
  final String aestheticJustification;
  final String? suggestedTime;
  final String? locationType;
  final String? goldenHourTime;
  final String? goldenHourTip;

  const CuratedLocation({
    required this.placeName,
    required this.streetAddress,
    required this.aestheticJustification,
    this.suggestedTime,
    this.locationType,
    this.goldenHourTime,
    this.goldenHourTip,
  });

  factory CuratedLocation.fromJson(Map<String, dynamic> j) => CuratedLocation(
    placeName: j['place_name'] ?? '',
    streetAddress: j['street_address'] ?? '',
    aestheticJustification: j['aesthetic_justification'] ?? '',
    suggestedTime: j['suggested_time'],
    locationType: j['location_type'],
    goldenHourTime: j['golden_hour_time'],
    goldenHourTip: j['golden_hour_tip'],
  );

  Map<String, dynamic> toJson() => {
    'place_name': placeName,
    'street_address': streetAddress,
    'aesthetic_justification': aestheticJustification,
    'suggested_time': suggestedTime,
    'location_type': locationType,
    'golden_hour_time': goldenHourTime,
    'golden_hour_tip': goldenHourTip,
  };
}

// ─── Daily Plan ───────────────────────────────────────────────
class DailyPlan {
  final int dayNumber;
  final String themeTitle;
  final String weatherForecast;
  final FashionProfile fashionProfile;
  final List<String> visualAssets;
  final List<CuratedLocation> curatedLocations;
  final List<PackCategory> packCategories; // OOTD categorised

  const DailyPlan({
    required this.dayNumber,
    required this.themeTitle,
    required this.weatherForecast,
    required this.fashionProfile,
    required this.visualAssets,
    required this.curatedLocations,
    required this.packCategories,
  });

  // Flat list of all pack items across all categories
  List<String> get allPackItems =>
      packCategories.expand((c) => c.items).toList();

  factory DailyPlan.fromJson(Map<String, dynamic> j) {
    // Handle both new categorised format and old flat list
    List<PackCategory> categories = [];
    final rawPack = j['pack_items'];
    if (rawPack is List) {
      if (rawPack.isNotEmpty && rawPack[0] is Map) {
        // New categorised format
        categories = rawPack
            .map((e) => PackCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        // Old flat string list — wrap in single category
        categories = [
          PackCategory(
            category: 'Key Pieces',
            items: List<String>.from(rawPack),
          ),
        ];
      }
    }

    return DailyPlan(
      dayNumber: j['day_number'] ?? 0,
      themeTitle: j['theme_title'] ?? '',
      weatherForecast: j['weather_forecast'] ?? '',
      fashionProfile: FashionProfile.fromJson(j['fashion_profile'] ?? {}),
      visualAssets: List<String>.from(j['visual_assets'] ?? []),
      curatedLocations: (j['curated_locations'] as List<dynamic>? ?? [])
          .map((e) => CuratedLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      packCategories: categories,
    );
  }

  Map<String, dynamic> toJson() => {
    'day_number': dayNumber,
    'theme_title': themeTitle,
    'weather_forecast': weatherForecast,
    'fashion_profile': fashionProfile.toJson(),
    'visual_assets': visualAssets,
    'curated_locations': curatedLocations.map((l) => l.toJson()).toList(),
    'pack_items': packCategories.map((c) => c.toJson()).toList(),
  };
}

// ─── Full Trip Itinerary ──────────────────────────────────────
class TripItinerary {
  final String tripId;
  final String destination;
  final String month;
  final int durationDays;
  final String overallVibe;
  final List<DailyPlan> days;

  const TripItinerary({
    required this.tripId,
    required this.destination,
    required this.month,
    required this.durationDays,
    required this.overallVibe,
    required this.days,
  });

  // Deduplicated master pack list with categories preserved
  Map<String, Set<String>> get masterPackByCategory {
    final map = <String, Set<String>>{};
    for (final day in days) {
      for (final cat in day.packCategories) {
        map.putIfAbsent(cat.category, () => {}).addAll(cat.items);
      }
    }
    return map;
  }

  factory TripItinerary.fromJson(Map<String, dynamic> j) {
    final days = (j['itinerary_days'] as List<dynamic>? ?? [])
        .map((e) => DailyPlan.fromJson(e as Map<String, dynamic>))
        .toList();

    return TripItinerary(
      tripId: j['trip_id'] ?? '',
      destination: j['destination'] ?? '',
      month: j['month'] ?? '',
      durationDays: j['duration_days'] ?? days.length,
      overallVibe: j['overall_vibe'] ?? '',
      days: days,
    );
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'destination': destination,
    'month': month,
    'duration_days': durationDays,
    'overall_vibe': overallVibe,
    'itinerary_days': days.map((d) => d.toJson()).toList(),
  };
}

// ─── Saved Trip ───────────────────────────────────────────────
class SavedTrip {
  final String id;
  final String userId;
  final TripItinerary itinerary;
  final DateTime savedAt;

  const SavedTrip({
    required this.id,
    required this.userId,
    required this.itinerary,
    required this.savedAt,
  });

  factory SavedTrip.fromFirestore(Map<String, dynamic> data, String docId) =>
      SavedTrip(
        id: docId,
        userId: data['user_id'] ?? '',
        itinerary: TripItinerary.fromJson(data['itinerary'] ?? {}),
        savedAt: (data['saved_at'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'itinerary': itinerary.toJson(),
    'saved_at': savedAt,
  };
}