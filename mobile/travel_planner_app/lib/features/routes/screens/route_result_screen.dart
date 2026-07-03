import 'package:flutter/material.dart';

class RouteResultScreen extends StatelessWidget {
  final Map<String, dynamic> routeResponse;

  const RouteResultScreen({
    super.key,
    required this.routeResponse,
  });

  Map<String, dynamic> get summary {
    return routeResponse['summary'] as Map<String, dynamic>? ?? {};
  }

  List<dynamic> get dayPlans {
    return routeResponse['day_plans'] as List<dynamic>? ?? [];
  }

  Widget _summaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Summary',
              style: TextStyle(
                fontSize: 20,
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
            Text('Total plan duration: ${summary['total_plan_duration_minutes'] ?? "-"} min'),

            const SizedBox(height: 12),

            Text('Route mode: ${summary['route_mode'] ?? "-"}'),
            Text('Algorithm: ${summary['route_algorithm'] ?? "-"}'),

            const SizedBox(height: 12),

            const Text(
              'Weather Note',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(summary['weather_note']?.toString() ?? '-'),

            const SizedBox(height: 12),

            Text('Unplanned places: ${summary['unplanned_place_count'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _dayPlanCard(dynamic dayPlan) {
    final routeItems = dayPlan['route_items'] as List<dynamic>? ?? [];
    final dailySummary =
        dayPlan['daily_summary'] as Map<String, dynamic>? ?? {};

    return Card(
      child: ExpansionTile(
        title: Text('Day ${dayPlan['day_number'] ?? "-"}'),
        subtitle: Text(dayPlan['date']?.toString() ?? '-'),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Places: ${dailySummary['number_of_places'] ?? "-"}\n'
                'Distance: ${dailySummary['total_distance_km'] ?? "-"} km\n'
                'Travel time: ${dailySummary['total_travel_time_minutes'] ?? "-"} min\n'
                'Visit duration: ${dailySummary['total_visit_duration_minutes'] ?? "-"} min\n'
                'Weather: ${dailySummary['weather_note'] ?? "-"}',
              ),
            ),
          ),

          if (routeItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No route items.'),
            )
          else
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Result'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(),

          const SizedBox(height: 20),

          const Text(
            'Day Plans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          if (dayPlans.isEmpty)
            const Text('No day plans returned.')
          else
            ...dayPlans.map(_dayPlanCard),
        ],
      ),
    );
  }
}