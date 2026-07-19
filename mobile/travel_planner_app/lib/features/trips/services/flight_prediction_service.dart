import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart'; 
import '../../../core/storage/token_storage.dart';

class FlightPredictionService {
  Future<double> predictPrice({
    required String departureTime,
    required String arrivalTime,
    required String flightClass,
    required String stops,
    required double duration,
    required int daysLeft,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/flights/predict/'); 
    final token = await TokenStorage().getAccessToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'departure_time': departureTime,
        'arrival_time': arrivalTime,
        'class': flightClass,
        'stops': stops,
        'duration': duration,
        'days_left': daysLeft,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['estimated_price'] as num).toDouble();
    } else {
      throw Exception('Failed to get prediction. Server responded with ${response.statusCode}');
    }
  }
}