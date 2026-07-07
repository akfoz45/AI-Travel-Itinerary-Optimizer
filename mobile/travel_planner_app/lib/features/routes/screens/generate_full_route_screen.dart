import 'package:flutter/material.dart';

import 'route_result_screen.dart';
import '../services/route_service.dart';

class GenerateFullRouteScreen extends StatefulWidget {
  final int tripId;
  final List<String> tripPreferences;
  // 1. ADIM: Otel olup olmadığını kontrol etmek için değişkenimizi ekledik
  final bool hasHotel; 

  const GenerateFullRouteScreen({
    super.key,
    required this.tripId,
    required this.tripPreferences,
    required this.hasHotel, // Constructor'a ekledik
  });

  @override
  State<GenerateFullRouteScreen> createState() =>
      _GenerateFullRouteScreenState();
}

class _GenerateFullRouteScreenState extends State<GenerateFullRouteScreen> {
  final RouteService _routeService = RouteService();

  // Varsayılan metinleri sildik ki kullanıcı oteli varsa boş bırakabilsin
  final TextEditingController _startPlaceController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController(text: '09:00');
  final TextEditingController _endTimeController = TextEditingController(text: '18:00');

  final List<String> _availableCategories = [
    'nature', 'museum', 'history', 'tourism', 'religious', 
    'restaurant', 'cafe', 'beach', 'park', 'shopping',
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
      _selectedCategories = {'nature', 'history', 'museum'};
    }
  }

  Future<void> _generateRoute() async {
    final categories = _selectedCategories.toList();
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();
    final startPlace = _startPlaceController.text.trim();

    // 2. ADIM: KOŞULLU VALIDASYON
    // Eğer otel YOKSA ve başlangıç noktası BOŞSA hata ver!
    if (!widget.hasHotel && startPlace.isEmpty) {
      setState(() {
        _errorMessage = 'Since you have no hotel, a Start Place is required.';
      });
      return;
    }

    if (categories.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one category.');
      return;
    }

    if (startTime.isEmpty || endTime.isEmpty) {
      setState(() => _errorMessage = 'Start time and end time are required.');
      return;
    }

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    if (startParts.length != 2 || endParts.length != 2) {
      setState(() => _errorMessage = 'Start time and end time must be valid.');
      return;
    }

    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);

    if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
      setState(() => _errorMessage = 'Start time and end time must be valid.');
      return;
    }

    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    if (endTotalMinutes <= startTotalMinutes) {
      setState(() => _errorMessage = 'End time must be after start time.');
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
        // Backend'e startPlace gönderiyoruz. Eğer boşsa (ve otel varsa) backend oteli kullanacak.
        startPlace: startPlace, 
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
        setState(() => _isLoading = false);
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
      builder: (context, child) {
        // Tema uyumluluğu eklendi (Karanlık Mod destekli saat seçici)
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
                ? const ColorScheme.dark(primary: Color(0xFF4F46E5)) 
                : const ColorScheme.light(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  selectedColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  checkmarkColor: const Color(0xFF4F46E5),
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
      color: Colors.black.withValues(alpha: 0.4),
      child: const Center(
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF4F46E5)),
                SizedBox(height: 20),
                Text(
                  'Generating your route...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Our AI is optimizing the best path for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
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
        title: const Text('Generate Route'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                
                // 3. ADIM: Dinamik Start Place Kutucuğu
                TextFormField(
                  controller: _startPlaceController,
                  decoration: InputDecoration(
                    labelText: widget.hasHotel ? 'Start Place (Optional)' : 'Start Place (Required)',
                    hintText: widget.hasHotel ? 'Leave blank to start from your hotel' : 'e.g. Kotor Old Town',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: widget.hasHotel ? const Icon(Icons.hotel, color: Color(0xFF4F46E5)) : null,
                  ),
                ),

                const SizedBox(height: 16),
                _buildCategorySelector(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        readOnly: true,
                        onTap: () => _pickTime(_startTimeController),
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        onTap: () => _pickTime(_endTimeController),
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          prefixIcon: Icon(Icons.access_time_filled),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedRouteMode,
                  decoration: const InputDecoration(
                    labelText: 'Route Mode',
                    prefixIcon: Icon(Icons.tune),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'balanced', child: Text('Balanced')),
                    DropdownMenuItem(value: 'shortest', child: Text('Shortest')),
                    DropdownMenuItem(value: 'recommended', child: Text('Recommended')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedRouteMode = value);
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
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateRoute,
                    icon: const Icon(Icons.route),
                    label: const Text('Generate AI Route', style: TextStyle(fontSize: 16)),
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