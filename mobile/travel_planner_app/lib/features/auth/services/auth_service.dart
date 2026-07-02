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
  }) async {
    await _apiClient.post(
      ApiConstants.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await _tokenStorage.getAccessToken();
    return accessToken != null;
  }
}