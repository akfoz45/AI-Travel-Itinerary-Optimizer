import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/trip_model.dart';
import 'trip_cache_service.dart';

class TripService {
  final ApiClient _apiClient = ApiClient();
  final TripCacheService _cacheService = TripCacheService();

  Future<List<Trip>> getTrips() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.trips,
        requiresAuth: true,
      );

      if (response is! List) {
        throw Exception('Trip response is invalid.');
      }

      await _cacheService.cacheTrips(response);

      return response
          .map((tripJson) => Trip.fromJson(tripJson))
          .toList();

    } catch (e) {
      final cachedTrips = await _cacheService.getCachedTrips();
      
      if (cachedTrips != null && cachedTrips.isNotEmpty) {
        return cachedTrips; 
      }

      throw Exception('No internet connection and no offline data available.');
    }
  }

  Future<Trip> createTrip({
    required String destination,
    required String startDate,
    required String endDate,
    required List<String> preferences,
    required String hotelName,
    required double hotelLatitude,
    required double hotelLongitude,
    double? hotelRating,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.trips,
      requiresAuth: true,
      body: {
        'destination': destination,
        'start_date': startDate,
        'end_date': endDate,
        'preferences': preferences,
        'hotel': {
          'name': hotelName,
          'latitude': hotelLatitude,
          'longitude': hotelLongitude,
          'rating': hotelRating,
        },
      },
    );

    if (response is! Map<String, dynamic>) {
      throw Exception('Create trip response is invalid.');
    }

    return Trip.fromJson(response);
  }

  Future<Trip> getTripDetail(int tripId) async {
    final response = await _apiClient.get(
      '${ApiConstants.trips}$tripId/',
      requiresAuth: true,
    );

    if (response is! Map<String, dynamic>) {
      throw Exception('Trip detail response is invalid.');
    }

    return Trip.fromJson(response);
  }
  Future<void> deleteTrip(int tripId) async {
    await _apiClient.delete(
      '${ApiConstants.trips}$tripId/',
      requiresAuth: true,
    );
  }

  Future<Trip> updateTrip({
    required int tripId,
    required String destination,
    required String startDate,
    required String endDate,
    required List<String> preferences,
    required String hotelName,
    required double hotelLatitude,
    required double hotelLongitude,
    double? hotelRating,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.trips}$tripId/',
      requiresAuth: true,
      body: {
        'destination': destination,
        'start_date': startDate,
        'end_date': endDate,
        'preferences': preferences,
        'hotel': {
          'name': hotelName,
          'latitude': hotelLatitude,
          'longitude': hotelLongitude,
          'rating': hotelRating,
        },
      },
    );

    if (response is! Map<String, dynamic>) {
      throw Exception('Update trip response is invalid.');
    }

    return Trip.fromJson(response);
  }

  Future<void> reorderRouteItems(int planId, List<int> routeIds) async {
    final response = await _apiClient.put(
      '${ApiConstants.trips}day-plans/$planId/reorder/',
      requiresAuth: true,
      body: {
        'route_ids': routeIds,
      },
    );

    if (response is Map<String, dynamic> && response.containsKey('error')) {
      throw Exception(response['error']);
    }
  }

  Future<void> joinTrip(String inviteCode) async {
    final response = await _apiClient.post(
      '${ApiConstants.trips}join/',
      requiresAuth: true,
      body: {'invite_code': inviteCode},
    );
    
    if (response is Map<String, dynamic> && response.containsKey('error')) {
      throw Exception(response['error']);
    }
  }

  Future<void> leaveTrip(int tripId) async {
    final response = await _apiClient.delete(
      '/api/trips/$tripId/leave/',
      requiresAuth: true,
    );
    
    if (response is Map<String, dynamic> && response.containsKey('error')) {
      throw Exception(response['error']);
    }
  }

  Future<void> removeCollaborator(int tripId, String username) async {
    final response = await _apiClient.delete(
      '/api/trips/$tripId/collaborators/$username/',
      requiresAuth: true,
    );
    
    if (response is Map<String, dynamic> && response.containsKey('error')) {
      throw Exception(response['error']);
    }
  }
}