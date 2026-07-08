import 'package:flutter/material.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../../routes/screens/generate_full_route_screen.dart';
import 'edit_trip_screen.dart';
import '../../places/widgets/favorite_button.dart'; 
import 'day_map_screen.dart';

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

  Future<void> _openGenerateRouteScreen(
    Trip trip, {
    bool skipExistingRouteWarning = false,
  }) async {
    if (!skipExistingRouteWarning && trip.dayPlans.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Regenerate Route'),
            content: const Text(
              'This trip already has a route. Generating a new route will replace the existing route. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      if (shouldContinue != true) return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateFullRouteScreen(
          tripId: trip.tripId,
          tripPreferences: trip.preferences.map((p) => p.preference).toList(),
          hasHotel: trip.hotels.isNotEmpty,
        ),
      ),
    );

    if (!mounted) return;
    await _refreshTrip();
  }

  Widget _buildHeader(Trip trip, bool isDark) {
    final imageUrl = 'https://picsum.photos/seed/${trip.tripId + 20}/800/400';

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent, 
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.destination,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF4F46E5), size: 20),
                const SizedBox(width: 8),
                Text(
                  '${trip.startDate}  —  ${trip.endDate}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Trip trip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openEditTripScreen(trip),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Trip'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openGenerateRouteScreen(trip),
              icon: const Icon(Icons.route, size: 18),
              label: const Text('Route'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPreferences(Trip trip, bool isDark) {
    if (trip.preferences.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('No preferences found.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: trip.preferences.map((preference) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
            ),
            child: Text(
              preference.preference,
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayPlans(Trip trip, bool isDark) {
    if (trip.dayPlans.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.route_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No route generated yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the Route button to let our AI create a perfect daily travel plan for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: trip.dayPlans.map((dayPlan) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'D${dayPlan.dayNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
              ),
              title: Text(
                'Day ${dayPlan.dayNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Text(dayPlan.date, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 12),
                    if (dayPlan.dailySummary != null)
                      _buildWeatherBadge(dayPlan.dailySummary!['weather_note'], isDark),
                  ],
                ),
              ),
              children: [
                if (dayPlan.dailySummary != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(Icons.place, '${dayPlan.dailySummary!['number_of_places'] ?? 0} Places'),
                        _buildSummaryItem(Icons.map, '${dayPlan.dailySummary!['total_distance_km'] ?? 0} km'),
                        _buildSummaryItem(Icons.timer, '${dayPlan.dailySummary!['total_travel_time_minutes'] ?? 0} min'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DayMapScreen(
                                dayPlan: dayPlan,
                                destination: trip.destination,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('View on Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        child: Text(
                          routeItem.visitOrder.toString(),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      title: Text(
                        routeItem.placeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${routeItem.category ?? "General"} • ${routeItem.arrivalTime ?? "TBD"}'),
                          if (routeItem.recommendationScore != null)
                            Text('Score: ${routeItem.recommendationScore}'),
                        ],
                      ),
                      trailing: FavoriteButton(
                        placeId: routeItem.placeId,
                      ),
                    );
                  }),
                const SizedBox(height: 8),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
      ],
    );
  }

  Widget _buildWeatherBadge(String? weatherNote, bool isDark) {
    if (weatherNote == null || weatherNote.isEmpty) return const SizedBox.shrink();

    IconData icon = Icons.thermostat;
    Color color = Colors.grey;
    String label = 'Normal';

    final lowerNote = weatherNote.toLowerCase();

    if (lowerNote.contains('rain') || lowerNote.contains('shower')) {
      icon = Icons.water_drop_rounded;
      color = Colors.blue;
      label = 'Rainy';
    } else if (lowerNote.contains('sun') || lowerNote.contains('clear')) {
      icon = Icons.wb_sunny_rounded;
      color = Colors.orange;
      label = 'Sunny';
    } else if (lowerNote.contains('cloud') || lowerNote.contains('overcast')) {
      icon = Icons.cloud_rounded;
      color = Colors.blueGrey;
      label = 'Cloudy';
    } else if (lowerNote.contains('snow')) {
      icon = Icons.ac_unit_rounded;
      color = Colors.lightBlueAccent;
      label = 'Snowy';
    } else if (lowerNote.contains('thunder') || lowerNote.contains('storm')) {
      icon = Icons.flash_on_rounded;
      color = Colors.deepPurple;
      label = 'Storm';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _confirmDeleteTrip,
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Delete Trip',
            ),
          ),
        ],
      ),
      body: FutureBuilder<Trip>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error!);
          }

          final trip = snapshot.data;

          if (trip == null) {
            return _buildNotFoundState();
          }

          return RefreshIndicator(
            onRefresh: _refreshTrip,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(trip, isDark),
                  const SizedBox(height: 24),
                  
                  _buildActionButtons(trip),
                  
                  _sectionTitle('Preferences', isDark),
                  _buildPreferences(trip, isDark),
                  
                  _sectionTitle('Itinerary', isDark),
                  _buildDayPlans(trip, isDark),
                ],
              ),
            ),
          );
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTripScreen(
          trip: trip,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map && result['updated'] == true) {
      await _refreshTrip();

      if (!mounted) return;

      if (result['shouldAskRegenerate'] == true) {
        await _askRegenerateAfterEdit();
      }
    }
  }

  Future<void> _askRegenerateAfterEdit() async {
    final shouldRegenerate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Trip Updated'),
          content: const Text(
            'This trip already has a route. Since trip details were updated, you may want to regenerate the route.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Regenerate'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (shouldRegenerate != true) return;

    final refreshedTrip = await _tripService.getTripDetail(widget.tripId);

    if (!mounted) return;

    await _openGenerateRouteScreen(
      refreshedTrip,
      skipExistingRouteWarning: true,
    );
  }
}