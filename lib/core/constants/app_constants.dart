// ══════════════════════════════════════════════════════════════
//  SUITCASE — API & App Constants
// ══════════════════════════════════════════════════════════════

class AppConstants {
  // ── Backend (swap with your Render/Railway URL after deploy) ──
  static const String backendBaseUrl = 'https://suitcase-backend.onrender.com';
  // static const String backendBaseUrl = 'http://10.0.2.2:8080';

  // Local dev: 'http://10.0.2.2:8080' for Android emulator
  //            'http://localhost:8080' for iOS simulator

  static const String generateLookEndpoint = '$backendBaseUrl/api/v1/generate-look';
  static const String generateTripEndpoint  = '$backendBaseUrl/api/v1/generate-experience';

  // ── App ────────────────────────────────────────────────────
  static const String appName         = 'SUITCASE';
  static const String appVersion      = '1.0.0';
  static const int    requestTimeoutS = 30;

  // ── Firestore Collections ──────────────────────────────────
  static const String usersCollection      = 'users';
  static const String savedLooksCollection = 'saved_looks';
  static const String tripsCollection      = 'trips';
}

// Vibe data used across Onboarding + Home + Travel
class StyleVibe {
  final String name;
  final String subtitle;
  final String description; // shown on home
  final String symbol;
  final int chipColorValue;

  const StyleVibe({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.symbol,
    required this.chipColorValue,
  });
}

const List<StyleVibe> kStyleVibes = [
  StyleVibe(
    name: 'Minimalist',
    subtitle: 'Clean lines, neutral tones',
    description: 'Structural simplicity with intentional restraint.',
    symbol: '○',
    chipColorValue: 0xFFCDC8BF,
  ),
  StyleVibe(
    name: 'Streetwear',
    subtitle: 'Bold, urban, effortless',
    description: 'Culture-first dressing with an edge.',
    symbol: '◆',
    chipColorValue: 0xFF242220,
  ),
  StyleVibe(
    name: 'Dark Academia',
    subtitle: 'Literary, layered, moody',
    description: 'Intellectual dressing rooted in texture.',
    symbol: '◉',
    chipColorValue: 0xFF3A3020,
  ),
  StyleVibe(
    name: 'Coquette',
    subtitle: 'Soft, feminine, dreamy',
    description: 'Delicate details with quiet confidence.',
    symbol: '◇',
    chipColorValue: 0xFFCFA0AC,
  ),
  StyleVibe(
    name: 'Old Money',
    subtitle: 'Tailored, quiet luxury',
    description: 'Heritage fabrics. Nothing loud. Nothing fast.',
    symbol: '▲',
    chipColorValue: 0xFF7A6548,
  ),
  StyleVibe(
    name: 'Elevated Casual',
    subtitle: 'Smart, relaxed, real',
    description: 'The art of looking undone and polished at once.',
    symbol: '●',
    chipColorValue: 0xFF526659,
  ),
  StyleVibe(
    name: 'Avant-Garde',
    subtitle: 'Sculptural, provocative',
    description: 'Fashion as art. Silhouettes that challenge.',
    symbol: '◈',
    chipColorValue: 0xFF3B4A5C,
  ),
  StyleVibe(
    name: 'Boho Luxe',
    subtitle: 'Free-spirited, rich textures',
    description: 'Natural layering with artisanal soul.',
    symbol: '✦',
    chipColorValue: 0xFFAA8B5E,
  ),
];