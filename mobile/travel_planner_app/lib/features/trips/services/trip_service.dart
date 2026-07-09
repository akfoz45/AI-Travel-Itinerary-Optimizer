import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/trip_model.dart';

class TripService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Trip>> getTrips() async {
    final response = await _apiClient.get(
      ApiConstants.trips,
      requiresAuth: true,
    );

    if (response is! List) {
      throw Exception('Trip response is invalid.');
    }

    return response
        .map((tripJson) => Trip.fromJson(tripJson))
        .toList();
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
}