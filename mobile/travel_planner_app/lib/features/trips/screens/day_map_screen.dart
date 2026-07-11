import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DayMapScreen extends StatelessWidget {
  final DayPlan dayPlan;
  final String destination;

  const DayMapScreen({
    super.key,
    required this.dayPlan,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final validItems = dayPlan.routeItems
        .where((item) => item.latitude != 0.0 && item.longitude != 0.0)
        .toList();
    
    if (validItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Day ${dayPlan.dayNumber} Map')),
        body: const Center(child: Text('No location data available for this route.')),
      );
    }

    final points = validItems.map((item) => LatLng(item.latitude, item.longitude)).toList();
    
    final initialCenter = points.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${dayPlan.dayNumber} - $destination'),
        centerTitle: true,
      ),
      body: FlutterMap(
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
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: const Color(0xFF4F46E5),
                strokeWidth: 4.0, 
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