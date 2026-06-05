// ══════════════════════════════════════════════════════════════
//  SUITCASE — Data Models
// ══════════════════════════════════════════════════════════════

// ─── Look Request (sent to backend) ──────────────────────────
class LookRequest {
  final String destination;
  final String month;
  final String stylePreference;
  final int lookCount; // how many outfit cards to generate

  const LookRequest({
    required this.destination,
    required this.month,
    required this.stylePreference,
    this.lookCount = 3,
  });

  Map<String, dynamic> toJson() => {
    'destination': destination,
    'month': month,
    'style_preference': stylePreference,
    'look_count': lookCount,
  };
}

// ─── Fashion Profile ──────────────────────────────────────────
class FashionProfile {
  final String styleVibe;
  final String stylingDirectives;   // full detailed description
  final String keyPieces;           // e.g. "Camel trench, black turtleneck"
  final String colorStory;          // e.g. "Earthy neutrals anchored by ivory"
  final String searchKeywords;      // used for Unsplash fetch

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

// ─── Single Look Card ─────────────────────────────────────────
class LookCard {
  final String lookId;
  final String occasion;          // e.g. "Morning Café Crawl"
  final String moodTagline;       // e.g. "Effortlessly literary"
  final FashionProfile fashionProfile;
  final List<String> visualAssets; // Unsplash URLs
  final String weatherNote;        // e.g. "Layering essential, 14°C"

  const LookCard({
    required this.lookId,
    required this.occasion,
    required this.moodTagline,
    required this.fashionProfile,
    required this.visualAssets,
    required this.weatherNote,
  });

  factory LookCard.fromJson(Map<String, dynamic> j) => LookCard(
    lookId: j['look_id'] ?? '',
    occasion: j['occasion'] ?? '',
    moodTagline: j['mood_tagline'] ?? '',
    fashionProfile: FashionProfile.fromJson(j['fashion_profile'] ?? {}),
    visualAssets: List<String>.from(j['visual_assets'] ?? []),
    weatherNote: j['weather_note'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'look_id': lookId,
    'occasion': occasion,
    'mood_tagline': moodTagline,
    'fashion_profile': fashionProfile.toJson(),
    'visual_assets': visualAssets,
    'weather_note': weatherNote,
  };
}

// ─── Full Lookbook Response ───────────────────────────────────
class LookbookResponse {
  final String destination;
  final String month;
  final String overallVibe;        // e.g. "Parisian Autumn Intellectualism"
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

// ─── Saved Look (stored in Firestore) ────────────────────────
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

  factory SavedLook.fromFirestore(Map<String, dynamic> data, String docId) => SavedLook(
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