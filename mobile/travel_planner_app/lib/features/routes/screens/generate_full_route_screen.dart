import 'package:flutter/material.dart';

import '../services/route_service.dart';

class GenerateFullRouteScreen extends StatefulWidget {
  final int tripId;

  const GenerateFullRouteScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<GenerateFullRouteScreen> createState() =>
      _GenerateFullRouteScreenState();
}

class _GenerateFullRouteScreenState extends State<GenerateFullRouteScreen> {
  final RouteService _routeService = RouteService();

  final TextEditingController _categoriesController =
      TextEditingController(text: 'nature,museum,history,tourism,religious');

  final TextEditingController _startPlaceController =
    TextEditingController(text: 'Kotor Old Town');

  final TextEditingController _startTimeController =
      TextEditingController(text: '09:00');

  final TextEditingController _endTimeController =
      TextEditingController(text: '18:00');

  String _selectedRouteMode = 'recommended';

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _routeResponse;

  Future<void> _generateRoute() async {
    final categories = _categoriesController.text
        .split(',')
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toList();

    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (categories.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      setState(() {
        _errorMessage = 'Categories, start time and end time are required.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _routeResponse = null;
    });

    try {
      final response = await _routeService.generateFullRoute(
        tripId: widget.tripId,
        categories: categories,
        startTime: startTime,
        endTime: endTime,
        routeMode: _selectedRouteMode,
        startPlace: _startPlaceController.text,
      );

      setState(() {
        _routeResponse = response;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to generate route.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSummary() {
    final summary = _routeResponse?['summary'];

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text('Generated days: ${summary['generated_days'] ?? "-"}'),
            Text('Places: ${summary['number_of_places'] ?? "-"}'),
            Text('Distance: ${summary['total_distance_km'] ?? "-"} km'),
            Text('Travel time: ${summary['total_travel_time_minutes'] ?? "-"} min'),
            Text('Visit duration: ${summary['total_visit_duration_minutes'] ?? "-"} min'),
            Text('Return to hotel: ${summary['return_to_hotel_minutes'] ?? "-"} min'),
            Text('Route mode: ${summary['route_mode'] ?? "-"}'),
            Text('Algorithm: ${summary['route_algorithm'] ?? "-"}'),

            const SizedBox(height: 12),

            Text(
              'Weather note:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(summary['weather_note']?.toString() ?? '-'),

            const SizedBox(height: 12),

            Text(
              'Unplanned places: ${summary['unplanned_place_count'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPlans() {
    final dayPlans = _routeResponse?['day_plans'];

    if (dayPlans == null || dayPlans is! List || dayPlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Text(
          'Day Plans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        ...dayPlans.map((dayPlan) {
          final routeItems = dayPlan['route_items'] as List? ?? [];

          return Card(
            child: ExpansionTile(
              title: Text('Day ${dayPlan['day_number']}'),
              subtitle: Text(dayPlan['date']?.toString() ?? '-'),
              children: [
                ...routeItems.map((item) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(item['visit_order'].toString()),
                    ),
                    title: Text(item['place_name']?.toString() ?? '-'),
                    subtitle: Text(
                      '${item['category'] ?? "-"} | ${item['source'] ?? "-"}\n'
                      '${item['arrival_time'] ?? "-"} - ${item['departure_time'] ?? "-"}\n'
                      'Score: ${item['recommendation_score'] ?? "-"}',
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

@override
void dispose() {
  _startPlaceController.dispose();
  _categoriesController.dispose();
  _startTimeController.dispose();
  _endTimeController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Full Route'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _startPlaceController,
              decoration: const InputDecoration(
                labelText: 'Start Place',
                hintText: 'Kotor Old Town',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _categoriesController,
              decoration: const InputDecoration(
                labelText: 'Categories',
                hintText: 'nature,museum,history',
                border: OutlineInputBorder(),
              ),
            ),

            TextField(
              controller: _startTimeController,
              decoration: const InputDecoration(
                labelText: 'Start Time',
                hintText: '09:00',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _endTimeController,
              decoration: const InputDecoration(
                labelText: 'End Time',
                hintText: '18:00',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedRouteMode,
              decoration: const InputDecoration(
                labelText: 'Route Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'balanced',
                  child: Text('Balanced'),
                ),
                DropdownMenuItem(
                  value: 'shortest',
                  child: Text('Shortest'),
                ),
                DropdownMenuItem(
                  value: 'recommended',
                  child: Text('Recommended'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedRouteMode = value;
                });
              },
            ),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateRoute,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generate Route'),
              ),
            ),

            _buildSummary(),
            _buildDayPlans(),
          ],
        ),
      ),
    );
  }
}