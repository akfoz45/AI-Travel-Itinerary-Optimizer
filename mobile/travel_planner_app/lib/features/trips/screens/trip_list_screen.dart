import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4F46E5), 
                        Color(0xFF0EA5E9), 
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          trip.destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '${trip.startDate} - ${trip.endDate}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (trip.preferences.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: trip.preferences.map((preference) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD), 
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                preference.preference,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E88E5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        const Text('No preferences.', style: TextStyle(color: Colors.grey)),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 12),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasHotel ? Icons.hotel : Icons.hotel_outlined,
                                size: 20,
                                color: hasHotel ? const Color(0xFF1E88E5) : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasHotel ? 'Hotel added' : 'No hotel',
                                style: TextStyle(
                                  color: hasHotel ? Colors.black87 : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 20, color: const Color(0xFFEEEEEE)),
                          Row(
                            children: [
                              Icon(
                                hasRoute ? Icons.route : Icons.route_outlined,
                                size: 20,
                                color: hasRoute ? const Color(0xFF43A047) : Colors.grey, // Yeşil vurgu
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasRoute ? 'Route ready' : 'No route',
                                style: TextStyle(
                                  color: hasRoute ? Colors.black87 : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4, 
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 220, 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7, 
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD), 
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flight_takeoff, 
                  size: 80,
                  color: Color(0xFF1E88E5), 
                ),
              ),
              const SizedBox(height: 32),
              
              // Başlık
              const Text(
                'No Trips Planned Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Create your first trip and let our AI generate the perfect, weather-aware daily itinerary for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5, 
                ),
              ),
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                onPressed: _openCreateTripScreen,
                icon: const Icon(Icons.add_location_alt),
                label: const Text(
                  'Plan Your First Trip', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            return _buildShimmerLoading(); 
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