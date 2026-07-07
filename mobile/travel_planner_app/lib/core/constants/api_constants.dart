class ApiConstants {
    static const String baseUrl = 'http://127.0.0.1:8000';
    // static const String baseUrl = 'http://172.17.96.1:8000';

    static const String register = "/api/auth/register/";
    static const String login = "/api/auth/token/";
    static const String refreshToken = "/api/auth/token/refresh/";

    static const String trips = "/api/trips/";
    static const String places = "/api/places/";
}