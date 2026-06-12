// ══════════════════════════════════════════════════════════════
//  SUITCASE — Lookbook Data Models v2
// ══════════════════════════════════════════════════════════════

class LookRequest {
  final String destination;
  final String month;
  final String stylePreference;
  final int lookCount;

  const LookRequest({
    required this.destination,
    required this.month,
    required this.stylePreference,
    this.lookCount = 6,
  });

  Map<String, dynamic> toJson() => {
    'destination': destination,
    'month': month,
    'style_preference': stylePreference,
    'look_count': lookCount,
  };
}

class FashionProfile {
  final String styleVibe;
  final String stylingDirectives;
  final String keyPieces;
  final String colorStory;
  final String searchKeywords;

  const FashionProfile({
    required this.styleVibe,
    required this.stylingDirectives,
    required this.keyPieces,
    required this.colorStory,
    required this.searchKeywords,
  });

  factory FashionProfile.fromJson(Map<String, dynamic> j) => FashionProfile(
    styleVibe: j['style_vibe'] ?? '',
    stylingDirectives: j['styling_directives'] ?? '',
    keyPieces: j['key_pieces'] ?? '',
    colorStory: j['color_story'] ?? '',
    searchKeywords: j['search_keywords'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'style_vibe': styleVibe,
    'styling_directives': stylingDirectives,
    'key_pieces': keyPieces,
    'color_story': colorStory,
    'search_keywords': searchKeywords,
  };
}

class LookCard {
  final String lookId;
  final String occasion;
  final String moodTagline;
  final FashionProfile fashionProfile;
  final List<String> visualAssets;
  final String weatherNote;
  final String? goldenHourTime;  // e.g. "4:30 PM"
  final String? goldenHourTip;   // full tip text

  const LookCard({
    required this.lookId,
    required this.occasion,
    required this.moodTagline,
    required this.fashionProfile,
    required this.visualAssets,
    required this.weatherNote,
    this.goldenHourTime,
    this.goldenHourTip,
  });

  factory LookCard.fromJson(Map<String, dynamic> j) => LookCard(
    lookId: j['look_id'] ?? '',
    occasion: j['occasion'] ?? '',
    moodTagline: j['mood_tagline'] ?? '',
    fashionProfile: FashionProfile.fromJson(j['fashion_profile'] ?? {}),
    visualAssets: List<String>.from(j['visual_assets'] ?? []),
    weatherNote: j['weather_note'] ?? '',
    goldenHourTime: j['golden_hour_time'],
    goldenHourTip: j['golden_hour_tip'],
  );

  Map<String, dynamic> toJson() => {
    'look_id': lookId,
    'occasion': occasion,
    'mood_tagline': moodTagline,
    'fashion_profile': fashionProfile.toJson(),
    'visual_assets': visualAssets,
    'weather_note': weatherNote,
    'golden_hour_time': goldenHourTime,
    'golden_hour_tip': goldenHourTip,
  };
}

class LookbookResponse {
  final String destination;
  final String month;
  final String overallVibe;
  final List<LookCard> looks;

  const LookbookResponse({
    required this.destination,
    required this.month,
    required this.overallVibe,
    required this.looks,
  });

  factory LookbookResponse.fromJson(Map<String, dynamic> j) => LookbookResponse(
    destination: j['destination'] ?? '',
    month: j['month'] ?? '',
    overallVibe: j['overall_vibe'] ?? '',
    looks: (j['looks'] as List<dynamic>? ?? [])
        .map((e) => LookCard.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class SavedLook {
  final String id;
  final String userId;
  final LookCard look;
  final String destination;
  final String month;
  final DateTime savedAt;

  const SavedLook({
    required this.id,
    required this.userId,
    required this.look,
    required this.destination,
    required this.month,
    required this.savedAt,
  });

  factory SavedLook.fromFirestore(Map<String, dynamic> data, String docId) =>
      SavedLook(
        id: docId,
        userId: data['user_id'] ?? '',
        look: LookCard.fromJson(data['look'] ?? {}),
        destination: data['destination'] ?? '',
        month: data['month'] ?? '',
        savedAt: (data['saved_at'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'look': look.toJson(),
    'destination': destination,
    'month': month,
    'saved_at': savedAt,
  };
}