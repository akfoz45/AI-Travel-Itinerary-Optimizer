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
}