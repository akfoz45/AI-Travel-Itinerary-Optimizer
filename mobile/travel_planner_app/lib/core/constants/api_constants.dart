class ApiConstants {
    //static const String baseUrl = 'http://127.0.0.1:8000';
    //static const String baseUrl = 'http://192.168.1.111:8000';
    //static const String baseUrl = 'http://10.222.121.242:8000';
    static const String baseUrl = 'http://10.0.2.2:8000';

    static const String wsBaseUrl = 'ws://127.0.0.1:8000';

    static const String register = "/api/auth/register/";
    static const String login = "/api/auth/token/";
    static const String refreshToken = "/api/auth/token/refresh/";

    static const String trips = "/api/trips/";
    static const String places = "/api/places/";
}