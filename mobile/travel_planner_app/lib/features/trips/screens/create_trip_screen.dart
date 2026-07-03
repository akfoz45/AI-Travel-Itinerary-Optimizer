import 'package:flutter/material.dart';

import '../services/trip_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final TripService _tripService = TripService();

  final TextEditingController _destinationController =
      TextEditingController(text: 'Kotor, Montenegro');

  final TextEditingController _startDateController =
      TextEditingController(text: '2026-07-01');

  final TextEditingController _endDateController =
      TextEditingController(text: '2026-07-03');

  final TextEditingController _preferencesController =
      TextEditingController(text: 'nature,history,museum');

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createTrip() async {
    final destination = _destinationController.text.trim();
    final startDate = _startDateController.text.trim();
    final endDate = _endDateController.text.trim();

    final preferences = _preferencesController.text
        .split(',')
        .map((preference) => preference.trim())
        .where((preference) => preference.isNotEmpty)
        .toList();

    if (destination.isEmpty || startDate.isEmpty || endDate.isEmpty) {
      setState(() {
        _errorMessage = 'Destination, start date and end date are required.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _tripService.createTrip(
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        preferences: preferences,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to create trip.\n$error';
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
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'Kotor, Montenegro',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _endDateController,
              decoration: const InputDecoration(
                labelText: 'End Date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _preferencesController,
              decoration: const InputDecoration(
                labelText: 'Preferences',
                hintText: 'nature,history,museum',
                border: OutlineInputBorder(),
              ),
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
                onPressed: _isLoading ? null : _createTrip,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}