import 'package:flutter/material.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripService _tripService = TripService();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load trips.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshTrips,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Text('No trips found.'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshTrips,
            child: ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(trip.destination),
                    subtitle: Text(
                      '${trip.startDate} - ${trip.endDate}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Trip detail screen will be added later.
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}