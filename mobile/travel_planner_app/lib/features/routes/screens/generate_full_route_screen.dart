import 'package:flutter/material.dart';

import 'route_result_screen.dart';
import '../services/route_service.dart';

class GenerateFullRouteScreen extends StatefulWidget {
  final int tripId;
  final List<String> tripPreferences;

  const GenerateFullRouteScreen({
    super.key,
    required this.tripId,
    required this.tripPreferences,
  });

  @override
  State<GenerateFullRouteScreen> createState() =>
      _GenerateFullRouteScreenState();
}

class _GenerateFullRouteScreenState extends State<GenerateFullRouteScreen> {
  final RouteService _routeService = RouteService();

  final TextEditingController _startPlaceController =
      TextEditingController(text: 'Kotor Old Town');

  final TextEditingController _startTimeController =
      TextEditingController(text: '09:00');

  final TextEditingController _endTimeController =
      TextEditingController(text: '18:00');

  final List<String> _availableCategories = [
    'nature',
    'museum',
    'history',
    'tourism',
    'religious',
    'restaurant',
    'cafe',
    'beach',
    'park',
    'shopping',
  ];

  late Set<String> _selectedCategories;

  String _selectedRouteMode = 'recommended';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _selectedCategories = widget.tripPreferences.toSet();

    if (_selectedCategories.isEmpty) {
      _selectedCategories = {
        'nature',
        'history',
        'museum',
      };
    }
  }

  Future<void> _generateRoute() async {
    final categories = _selectedCategories.toList();
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (categories.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one category.';
      });
      return;
    }

    if (startTime.isEmpty || endTime.isEmpty) {
      setState(() {
        _errorMessage = 'Start time and end time are required.';
      });
      return;
    }

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    if (startParts.length != 2 || endParts.length != 2) {
      setState(() {
        _errorMessage = 'Start time and end time must be valid.';
      });
      return;
    }

    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);

    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null) {
      setState(() {
        _errorMessage = 'Start time and end time must be valid.';
      });
      return;
    }

    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    if (endTotalMinutes <= startTotalMinutes) {
      setState(() {
        _errorMessage = 'End time must be after start time.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RouteResultScreen(
            routeResponse: response,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

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

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);

    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(':');

      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null && minute != null) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null) return;

    final formattedHour = selectedTime.hour.toString().padLeft(2, '0');
    final formattedMinute = selectedTime.minute.toString().padLeft(2, '0');

    setState(() {
      controller.text = '$formattedHour:$formattedMinute';
    });
  }

  Widget _buildCategorySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);

                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),

                SizedBox(height: 16),

                Text(
                  'Generating your route...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'This may take a few seconds.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startPlaceController.dispose();
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
      body: Stack(
        children: [
          SingleChildScrollView(
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

                _buildCategorySelector(),

                const SizedBox(height: 16),

                TextField(
                  controller: _startTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_startTimeController),
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    hintText: '09:00',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _endTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_endTimeController),
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    hintText: '18:00',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedRouteMode,
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateRoute,
                    icon: const Icon(Icons.route),
                    label: const Text('Generate Route'),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}