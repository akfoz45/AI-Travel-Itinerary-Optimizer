import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class RouteService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> generateFullRoute({
    required int tripId,
    required List<String> categories,
    required String startTime,
    required String endTime,
    required String routeMode,
    String? startPlace,
  }) async {
    final body = <String, dynamic>{
      'categories': categories,
      'start_time': startTime,
      'end_time': endTime,
      'route_mode': routeMode,
    };

    if (startPlace != null && startPlace.trim().isNotEmpty) {
      body['start_place'] = startPlace.trim();
    }

    final response = await _apiClient.post(
      '${ApiConstants.trips}$tripId/generate-full-route/',
      requiresAuth: true,
      body: body,
    );

    if (response is! Map<String, dynamic>) {
      throw Exception('Generate route response is invalid.');
    }

    return response;
  }
}