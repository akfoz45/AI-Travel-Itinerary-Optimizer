import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {
        'username': username,
        'password': password,
      },
    );

    final accessToken = response['access'];
    final refreshToken = response['refresh'];

    if (accessToken == null || refreshToken == null) {
      throw Exception('Token response is invalid.');
    }

    await _tokenStorage.saveToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    await _apiClient.post(
      ApiConstants.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      },
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await _tokenStorage.getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.put(
        '/api/auth/change-password/', 
        requiresAuth: true,
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      return true;
      
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiClient.get(
        '/api/auth/profile/', 
        requiresAuth: true,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<void> updateProfile({
    required String username, 
    required String email
  }) async {
    try {
      await _apiClient.put(
        '/api/auth/profile/', 
        requiresAuth: true,
        body: {
          'username': username, 
          'email': email,
        },
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}