import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../services/trip_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final TripService _tripService = TripService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _dateRangeDisplayController = TextEditingController();
  final TextEditingController _hotelNameController = TextEditingController();

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
    
    final initialStart = _startDateController.text.isNotEmpty 
        ? DateTime.parse(_startDateController.text) 
        : now;
    final initialEnd = _endDateController.text.isNotEmpty 
        ? DateTime.parse(_endDateController.text) 
        : now.add(const Duration(days: 2));

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
                ? const ColorScheme.dark(
                    primary: Color(0xFF4F46E5), 
                    onPrimary: Colors.white,   
                    surface: Color(0xFF1E293B), 
                    onSurface: Colors.white,    
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF4F46E5),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5), 
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
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

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;

    final destination = _destinationController.text.trim();
    final startDate = _startDateController.text.trim();
    final endDate = _endDateController.text.trim();
    final hotelName = _hotelNameController.text.trim();
    final preferences = _selectedPreferences.toList();

    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    if (preferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one preference.')));
      return;
    }

    final parsedStartDate = DateTime.tryParse(startDate);
    final parsedEndDate = DateTime.tryParse(endDate);

    if (parsedEndDate != null && parsedStartDate != null && parsedEndDate.isBefore(parsedStartDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date cannot be before start date.')));
      return;
    }

    tripProvider.clearError();

    final coords = await _getCoordinates(hotelName, destination);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("We couldn't find the location for '$hotelName'.")));
      return;
    }

    final success = await tripProvider.createTrip(
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      preferences: preferences,
      hotelName: hotelName,
      hotelLatitude: coords['lat']!,
      hotelLongitude: coords['lon']!,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
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
                  hintText: 'e.g. Paris, France', 
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
                  hintText: 'Select your travel dates',
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
                  hintText: 'e.g. Hilton Paris Opera',
                  prefixIcon: Icon(Icons.hotel),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Consumer<TripProvider>(
                builder: (context, provider, child) {
                  if (provider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              Consumer<TripProvider>(
                builder: (context, provider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _createTrip,
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Create Trip', style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}