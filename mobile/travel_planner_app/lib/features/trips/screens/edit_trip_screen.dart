import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _destinationController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _dateRangeDisplayController;
  late final TextEditingController _hotelNameController;

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

  double? _currentLat;
  double? _currentLon;
  String? _originalHotelName;

  @override
  void initState() {
    super.initState();
    final hotel = widget.trip.hotels.isNotEmpty ? widget.trip.hotels.first : null;

    _destinationController = TextEditingController(text: widget.trip.destination);
    _startDateController = TextEditingController(text: widget.trip.startDate);
    _endDateController = TextEditingController(text: widget.trip.endDate);
    
    _dateRangeDisplayController = TextEditingController(
      text: '${widget.trip.startDate} - ${widget.trip.endDate}',
    );

    _selectedPreferences.addAll(
      widget.trip.preferences.map((preference) => preference.preference),
    );

    _originalHotelName = hotel?.name ?? '';
    _hotelNameController = TextEditingController(text: _originalHotelName);

    _currentLat = hotel?.latitude;
    _currentLon = hotel?.longitude;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _dateRangeDisplayController.dispose();
    _hotelNameController.dispose();
    super.dispose();
  }

  Future<Map<String, double>?> _getCoordinates(String hotelName, String destination) async {
    final searchQueries = [
      '$hotelName, $destination', 
      '$hotelName ${destination.replaceAll(',', '')}', 
      hotelName, 
    ];

    for (String query in searchQueries) {
      try {
        final encodedQuery = Uri.encodeComponent(query);
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1');
        
        final response = await http.get(url, headers: {'User-Agent': 'TravelPlannerApp/1.0'});
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List;
          if (data.isNotEmpty) {
            return {
              'lat': double.parse(data[0]['lat']),
              'lon': double.parse(data[0]['lon']),
            };
          }
        }
      } catch (e) {
        debugPrint('Geocoding error for query "$query": $e');
      }
    }
    return null;
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
              primary: Color(0xFF4F46E5), 
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

  Future<void> _updateTrip() async {
    if (!_formKey.currentState!.validate()) return;

    final destination = _destinationController.text.trim();
    final startDate = _startDateController.text.trim();
    final endDate = _endDateController.text.trim();
    final hotelName = _hotelNameController.text.trim();
    final preferences = _selectedPreferences.toList();

    if (preferences.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one preference.');
      return;
    }

    final parsedStartDate = DateTime.tryParse(startDate);
    final parsedEndDate = DateTime.tryParse(endDate);
    if (parsedStartDate == null || parsedEndDate == null) {
      setState(() => _errorMessage = 'Dates must be valid.');
      return;
    }
    if (parsedEndDate.isBefore(parsedStartDate)) {
      setState(() => _errorMessage = 'End date cannot be before start date.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    double finalLat = _currentLat ?? 0.0;
    double finalLon = _currentLon ?? 0.0;

    if (hotelName != _originalHotelName || _currentLat == null) {
      final coords = await _getCoordinates(hotelName, destination);
      if (coords == null) {
        setState(() {
          _errorMessage = "We couldn't find the location for '$hotelName'. Please check the hotel name.";
          _isLoading = false;
        });
        return;
      }
      finalLat = coords['lat']!;
      finalLon = coords['lon']!;
    }

    try {
      await _tripService.updateTrip(
        tripId: widget.trip.tripId,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        preferences: preferences,
        hotelName: hotelName,
        hotelLatitude: finalLat,
        hotelLongitude: finalLon,
        hotelRating: null, 
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
                  selectedColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  checkmarkColor: const Color(0xFF4F46E5),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trip'),
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
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
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
              
              const SizedBox(height: 24),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateTrip,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Update Trip', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}