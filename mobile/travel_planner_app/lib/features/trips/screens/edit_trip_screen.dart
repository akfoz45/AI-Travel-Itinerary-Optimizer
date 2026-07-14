import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../../../core/storage/token_storage.dart'; 

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
              Autocomplete<String>(
                initialValue: TextEditingValue(text: widget.trip.destination),
                
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  final searchQuery = textEditingValue.text;
                  if (searchQuery.isEmpty || searchQuery.length < 3) {
                    return const Iterable<String>.empty();
                  }
                  
                  try {
                    final url = Uri.parse('http://127.0.0.1:8000/api/trips/places/autocomplete/?q=$searchQuery&type=city');
                    
                    final tokenStorage = TokenStorage();
                    final token = await tokenStorage.getAccessToken(); 

                    final response = await http.get(url, headers: {
                      'Content-Type': 'application/json',
                      if (token != null) 'Authorization': 'Bearer $token', 
                    });

                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);
                      final predictions = data['predictions'] as List;
                      return predictions.map((p) => p.toString()).toList();
                    }
                  } catch (e) {
                    debugPrint("API Error (City): $e");
                  }
                  return const Iterable<String>.empty();
                },

                onSelected: (String selectedValue) {
                  _destinationController.text = selectedValue;
                },

                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  if (controller.text.isEmpty && _destinationController.text.isNotEmpty) {
                    controller.text = _destinationController.text;
                  }
                  
                  return TextFormField(
                    controller: controller, 
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    onChanged: (val) {
                      _destinationController.text = val;
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Destination is required' : null,
                    decoration: const InputDecoration(
                      labelText: 'Destination (City)',
                      hintText: 'e.g. İzmir, Turkey',
                      prefixIcon: Icon(Icons.location_city_rounded),
                    ),
                  );
                },

                optionsViewBuilder: (context, onSelected, options) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width - 32, 
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              leading: const Icon(Icons.location_on_rounded, color: Color(0xFF4F46E5)),
                              title: Text(option, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              onTap: () {
                                onSelected(option); 
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
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
              
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _originalHotelName ?? ''),

                optionsBuilder: (TextEditingValue textEditingValue) async {
                  final searchQuery = textEditingValue.text;
                  if (searchQuery.isEmpty || searchQuery.length < 3) {
                    return const Iterable<String>.empty();
                  }
                  
                  try {
                    final url = Uri.parse('http://127.0.0.1:8000/api/trips/places/autocomplete/?q=$searchQuery&type=hotel');
                    
                    final tokenStorage = TokenStorage();
                    final token = await tokenStorage.getAccessToken(); 

                    final response = await http.get(url, headers: {
                      'Content-Type': 'application/json',
                      if (token != null) 'Authorization': 'Bearer $token', 
                    });

                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);
                      final predictions = data['predictions'] as List;
                      return predictions.map((p) => p.toString()).toList();
                    }
                  } catch (e) {
                    debugPrint("API Error (Hotel): $e");
                  }
                  return const Iterable<String>.empty();
                },

                onSelected: (String selectedValue) {
                  _hotelNameController.text = selectedValue;
                },

                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  if (controller.text.isEmpty && _hotelNameController.text.isNotEmpty) {
                    controller.text = _hotelNameController.text;
                  }

                  return TextFormField(
                    controller: controller, 
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    onChanged: (val) {
                      _hotelNameController.text = val;
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Hotel name is required' : null,
                    decoration: const InputDecoration(
                      labelText: 'Hotel Name',
                      hintText: 'e.g. Hilton Paris Opera',
                      prefixIcon: Icon(Icons.hotel_rounded),
                    ),
                  );
                },

                optionsViewBuilder: (context, onSelected, options) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width - 32, 
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              leading: const Icon(Icons.hotel_rounded, color: Color(0xFF4F46E5)),
                              title: Text(option, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              onTap: () {
                                onSelected(option); 
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
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