import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class FavoritePlaceService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getFavorites() async {
    final response = await _apiClient.get(
      '${ApiConstants.places}favorites/',
      requiresAuth: true,
    );

    if (response is! List) {
      throw Exception('Favorite places response is invalid.');
    }

    return response;
  }

  Future<void> addFavorite(int placeId) async {
    await _apiClient.post(
      '${ApiConstants.places}favorites/add/',
      requiresAuth: true,
      body: {
        'place_id': placeId,
      },
    );
  }

  Future<void> removeFavorite(int placeId) async {
    await _apiClient.delete(
      '${ApiConstants.places}favorites/$placeId/',
      requiresAuth: true,
    );
  }
}