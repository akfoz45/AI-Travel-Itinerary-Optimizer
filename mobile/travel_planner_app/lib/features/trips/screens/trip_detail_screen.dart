import 'package:flutter/material.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../../routes/screens/generate_full_route_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripService _tripService = TripService();

  late Future<Trip> _tripFuture;

  @override
  void initState() {
    super.initState();
    _tripFuture = _tripService.getTripDetail(widget.tripId);
  }

  Future<void> _refreshTrip() async {
    setState(() {
      _tripFuture = _tripService.getTripDetail(widget.tripId);
    });
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String subtitle,
    IconData icon = Icons.info_outline,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildTripDetail(Trip trip) {
    return RefreshIndicator(
      onRefresh: _refreshTrip,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            trip.destination,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${trip.startDate} - ${trip.endDate}',
            style: const TextStyle(fontSize: 16),
          ),

          _sectionTitle('Preferences'),

          if (trip.preferences.isEmpty)
            const Text('No preferences found.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.preferences
                  .map(
                    (preference) => Chip(
                      label: Text(preference.preference),
                    ),
                  )
                  .toList(),
            ),

          _sectionTitle('Hotel'),

          if (trip.hotels.isEmpty)
            const Text('No hotel found.')
          else
            ...trip.hotels.map(
              (hotel) => _infoCard(
                icon: Icons.hotel,
                title: hotel.name,
                subtitle:
                    'Lat: ${hotel.latitude}, Lng: ${hotel.longitude}\nRating: ${hotel.rating ?? "-"}',
              ),
            ),

          _sectionTitle('Day Plans'),

          if (trip.dayPlans.isEmpty)
            const Text('No route generated yet.')
          else
            ...trip.dayPlans.map(
              (dayPlan) => Card(
                child: ExpansionTile(
                  title: Text('Day ${dayPlan.dayNumber}'),
                  subtitle: Text(dayPlan.date),
                  children: [
                    if (dayPlan.dailySummary != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Places: ${dayPlan.dailySummary?['number_of_places'] ?? "-"}\n'
                            'Distance: ${dayPlan.dailySummary?['total_distance_km'] ?? "-"} km\n'
                            'Weather: ${dayPlan.dailySummary?['weather_note'] ?? "No weather note"}',
                          ),
                        ),
                      ),

                    if (dayPlan.routeItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No route items.'),
                      )
                    else
                      ...dayPlan.routeItems.map(
                        (routeItem) => ListTile(
                          leading: CircleAvatar(
                            child: Text(routeItem.visitOrder.toString()),
                          ),
                          title: Text(
                            routeItem.placeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Category: ${routeItem.category ?? "-"}\n'
                            'Source: ${routeItem.source ?? "-"}\n'
                            'Time: ${routeItem.arrivalTime ?? "-"} - ${routeItem.departureTime ?? "-"}\n'
                            'Score: ${routeItem.recommendationScore ?? "-"}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Detail'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenerateFullRouteScreen(
                tripId: widget.tripId,
              ),
            ),
          );

          if (!mounted) return;

          await _refreshTrip();
        },
        icon: const Icon(Icons.route),
        label: const Text('Route'),
      ),
      body: FutureBuilder<Trip>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load trip detail.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final trip = snapshot.data;

          if (trip == null) {
            return const Center(
              child: Text('Trip not found.'),
            );
          }

          return _buildTripDetail(trip);
        },
      ),
    );
  }
}