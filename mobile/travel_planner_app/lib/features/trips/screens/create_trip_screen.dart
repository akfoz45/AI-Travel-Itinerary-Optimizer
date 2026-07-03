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

  final TextEditingController _hotelNameController =
      TextEditingController(text: 'Hotel Kotor Example');

  final TextEditingController _hotelLatitudeController =
      TextEditingController(text: '42.425');

  final TextEditingController _hotelLongitudeController =
      TextEditingController(text: '18.771');

  final TextEditingController _hotelRatingController =
      TextEditingController(text: '4.5');

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createTrip() async {
    final destination = _destinationController.text.trim();
    final startDate = _startDateController.text.trim();
    final endDate = _endDateController.text.trim();
    final hotelName = _hotelNameController.text.trim();
    final hotelLatitudeText = _hotelLatitudeController.text.trim();
    final hotelLongitudeText = _hotelLongitudeController.text.trim();
    final hotelRatingText = _hotelRatingController.text.trim();

    final preferences = _preferencesController.text
        .split(',')
        .map((preference) => preference.trim())
        .where((preference) => preference.isNotEmpty)
        .toList();

    if (destination.isEmpty ||
        startDate.isEmpty ||
        endDate.isEmpty ||
        hotelName.isEmpty ||
        hotelLatitudeText.isEmpty ||
        hotelLongitudeText.isEmpty) {
      setState(() {
        _errorMessage =
            'Destination, dates, hotel name, latitude and longitude are required.';
      });
      return;
    }

    final hotelLatitude = double.tryParse(hotelLatitudeText);
    final hotelLongitude = double.tryParse(hotelLongitudeText);
    final hotelRating = hotelRatingText.isEmpty
        ? null
        : double.tryParse(hotelRatingText);

    if (hotelLatitude == null || hotelLongitude == null) {
      setState(() {
        _errorMessage = 'Hotel latitude and longitude must be valid numbers.';
      });
      return;
    }

    if (hotelRatingText.isNotEmpty && hotelRating == null) {
      setState(() {
        _errorMessage = 'Hotel rating must be a valid number.';
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
        hotelName: hotelName,
        hotelLatitude: hotelLatitude,
        hotelLongitude: hotelLongitude,
        hotelRating: hotelRating,
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
    _hotelNameController.dispose();
    _hotelLatitudeController.dispose();
    _hotelLongitudeController.dispose();
    _hotelRatingController.dispose();
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

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hotel Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _hotelNameController,
              decoration: const InputDecoration(
                labelText: 'Hotel Name',
                hintText: 'Hotel Kotor Example',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _hotelLatitudeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hotel Latitude',
                hintText: '42.425',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _hotelLongitudeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hotel Longitude',
                hintText: '18.771',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _hotelRatingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hotel Rating',
                hintText: '4.5',
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