import 'package:flutter/material.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> createTrip({
    required String destination,
    required String startDate,
    required String endDate,
    required List<String> preferences,
    required String hotelName,
    required double hotelLatitude,
    required double hotelLongitude,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _tripService.createTrip(
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        preferences: preferences,
        hotelName: hotelName,
        hotelLatitude: hotelLatitude,
        hotelLongitude: hotelLongitude,
      );
      _setLoading(false);
      return true; 
    } catch (error) {
      _errorMessage = 'Failed to create trip.\n$error';
      _setLoading(false);
      return false; 
    }
  }
}