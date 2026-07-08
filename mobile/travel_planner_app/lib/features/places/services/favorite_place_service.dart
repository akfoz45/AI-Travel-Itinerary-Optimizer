import '../../../core/network/api_client.dart';

class FavoritePlaceService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final response = await _apiClient.get(
        '/api/places/favorites/',
        requiresAuth: true,
      );
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Favoriler yüklenirken bir hata oluştu: $e');
    }
  }

  Future<void> addFavorite(int placeId) async {
    try {
      await _apiClient.post(
        '/api/places/favorites/add/',
        requiresAuth: true,
        body: {'place_id': placeId},
      );
    } catch (e) {
      throw Exception('Favoriye eklenemedi: $e');
    }
  }

  Future<void> removeFavorite(int placeId) async {
    try {
      await _apiClient.delete(
        '/api/places/favorites/$placeId/',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Favoriden çıkarılamadı: $e');
    }
  }
}