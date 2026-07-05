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

  void _backToTripDetail(BuildContext context) {
    final navigator = Navigator.of(context);

    navigator.pop();

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.route),
                SizedBox(width: 8),
                Text(
                  'Route Summary',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _summaryItem(
              icon: Icons.calendar_today,
              label: 'Generated days',
              value: '${summary['generated_days'] ?? "-"}',
            ),

            const SizedBox(height: 10),

            _summaryItem(
              icon: Icons.place,
              label: 'Places',
              value: '${summary['number_of_places'] ?? "-"}',
            ),

            const SizedBox(height: 10),

            _summaryItem(
              icon: Icons.directions_walk,
              label: 'Distance',
              value: '${summary['total_distance_km'] ?? "-"} km',
            ),

            const SizedBox(height: 10),

            _summaryItem(
              icon: Icons.access_time,
              label: 'Travel time',
              value: '${summary['total_travel_time_minutes'] ?? "-"} min',
            ),

            const SizedBox(height: 10),

            _summaryItem(
              icon: Icons.schedule,
              label: 'Visit duration',
              value: '${summary['total_visit_duration_minutes'] ?? "-"} min',
            ),

            const SizedBox(height: 10),

            _summaryItem(
              icon: Icons.tune,
              label: 'Route mode',
              value: '${summary['route_mode'] ?? "-"}',
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE0E6EF),
                ),
              ),
              child: Text(
                summary['weather_note']?.toString() ??
                    'No weather note available.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary(Map<String, dynamic> dailySummary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E6EF),
        ),
      ),
      child: Text(
        'Places: ${dailySummary['number_of_places'] ?? "-"}\n'
        'Distance: ${dailySummary['total_distance_km'] ?? "-"} km\n'
        'Travel time: ${dailySummary['total_travel_time_minutes'] ?? "-"} min\n'
        'Visit duration: ${dailySummary['total_visit_duration_minutes'] ?? "-"} min\n'
        'Weather: ${dailySummary['weather_note'] ?? "No weather note"}',
      ),
    );
  }

  Widget _buildRouteItem(dynamic item) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('${item['visit_order'] ?? "-"}'),
      ),
      title: Text(
        item['place_name']?.toString() ?? '-',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Category: ${item['category'] ?? "-"}\n'
        'Source: ${item['source'] ?? "-"}\n'
        'Time: ${item['arrival_time'] ?? "-"} - ${item['departure_time'] ?? "-"}\n'
        'Score: ${item['recommendation_score'] ?? "-"}',
      ),
    );
  }

  Widget _buildDayPlanCard(dynamic dayPlan) {
    final routeItems = dayPlan['route_items'] as List<dynamic>? ?? [];
    final dailySummary =
        dayPlan['daily_summary'] as Map<String, dynamic>? ?? {};

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          child: Text('${dayPlan['day_number'] ?? "-"}'),
        ),
        title: Text(
          'Day ${dayPlan['day_number'] ?? "-"}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(dayPlan['date']?.toString() ?? '-'),
        children: [
          if (dailySummary.isNotEmpty) _buildDailySummary(dailySummary),

          if (routeItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No route items.'),
              ),
            )
          else
            ...routeItems.map(_buildRouteItem),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (dayPlans.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Route Result'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    'No route result found.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _backToTripDetail(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Trip Detail'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Result'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),

          const SizedBox(height: 20),

          const Text(
            'Day Plans',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ...dayPlans.map(_buildDayPlanCard),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _backToTripDetail(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Trip Detail'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}