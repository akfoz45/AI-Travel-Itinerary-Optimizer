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

  Widget _buildTimelineItem(dynamic item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${item['visit_order'] ?? "-"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFF1E88E5).withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0), 
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E6EF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['place_name']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${item['arrival_time'] ?? "-"} - ${item['departure_time'] ?? "-"}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Etiketler (Kategori ve Skor)
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0), // Turuncu ton
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['category'] ?? "Unknown",
                            style: const TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9), // Yeşil ton
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Score: ${item['recommendation_score'] ?? "-"}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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

  Widget _buildDayPlanCard(dynamic dayPlan) {
    final routeItems = dayPlan['route_items'] as List<dynamic>? ?? [];
    final dailySummary = dayPlan['daily_summary'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE0E6EF)), 
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(), 
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F2FD),
          foregroundColor: const Color(0xFF1E88E5),
          child: Text(
            '${dayPlan['day_number'] ?? "-"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Day ${dayPlan['day_number'] ?? "-"}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          dayPlan['date']?.toString() ?? '-',
          style: const TextStyle(color: Colors.grey),
        ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: List.generate(routeItems.length, (index) {
                  final item = routeItems[index];
                  final isLast = index == routeItems.length - 1; 
                  return _buildTimelineItem(item, isLast); 
                }),
              ),
            ),
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