import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/trip_model.dart';

class DayMapScreen extends StatefulWidget {
  final DayPlan dayPlan;
  final String destination;

  const DayMapScreen({
    super.key,
    required this.dayPlan,
    required this.destination,
  });

  @override
  State<DayMapScreen> createState() => _DayMapScreenState();
}

class _DayMapScreenState extends State<DayMapScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _fetchRealRoute();
  }

  Future<void> _fetchRealRoute() async {
    final validItems = widget.dayPlan.routeItems
        .where((item) => item.latitude != 0.0 && item.longitude != 0.0)
        .toList();

    if (validItems.length < 2) {
      if (mounted) {
        setState(() {
          _routePoints = validItems.map((item) => LatLng(item.latitude, item.longitude)).toList();
          _isLoadingRoute = false;
        });
      }
      return;
    }

    final coordsString = validItems
        .map((item) => '${item.longitude},${item.latitude}')
        .join(';');

    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$coordsString?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;

        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final List<LatLng> polylinePoints = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          if (mounted) {
            setState(() {
              _routePoints = polylinePoints;
              _isLoadingRoute = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('OSRM Routing error: $e');
    }

    if (mounted) {
      setState(() {
        _routePoints = validItems.map((item) => LatLng(item.latitude, item.longitude)).toList();
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final validItems = widget.dayPlan.routeItems
        .where((item) => item.latitude != 0.0 && item.longitude != 0.0)
        .toList();

    if (validItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Day ${widget.dayPlan.dayNumber} Map')),
        body: const Center(child: Text('No location data available for this route.')),
      );
    }

    final initialCenter = LatLng(validItems.first.latitude, validItems.first.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.dayPlan.dayNumber} - ${widget.destination}'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png?api_key=${dotenv.env['STADIA_MAPS_API_KEY']}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.travel_planner_app',
              ),
              
              if (!_isLoadingRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF4F46E5),
                      strokeWidth: 5.0, 
                    ),
                  ],
                ),
                
              MarkerLayer(
                markers: validItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Marker(
                    point: LatLng(item.latitude, item.longitude),
                    width: 40,
                    height: 40,
                    child: _buildMarkerWidget(index + 1),
                  );
                }).toList(),
              ),
            ],
          ),
          
          if (_isLoadingRoute)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generating street route...', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkerWidget(int order) {
    return RepaintBoundary(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF4F46E5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Center(
          child: Text(
            order.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}