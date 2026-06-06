// ══════════════════════════════════════════════════════════════
//  SUITCASE — Phase 2 Trip Models
// ══════════════════════════════════════════════════════════════

import 'lookbook_models.dart';

// ─── Trip Request ─────────────────────────────────────────────
class TripRequest {
  final String destination;
  final String month;
  final int durationDays;
  final String stylePreference;

  const TripRequest({
    required this.destination,
    required this.month,
    required this.durationDays,
    required this.stylePreference,
  });

  Map<String, dynamic> toJson() => {
    'destination': destination,
    'month': month,
    'duration_days': durationDays,
    'style_preference': stylePreference,
  };
}

// ─── Curated Location ─────────────────────────────────────────
class CuratedLocation {
  final String placeName;
  final String streetAddress;
  final String aestheticJustification;
  final String? suggestedTime; // e.g. "10:00 AM"
  final String? locationType;  // e.g. "Café", "Museum", "Market"

  const CuratedLocation({
    required this.placeName,
    required this.streetAddress,
    required this.aestheticJustification,
    this.suggestedTime,
    this.locationType,
  });

  factory CuratedLocation.fromJson(Map<String, dynamic> j) => CuratedLocation(
    placeName: j['place_name'] ?? '',
    streetAddress: j['street_address'] ?? '',
    aestheticJustification: j['aesthetic_justification'] ?? '',
    suggestedTime: j['suggested_time'],
    locationType: j['location_type'],
  );

  Map<String, dynamic> toJson() => {
    'place_name': placeName,
    'street_address': streetAddress,
    'aesthetic_justification': aestheticJustification,
    'suggested_time': suggestedTime,
    'location_type': locationType,
  };
}

// ─── Daily Plan ───────────────────────────────────────────────
class DailyPlan {
  final int dayNumber;
  final String themeTitle;       // e.g. "Neon Minimalist & Shibuya Crossings"
  final String weatherForecast;
  final FashionProfile fashionProfile;
  final List<String> visualAssets;
  final List<CuratedLocation> curatedLocations;
  final List<String> packItems;  // key pieces for this day

  const DailyPlan({
    required this.dayNumber,
    required this.themeTitle,
    required this.weatherForecast,
    required this.fashionProfile,
    required this.visualAssets,
    required this.curatedLocations,
    required this.packItems,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> j) => DailyPlan(
    dayNumber: j['day_number'] ?? 0,
    themeTitle: j['theme_title'] ?? '',
    weatherForecast: j['weather_forecast'] ?? '',
    fashionProfile: FashionProfile.fromJson(j['fashion_profile'] ?? {}),
    visualAssets: List<String>.from(j['visual_assets'] ?? []),
    curatedLocations: (j['curated_locations'] as List<dynamic>? ?? [])
        .map((e) => CuratedLocation.fromJson(e as Map<String, dynamic>))
        .toList(),
    packItems: List<String>.from(j['pack_items'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'day_number': dayNumber,
    'theme_title': themeTitle,
    'weather_forecast': weatherForecast,
    'fashion_profile': fashionProfile.toJson(),
    'visual_assets': visualAssets,
    'curated_locations': curatedLocations.map((l) => l.toJson()).toList(),
    'pack_items': packItems,
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
  final List<String> masterPackList; // deduplicated across all days

  const TripItinerary({
    required this.tripId,
    required this.destination,
    required this.month,
    required this.durationDays,
    required this.overallVibe,
    required this.days,
    required this.masterPackList,
  });

  factory TripItinerary.fromJson(Map<String, dynamic> j) {
    final days = (j['itinerary_days'] as List<dynamic>? ?? [])
        .map((e) => DailyPlan.fromJson(e as Map<String, dynamic>))
        .toList();

    // Build master pack list — deduplicated across all days
    final allItems = <String>{};
    for (final day in days) {
      allItems.addAll(day.packItems);
    }

    return TripItinerary(
      tripId: j['trip_id'] ?? '',
      destination: j['destination'] ?? '',
      month: j['month'] ?? '',
      durationDays: j['duration_days'] ?? days.length,
      overallVibe: j['overall_vibe'] ?? '',
      days: days,
      masterPackList: allItems.toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'destination': destination,
    'month': month,
    'duration_days': durationDays,
    'overall_vibe': overallVibe,
    'itinerary_days': days.map((d) => d.toJson()).toList(),
    'master_pack_list': masterPackList,
  };
}

// ─── Saved Trip (Firestore) ───────────────────────────────────
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