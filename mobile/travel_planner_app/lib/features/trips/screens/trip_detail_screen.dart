import 'package:flutter/material.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../../routes/screens/generate_full_route_screen.dart';
import 'edit_trip_screen.dart';

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

  Future<void> _openGenerateRouteScreen(Trip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateFullRouteScreen(
          tripId: widget.tripId,
          tripPreferences: trip.preferences
              .map((preference) => preference.preference)
              .toList(),
        ),
      ),
    );

    if (!mounted) return;

    await _refreshTrip();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Trip trip) {
    final hasHotel = trip.hotels.isNotEmpty;
    final hasRoute = trip.dayPlans.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.travel_explore,
              size: 32,
            ),

            const SizedBox(height: 12),

            Text(
              trip.destination,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.date_range,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${trip.startDate} - ${trip.endDate}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _statusChip(
                  icon: hasHotel ? Icons.hotel : Icons.hotel_outlined,
                  label: hasHotel ? 'Hotel added' : 'No hotel',
                ),
                _statusChip(
                  icon: hasRoute ? Icons.route : Icons.route_outlined,
                  label: hasRoute ? 'Route generated' : 'No route yet',
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openEditTripScreen(trip),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Trip'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGenerateRouteScreen(trip),
                icon: const Icon(Icons.route),
                label: const Text('Generate Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E6EF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(Trip trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: trip.preferences.isEmpty
            ? const Text('No preferences found.')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: trip.preferences.map((preference) {
                  return Chip(
                    label: Text(preference.preference),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildHotelCard(Trip trip) {
    if (trip.hotels.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.hotel_outlined),
          title: Text('No hotel found'),
          subtitle: Text(
            'This trip does not have a hotel. Route can still be generated with a start place.',
          ),
        ),
      );
    }

    return Column(
      children: trip.hotels.map((hotel) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.hotel),
            title: Text(
              hotel.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Latitude: ${hotel.latitude}\n'
              'Longitude: ${hotel.longitude}\n'
              'Rating: ${hotel.rating ?? "-"}',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRouteStatusCard(Trip trip) {
    final hasRoute = trip.dayPlans.isNotEmpty;

    return Card(
      child: ListTile(
        leading: Icon(
          hasRoute ? Icons.check_circle_outline : Icons.route_outlined,
        ),
        title: Text(
          hasRoute ? 'Route generated' : 'No route generated yet',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          hasRoute
              ? '${trip.dayPlans.length} day plan(s) available.'
              : 'Use the Route button to generate a route for this trip.',
        ),
      ),
    );
  }

  Widget _buildDayPlans(Trip trip) {
    if (trip.dayPlans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No day plans available.'),
        ),
      );
    }

    return Column(
      children: trip.dayPlans.map((dayPlan) {
        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              child: Text(dayPlan.dayNumber.toString()),
            ),
            title: Text(
              'Day ${dayPlan.dayNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(dayPlan.date),
            children: [
              if (dayPlan.dailySummary != null)
                _buildDailySummary(dayPlan.dailySummary!),

              if (dayPlan.routeItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No route items.'),
                  ),
                )
              else
                ...dayPlan.routeItems.map((routeItem) {
                  return ListTile(
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
                  );
                }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailySummary(Map<String, dynamic> dailySummary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE0E6EF),
          ),
        ),
        child: Text(
          'Places: ${dailySummary['number_of_places'] ?? "-"}\n'
          'Distance: ${dailySummary['total_distance_km'] ?? "-"} km\n'
          'Travel time: ${dailySummary['total_travel_time_minutes'] ?? "-"} min\n'
          'Visit duration: ${dailySummary['total_visit_duration_minutes'] ?? "-"} min\n'
          'Weather: ${dailySummary['weather_note'] ?? "No weather note"}',
        ),
      ),
    );
  }

  Widget _buildTripDetail(Trip trip) {
    return RefreshIndicator(
      onRefresh: _refreshTrip,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(trip),

          _sectionTitle('Preferences'),
          _buildPreferencesCard(trip),

          _sectionTitle('Hotel'),
          _buildHotelCard(trip),

          _sectionTitle('Route Status'),
          _buildRouteStatusCard(trip),

          _sectionTitle('Day Plans'),
          _buildDayPlans(trip),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return RefreshIndicator(
      onRefresh: _refreshTrip,
      child: ListView(
        children: [
          const SizedBox(height: 160),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load trip detail.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return RefreshIndicator(
      onRefresh: _refreshTrip,
      child: ListView(
        children: const [
          SizedBox(height: 160),
          Center(
            child: Text('Trip not found.'),
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
        actions: [
          IconButton(
            onPressed: _confirmDeleteTrip,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Trip',
          ),
        ],
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
            return _buildErrorState(snapshot.error!);
          }

          final trip = snapshot.data;

          if (trip == null) {
            return _buildNotFoundState();
          }

          return _buildTripDetail(trip);
        },
      ),
    );
  }

  Future<void> _confirmDeleteTrip() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: const Text(
            'Are you sure you want to delete this trip? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _tripService.deleteTrip(widget.tripId);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete trip: $error'),
        ),
      );
    }
  }

  Future<void> _openEditTripScreen(Trip trip) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTripScreen(
          trip: trip,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _refreshTrip();
    }
  }
}