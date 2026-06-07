import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_models.dart';
import '../services/travel_api_service.dart';
import '../core/constants/app_constants.dart';

enum TravelState { idle, generating, success, error }

class TravelEngineProvider with ChangeNotifier {
  final TravelApiService _api = TravelApiService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  TravelState _state = TravelState.idle;
  TripItinerary? _currentTrip;
  List<SavedTrip> _savedTrips = [];
  String _errorMessage = '';
  bool _loadingSaved = false;
  final Set<String> _savingIds = {};

  TravelState get state => _state;
  TripItinerary? get currentTrip => _currentTrip;
  List<SavedTrip> get savedTrips => _savedTrips;
  String get errorMessage => _errorMessage;
  bool get loadingSaved => _loadingSaved;
  bool isSaving(String tripId) => _savingIds.contains(tripId);

  Future<void> generateTrip({
    required String destination,
    required String month,
    required int durationDays,
    required String style,
    bool sustainable = false,
  }) async {
    _state = TravelState.generating;
    _errorMessage = '';
    notifyListeners();

    try {
      final request = TripRequest(
        destination: destination,
        month: month,
        durationDays: durationDays,
        stylePreference: style,
        sustainable: sustainable,
      );
      _currentTrip = await _api.generateTrip(request);
      _state = TravelState.success;
    } catch (e) {
      _errorMessage = 'Could not generate your trip. Check your connection.';
      _state = TravelState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveTrip(TripItinerary itinerary) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _savingIds.contains(itinerary.tripId)) return;
    _savingIds.add(itinerary.tripId);
    notifyListeners();
    try {
      final saved = SavedTrip(
        id: '', userId: user.uid,
        itinerary: itinerary, savedAt: DateTime.now(),
      );
      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.tripsCollection)
          .add(saved.toFirestore());
      await loadSavedTrips();
    } catch (_) {
    } finally {
      _savingIds.remove(itinerary.tripId);
      notifyListeners();
    }
  }

  Future<void> removeSavedTrip(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .collection(AppConstants.tripsCollection)
        .doc(docId)
        .delete();
    _savedTrips.removeWhere((t) => t.id == docId);
    notifyListeners();
  }

  Future<void> loadSavedTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _loadingSaved = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.tripsCollection)
          .orderBy('saved_at', descending: true)
          .get();
      _savedTrips = snap.docs
          .map((d) => SavedTrip.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      _savedTrips = [];
    } finally {
      _loadingSaved = false;
      notifyListeners();
    }
  }

  bool isTripSaved(String tripId) =>
      _savedTrips.any((t) => t.itinerary.tripId == tripId);

  void resetState() {
    _currentTrip = null;
    _state = TravelState.idle;
    notifyListeners();
  }
}