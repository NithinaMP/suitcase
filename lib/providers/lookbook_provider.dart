import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lookbook_models.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Lookbook Provider
// ══════════════════════════════════════════════════════════════

enum LookbookState { idle, generating, success, error }

class LookbookProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  LookbookState _state = LookbookState.idle;
  LookbookResponse? _currentLookbook;
  List<SavedLook> _savedLooks = [];
  String _errorMessage = '';
  bool _loadingSaved = false;
  Set<String> _savingIds = {}; // tracks in-progress saves

  LookbookState get state => _state;
  LookbookResponse? get lookbook => _currentLookbook;
  List<SavedLook> get savedLooks => _savedLooks;
  String get errorMessage => _errorMessage;
  bool get loadingSaved => _loadingSaved;
  bool isSaving(String lookId) => _savingIds.contains(lookId);

  // ── Generate Lookbook ─────────────────────────────────────
  Future<void> generateLookbook({
    required String destination,
    required String month,
    required String style,
    int lookCount = 3,
  }) async {
    _state = LookbookState.generating;
    _errorMessage = '';
    notifyListeners();

    try {
      final request = LookRequest(
        destination: destination,
        month: month,
        stylePreference: style,
        lookCount: lookCount,
      );
      _currentLookbook = await _api.generateLookbook(request);
      _state = LookbookState.success;
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Could not generate your lookbook. Check your connection.';
      _state = LookbookState.error;
    } finally {
      notifyListeners();
    }
  }

  // ── Save Look ─────────────────────────────────────────────
  Future<void> saveLook(LookCard look, String destination, String month) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _savingIds.contains(look.lookId)) return;

    _savingIds.add(look.lookId);
    notifyListeners();

    try {
      final saved = SavedLook(
        id: '',
        userId: user.uid,
        look: look,
        destination: destination,
        month: month,
        savedAt: DateTime.now(),
      );
      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.savedLooksCollection)
          .add(saved.toFirestore());

      // Refresh saved list
      await loadSavedLooks();
    } catch (_) {
      // silently fail, UI shows toast
    } finally {
      _savingIds.remove(look.lookId);
      notifyListeners();
    }
  }

  // ── Remove Saved Look ─────────────────────────────────────
  Future<void> removeSavedLook(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .collection(AppConstants.savedLooksCollection)
        .doc(docId)
        .delete();

    _savedLooks.removeWhere((s) => s.id == docId);
    notifyListeners();
  }

  // ── Load Saved Looks ──────────────────────────────────────
  Future<void> loadSavedLooks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _loadingSaved = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.savedLooksCollection)
          .orderBy('saved_at', descending: true)
          .get();

      _savedLooks = snapshot.docs
          .map((d) => SavedLook.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      _savedLooks = [];
    } finally {
      _loadingSaved = false;
      notifyListeners();
    }
  }

  // ── Check if look is already saved ───────────────────────
  bool isLookSaved(String lookId) {
    return _savedLooks.any((s) => s.look.lookId == lookId);
  }

  void resetState() {
    _currentLookbook = null;
    _state = LookbookState.idle;
    notifyListeners();
  }
}