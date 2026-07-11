import 'package:flutter/material.dart';
import '../services/route_service.dart';

class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> generateFullRoute({
    required int tripId,
    required List<String> categories,
    required String startTime,
    required String endTime,
    required String routeMode,
    String? startPlace,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _routeService.generateFullRoute(
        tripId: tripId,
        categories: categories,
        startTime: startTime,
        endTime: endTime,
        routeMode: routeMode,
        startPlace: startPlace,
      );
      
      _isLoading = false;
      notifyListeners(); 
      return response; 
      
    } catch (error) {
      _errorMessage = 'AI Engine failed to generate route.\n$error';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}