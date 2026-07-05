import 'package:flutter/material.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripService _tripService = TripService();
  final AuthService _authService = AuthService();

  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _tripService.getTrips();
  }

  Future<void> _refreshTrips() async {
    setState(() {
      _tripsFuture = _tripService.getTrips();
    });
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget _buildTripCard(Trip trip) {
    final hasHotel = trip.hotels.isNotEmpty;
    final hasRoute = trip.dayPlans.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailScreen(
                tripId: trip.tripId,
              ),
            ),
          );

          if (!mounted) return;
          await _refreshTrips();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.destination,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),

              const SizedBox(height: 8),

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
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (trip.preferences.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: trip.preferences.map((preference) {
                    return Chip(
                      label: Text(preference.preference),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                )
              else
                const Text('No preferences.'),

              const SizedBox(height: 12),

              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasHotel ? Icons.hotel : Icons.hotel_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasHotel ? 'Hotel added' : 'No hotel',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRoute ? Icons.route : Icons.route_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasRoute ? 'Route generated' : 'No route yet',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: ListView(
        children: const [
          SizedBox(height: 120),

          Icon(
            Icons.travel_explore,
            size: 72,
          ),

          SizedBox(height: 16),

          Center(
            child: Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 8),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create your first trip and start generating optimized travel routes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
          ),

          SizedBox(height: 12),

          Center(
            child: Text(
              'Tap the + button to begin.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: ListView(
        children: [
          const SizedBox(height: 160),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load trips.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(List<Trip> trips) {
    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Future<void> _openCreateTripScreen() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTripScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _refreshTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTripScreen,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error!);
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return _buildEmptyState();
          }

          return _buildTripList(trips);
        },
      ),
    );
  }
}