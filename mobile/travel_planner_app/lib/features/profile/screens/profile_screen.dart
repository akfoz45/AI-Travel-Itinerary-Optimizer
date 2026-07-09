import 'package:flutter/material.dart';
import 'account_settings_screen.dart';
import 'favorite_places_screen.dart';
import '../../trips/services/trip_service.dart';
import '../../trips/models/trip_model.dart';
import '../../auth/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TripService _tripService = TripService();
  late Future<List<Trip>> _tripsFuture;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _tripService.getTrips();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      // Hata yönetimi
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: NetworkImage(
                      'https://ui-avatars.com/api/?name=${_userProfile?['username'] ?? 'User'}&size=200&background=4F46E5&color=fff'
                      ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile?['username'] ?? 'Loading...', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _userProfile?['email'] ?? '',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54, 
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF4F46E5).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FutureBuilder<List<Trip>>(
                future: _tripsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  int totalTrips = 0;
                  int totalPlaces = 0;
                  double totalDistance = 0.0;

                  if (snapshot.hasData) {
                    final trips = snapshot.data!;
                    totalTrips = trips.length;
                    
                    for (var trip in trips) {
                      totalPlaces += trip.hotels.length;
                      
                      for (var dayPlan in trip.dayPlans) {
                        if (dayPlan.routeItems.isNotEmpty) {
                          totalPlaces += dayPlan.routeItems.length;
                        } else {
                          totalPlaces += 3; 
                        }

                        if (dayPlan.dailySummary != null && dayPlan.dailySummary!['total_distance_km'] != null) {
                          final distanceStr = dayPlan.dailySummary!['total_distance_km'].toString();
                          totalDistance += double.tryParse(distanceStr) ?? 0.0;
                        }
                      }
                    }
                  }

                  String formattedDistance = totalDistance.toStringAsFixed(1);
                  if (formattedDistance.endsWith('.0')) {
                    formattedDistance = totalDistance.toStringAsFixed(0);
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Trips', totalTrips.toString(), isDark),
                      _buildDivider(isDark),
                      _buildStatColumn('Places', totalPlaces.toString(), isDark),
                      _buildDivider(isDark),
                      _buildStatColumn('Distance (km)', formattedDistance, isDark),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personalization',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildMenuTile(
              icon: Icons.person_outline,
              title: 'Account Settings',
              subtitle: 'Change name, email, and password',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                );
                if (result == true) {
                  _loadProfile();
                }
              },
            ),
            _buildMenuTile(
              icon: Icons.tune_rounded,
              title: 'AI Preferences',
              subtitle: 'Set default travel categories',
              onTap: () {},
            ),
            _buildMenuTile(
              icon: Icons.favorite_border_rounded,
              title: 'Favorite Places',
              subtitle: 'Your saved locations',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritePlacesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}