import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({
    super.key,
    required this.trip,
  });

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final TripService _tripService = TripService();

  late final TextEditingController _destinationController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _hotelNameController;
  late final TextEditingController _hotelLatitudeController;
  late final TextEditingController _hotelLongitudeController;
  late final TextEditingController _hotelRatingController;

  final List<String> _availablePreferences = [
    'nature',
    'history',
    'museum',
    'tourism',
    'religious',
    'restaurant',
    'cafe',
    'beach',
    'park',
    'shopping',
  ];

  final Set<String> _selectedPreferences = {};

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final hotel = widget.trip.hotels.isNotEmpty
        ? widget.trip.hotels.first
        : null;

    _destinationController = TextEditingController(
      text: widget.trip.destination,
    );

    _startDateController = TextEditingController(
      text: widget.trip.startDate,
    );

    _endDateController = TextEditingController(
      text: widget.trip.endDate,
    );

    _selectedPreferences.addAll(
      widget.trip.preferences.map(
        (preference) => preference.preference,
      ),
    );

    _hotelNameController = TextEditingController(
      text: hotel?.name ?? '',
    );

    _hotelLatitudeController = TextEditingController(
      text: hotel?.latitude.toString() ?? '',
    );

    _hotelLongitudeController = TextEditingController(
      text: hotel?.longitude.toString() ?? '',
    );

    _hotelRatingController = TextEditingController(
      text: hotel?.rating?.toString() ?? '',
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.tryParse(controller.text) ?? now
          : now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate == null) return;

    setState(() {
      controller.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    });
  }

  Future<void> _updateTrip() async {
    final destination = _destinationController.text.trim();
    final startDate = _startDateController.text.trim();
    final endDate = _endDateController.text.trim();

    final hotelName = _hotelNameController.text.trim();
    final hotelLatitudeText = _hotelLatitudeController.text.trim();
    final hotelLongitudeText = _hotelLongitudeController.text.trim();
    final hotelRatingText = _hotelRatingController.text.trim();

    final preferences = _selectedPreferences.toList();

    if (preferences.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one preference.';
      });
      return;
    }

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

    final parsedStartDate = DateTime.tryParse(startDate);
    final parsedEndDate = DateTime.tryParse(endDate);

    if (parsedStartDate == null || parsedEndDate == null) {
      setState(() {
        _errorMessage = 'Dates must be valid.';
      });
      return;
    }

    if (parsedEndDate.isBefore(parsedStartDate)) {
      setState(() {
        _errorMessage = 'End date cannot be before start date.';
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
      await _tripService.updateTrip(
        tripId: widget.trip.tripId,
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

      Navigator.pop(context, {
        'updated': true,
        'shouldAskRegenerate': widget.trip.dayPlans.isNotEmpty,
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to update trip.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPreferenceSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availablePreferences.map((preference) {
                final isSelected = _selectedPreferences.contains(preference);

                return FilterChip(
                  label: Text(preference),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPreferences.add(preference);
                      } else {
                        _selectedPreferences.remove(preference);
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

  @override
  void dispose() {
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
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
        title: const Text('Edit Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _startDateController,
              readOnly: true,
              onTap: () => _pickDate(_startDateController),
              decoration: const InputDecoration(
                labelText: 'Start Date',
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _endDateController,
              readOnly: true,
              onTap: () => _pickDate(_endDateController),
              decoration: const InputDecoration(
                labelText: 'End Date',
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            _buildPreferenceSelector(),

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
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _hotelLatitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Hotel Latitude',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _hotelLongitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Hotel Longitude',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _hotelRatingController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Hotel Rating',
                border: OutlineInputBorder(),
              ),
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
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateTrip,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}