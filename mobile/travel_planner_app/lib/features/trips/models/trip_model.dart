class Trip {
  final int tripId;
  final String destination;
  final String startDate;
  final String endDate;

  Trip({
    required this.tripId,
    required this.destination,
    required this.startDate,
    required this.endDate,
  });

  factory Trip.from(Map<String, dynamic> json) {
    return Trip(
      tripId: json['trip_id'],
      destination: json['destination'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}