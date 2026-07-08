import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/settings_screen.dart';

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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageUrl = 'https://picsum.photos/seed/${trip.tripId + 10}/600/300';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF4F46E5).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
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
                Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        trip.destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            trip.isPinned = !trip.isPinned;
                          });
                          // TODO: İleride AuthService veya TripService üzerinden backend'e bu değişikliği bildiren bir PUT isteği atabiliriz.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(trip.isPinned ? 'Trip pinned to top' : 'Trip unpinned'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: trip.isPinned 
                                ? const Color(0xFF4F46E5) 
                                : Colors.white.withValues(alpha: 0.2), 
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            trip.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, 
                            color: Colors.white, 
                            size: 20
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${trip.startDate}  —  ${trip.endDate}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (trip.preferences.isNotEmpty)
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: trip.preferences.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    trip.preferences[index].preference,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        const Text('No preferences selected', style: TextStyle(color: Colors.grey, fontSize: 13)),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          _buildModernStatusBadge(
                            icon: hasHotel ? Icons.hotel_rounded : Icons.hotel_outlined,
                            label: hasHotel ? 'Hotel' : 'No Hotel',
                            isActive: hasHotel,
                            activeColor: const Color(0xFF4F46E5),
                            isDark: isDark, 
                          ),
                          const SizedBox(width: 12),
                          _buildModernStatusBadge(
                            icon: hasRoute ? Icons.alt_route_rounded : Icons.route_outlined,
                            label: hasRoute ? 'Route Ready' : 'No Route',
                            isActive: hasRoute,
                            activeColor: const Color(0xFF10B981),
                            isDark: isDark,
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

  Widget _buildModernStatusBadge({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? activeColor.withValues(alpha: 0.1) 
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? activeColor : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : const Color(0xFF94A3B8),
              ),
            ),
          ],
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
    trips.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0; 
    });

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 28),
            onSelected: (String value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black54),
                      SizedBox(width: 10),
                      Text('Profil'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.black54),
                      SizedBox(width: 10),
                      Text('Ayarlar'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
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