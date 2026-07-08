class Trip {
  final int tripId;
  final String destination;
  final String startDate;
  final String endDate;
  bool isPinned;
  final List<TripPreference> preferences;
  final List<Hotel> hotels;
  final List<DayPlan> dayPlans;

  Trip({
    required this.tripId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.isPinned = false,
    this.preferences = const [],
    this.hotels = const [],
    this.dayPlans = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['trip_id'],
      destination: json['destination'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isPinned: json['is_pinned'] ?? false,
      preferences: (json['preferences'] as List? ?? [])
          .map((item) => TripPreference.fromJson(item))
          .toList(),
      hotels: (json['hotels'] as List? ?? [])
          .map((item) => Hotel.fromJson(item))
          .toList(),
      dayPlans: (json['day_plans'] as List? ?? [])
          .map((item) => DayPlan.fromJson(item))
          .toList(),
    );
  }
}

class TripPreference {
  final int preferenceId;
  final String preference;

  TripPreference({
    required this.preferenceId,
    required this.preference,
  });

  factory TripPreference.fromJson(Map<String, dynamic> json) {
    return TripPreference(
      preferenceId: json['preference_id'],
      preference: json['preference'],
    );
  }
}

class Hotel {
  final int hotelId;
  final String name;
  final double latitude;
  final double longitude;
  final double? rating;

  Hotel({
    required this.hotelId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.rating,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      hotelId: json['hotel_id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: json['rating'] == null ? null : (json['rating'] as num).toDouble(),
    );
  }
}

class DayPlan {
  final int planId;
  final int dayNumber;
  final String date;
  final Map<String, dynamic>? dailySummary;
  final List<RouteItem> routeItems;

  DayPlan({
    required this.planId,
    required this.dayNumber,
    required this.date,
    this.dailySummary,
    this.routeItems = const [],
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      planId: json['plan_id'],
      dayNumber: json['day_number'],
      date: json['date'],
      dailySummary: json['daily_summary'],
      routeItems: (json['route_items'] as List? ?? [])
          .map((item) => RouteItem.fromJson(item))
          .toList(),
    );
  }
}

class RouteItem {
  final int routeId;
  final int visitOrder;
  final String placeName;
  final String? category;
  final String? source;
  final double? recommendationScore;
  final String? arrivalTime;
  final String? departureTime;

  RouteItem({
    required this.routeId,
    required this.visitOrder,
    required this.placeName,
    this.category,
    this.source,
    this.recommendationScore,
    this.arrivalTime,
    this.departureTime,
  });

  factory RouteItem.fromJson(Map<String, dynamic> json) {
    return RouteItem(
      routeId: json['route_id'],
      visitOrder: json['visit_order'],
      placeName: json['place_name'],
      category: json['category'],
      source: json['source'],
      recommendationScore: json['recommendation_score'] == null
          ? null
          : (json['recommendation_score'] as num).toDouble(),
      arrivalTime: json['arrival_time'],
      departureTime: json['departure_time'],
    );
  }
}