import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final TextEditingController _hotelNameController =
      TextEditingController(text: 'Hotel Kotor Example');

  final TextEditingController _hotelLatitudeController =
      TextEditingController(text: '42.425');

  final TextEditingController _hotelLongitudeController =
      TextEditingController(text: '18.771');

  final TextEditingController _hotelRatingController =
      TextEditingController(text: '4.5');

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateRangeDisplayController =
      TextEditingController(text: '2026-07-01 - 2026-07-03');

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

  final Set<String> _selectedPreferences = {
    'nature',
    'history',
    'museum',
  };

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createTrip() async {

    if (!_formKey.currentState!.validate()) return;

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
    final hotelRating =
        hotelRatingText.isEmpty ? null : double.tryParse(hotelRatingText);

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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    
    final initialStart = DateTime.tryParse(_startDateController.text) ?? now;
    final initialEnd = DateTime.tryParse(_endDateController.text) ?? now.add(const Duration(days: 2));

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5), 
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange == null) return;

    final startFormatted = DateFormat('yyyy-MM-dd').format(selectedRange.start);
    final endFormatted = DateFormat('yyyy-MM-dd').format(selectedRange.end);

    setState(() {
      _startDateController.text = startFormatted;
      _endDateController.text = endFormatted;
      _dateRangeDisplayController.text = '$startFormatted - $endFormatted';
    });
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
        title: const Text('Create Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, 
          child: Column(
            children: [
              TextFormField( 
                controller: _destinationController,
                validator: (value) => value == null || value.isEmpty ? 'Destination is required' : null,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: 'e.g. Kotor, Montenegro',
                  prefixIcon: Icon(Icons.location_city), 
                ),
              ),
              const SizedBox(height: 16),
              
              // Tek bir Tarih Aralığı Alanı
              TextFormField(
                controller: _dateRangeDisplayController,
                readOnly: true,
                onTap: _pickDateRange, 
                validator: (value) => value == null || value.isEmpty ? 'Dates are required' : null,
                decoration: const InputDecoration(
                  labelText: 'Travel Dates',
                  prefixIcon: Icon(Icons.calendar_month),
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
              
              TextFormField(
                controller: _hotelNameController,
                validator: (value) => value == null || value.isEmpty ? 'Hotel name is required' : null,
                decoration: const InputDecoration(
                  labelText: 'Hotel Name',
                  prefixIcon: Icon(Icons.hotel),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hotelLatitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.map),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _hotelLongitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _hotelRatingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Hotel Rating (Optional)',
                  prefixIcon: Icon(Icons.star_border),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              SizedBox(
                width: double.infinity,
                height: 50, 
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTrip,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Create Trip', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}