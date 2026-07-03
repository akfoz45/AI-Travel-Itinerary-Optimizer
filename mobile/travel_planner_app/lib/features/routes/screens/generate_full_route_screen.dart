import 'package:flutter/material.dart';
import 'route_result_screen.dart';
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
          ],
        ),
      ),
    );
  }
}