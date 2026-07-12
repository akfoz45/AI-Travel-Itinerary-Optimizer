import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';

class TripCacheService {
  static const String _tripsKey = 'offline_cached_trips';

  Future<void> cacheTrips(List<dynamic> tripsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tripsKey, jsonEncode(tripsJson));
  }

  Future<List<Trip>?> getCachedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_tripsKey);
    
    if (cachedData != null) {
      final List<dynamic> decodedData = jsonDecode(cachedData);
      return decodedData.map((json) => Trip.fromJson(json)).toList();
    }
    
    return null;
  }
}