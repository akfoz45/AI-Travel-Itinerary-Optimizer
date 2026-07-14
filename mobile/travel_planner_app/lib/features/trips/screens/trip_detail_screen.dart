import 'package:flutter/material.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../../routes/screens/generate_full_route_screen.dart';
import 'edit_trip_screen.dart';
import '../../places/widgets/favorite_button.dart'; 
import 'day_map_screen.dart';
import '../services/pdf_export_service.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter/services.dart';

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

  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _tripFuture = _tripService.getTripDetail(widget.tripId);
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final wsUrl = Uri.parse('${ApiConstants.wsBaseUrl}/ws/trips/${widget.tripId}/');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        
        if (data['action'] == 'route_updated') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A collaborator updated the trip! Refreshing...'),
                backgroundColor: Colors.blueAccent,
                duration: Duration(seconds: 2),
              ),
            );
            _refreshTrip(); 
          }
        }
      },
      onError: (error) {
        debugPrint('WebSocket Error: $error');
      },
    );
  }

  Future<void> _refreshTrip() async {
    setState(() {
      _tripFuture = _tripService.getTripDetail(widget.tripId);
    });
  }

  @override
  void dispose() {
    _channel?.sink.close(); 
    super.dispose();
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
                    if (dayPlan.dailySummary?['weather_note'] != null)
                      _buildWeatherBadge(dayPlan.dailySummary!['weather_note'], isDark),
                  ],
                ),
              ),
              children: [
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
                      _buildSummaryItem(Icons.place, '${dayPlan.routeItems.length} Places'),
                      
                      _buildSummaryItem(Icons.map, '${dayPlan.dailySummary?['total_distance_km'] ?? 0} km'),
                      _buildSummaryItem(
                        Icons.timer, 
                        '${dayPlan.dailySummary?['total_travel_time_minutes'] ?? dayPlan.dailySummary?['total_duration'] ?? dayPlan.dailySummary?['total_time'] ?? dayPlan.dailySummary?['travel_time'] ?? 0} min'
                      ),
                    ],
                  ),
                ),

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
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false, 
                    onReorderItem: (oldIndex, newIndex) async {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      
                      setState(() {
                        final item = dayPlan.routeItems.removeAt(oldIndex);
                        dayPlan.routeItems.insert(newIndex, item);
                      });

                      try {
                        final routeIds = dayPlan.routeItems.map((e) => e.routeId).toList();
                        await _tripService.reorderRouteItems(dayPlan.planId, routeIds);
                        _refreshTrip();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to reorder: $e')),
                          );
                          _refreshTrip();
                        }
                      }
                    },
                    children: dayPlan.routeItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final routeItem = entry.value;

                      return ListTile(
                        key: ValueKey(routeItem.routeId),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          child: Text(
                            (index + 1).toString(), 
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FavoriteButton(placeId: routeItem.placeId),
                            const SizedBox(width: 8),
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(Icons.drag_indicator_rounded, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
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
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                final trip = await _tripFuture;
                if (!context.mounted) return;
                
                _showInviteDialog(trip);
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
              tooltip: 'Invite Friends',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                final trip = await _tripFuture;
                if (!context.mounted) return;
                _showCollaboratorsDialog(trip);
              },
              icon: const Icon(Icons.group_rounded, color: Colors.white, size: 20),
              tooltip: 'View People',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                final trip = await _tripFuture;
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF...')),
                );
                
                await PdfExportService().generateAndShareTripPdf(trip);
              },
              icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
              tooltip: 'Export & Share',
            ),
          ),
          
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _confirmDeleteTrip,
              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
              tooltip: 'Delete Trip',
            ),
          ),
        ],
      ),
      body: FutureBuilder<Trip>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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

  void _showInviteDialog(Trip trip) {
    String selectedRole = 'editor'; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = const Color(0xFF4F46E5);
            final activeCode = selectedRole == 'editor' ? trip.inviteCode : trip.viewerInviteCode;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.share_rounded, color: primaryColor, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Share Your Trip',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invite friends to view or collaborate.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedRole = 'editor'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedRole == 'editor' ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedRole == 'editor' ? primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  width: selectedRole == 'editor' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.edit_rounded, color: selectedRole == 'editor' ? primaryColor : Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Editor', 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: selectedRole == 'editor' ? primaryColor : Colors.grey
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedRole = 'viewer'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedRole == 'viewer' ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedRole == 'viewer' ? primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  width: selectedRole == 'viewer' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.visibility_rounded, color: selectedRole == 'viewer' ? primaryColor : Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Viewer', 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: selectedRole == 'viewer' ? primaryColor : Colors.grey
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- DAVET KODU GÖSTERİMİ ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, size: 18, color: primaryColor),
                          const SizedBox(width: 10),
                          // YENİ KISIM: Yatay kaydırma ve tek satır sabitlemesi
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal, // Sağa-sola kaydırma
                              child: SelectableText(
                                activeCode,
                                maxLines: 1, // Alt satıra taşmasını engeller
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: activeCode));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${selectedRole.toUpperCase()} code copied to clipboard!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, color: Colors.white),
                        label: const Text(
                          'Copy Link', 
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showCollaboratorsDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: Color(0xFF4F46E5)),
              const SizedBox(width: 10),
              Text('People', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    child: const Icon(Icons.star_rounded, color: Color(0xFF4F46E5)),
                  ),
                  title: Text(trip.ownerUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Owner'),
                ),
                if (trip.collaborators.isNotEmpty) const Divider(),
                
                ...trip.collaborators.map((collab) {
                  final isEditor = collab.role == 'editor';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: Icon(
                        isEditor ? Icons.edit_rounded : Icons.visibility_rounded,
                        color: isEditor ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(collab.username, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(isEditor ? 'Editor' : 'Viewer'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 20),
                      tooltip: 'Remove User',
                      onPressed: () async {
                        try {
                          await _tripService.removeCollaborator(trip.tripId, collab.username);
                          if (!context.mounted) return;
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${collab.username} removed!'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  );
                }),
                
                if (trip.collaborators.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No one has joined this trip yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Leave Trip?'),
                    content: const Text('Are you sure you want to leave this trip? You will need an invite code to join again.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Leave', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await _tripService.leaveTrip(trip.tripId);
                    if (!context.mounted) return;
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You left the trip.'), backgroundColor: Colors.orange),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Leave Trip', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}