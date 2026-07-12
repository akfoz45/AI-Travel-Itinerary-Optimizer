import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import 'route_result_screen.dart';

class GenerateFullRouteScreen extends StatefulWidget {
  final int tripId;
  final List<String> tripPreferences;
  final bool hasHotel; 

  const GenerateFullRouteScreen({
    super.key,
    required this.tripId,
    required this.tripPreferences,
    required this.hasHotel,
  });

  @override
  State<GenerateFullRouteScreen> createState() => _GenerateFullRouteScreenState();
}

class _GenerateFullRouteScreenState extends State<GenerateFullRouteScreen> {
  final TextEditingController _startPlaceController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController(text: '09:00');
  final TextEditingController _endTimeController = TextEditingController(text: '18:00');

  final Map<String, IconData> _categoryIcons = {
    'nature': Icons.park_rounded,
    'museum': Icons.museum_rounded,
    'history': Icons.account_balance_rounded,
    'tourism': Icons.camera_alt_rounded,
    'religious': Icons.church_rounded,
    'restaurant': Icons.restaurant_rounded,
    'cafe': Icons.local_cafe_rounded,
    'beach': Icons.beach_access_rounded,
    'park': Icons.nature_people_rounded,
    'shopping': Icons.shopping_bag_rounded,
  };

  late Set<String> _selectedCategories;
  String _selectedRouteMode = 'recommended';

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

    if (!widget.hasHotel && startPlace.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Since you have no hotel, a Start Place is required.')));
      return;
    }

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one category.')));
      return;
    }

    if (startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start time and end time are required.')));
      return;
    }

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    if (startParts.length != 2 || endParts.length != 2) return;

    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);

    if (startHour == null || startMinute == null || endHour == null || endMinute == null) return;

    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    if (endTotalMinutes <= startTotalMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time.')));
      return;
    }

    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    routeProvider.clearError();

    final response = await routeProvider.generateFullRoute(
      tripId: widget.tripId,
      categories: categories,
      startTime: startTime,
      endTime: endTime,
      routeMode: _selectedRouteMode,
      startPlace: startPlace, 
    );

    if (!mounted) return;

    if (response != null) {
      Navigator.pushReplacement( 
        context,
        MaterialPageRoute(
          builder: (_) => RouteResultScreen(routeResponse: response),
        ),
      );
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
                ? const ColorScheme.dark(primary: Color(0xFF4F46E5), surface: Color(0xFF1E293B)) 
                : const ColorScheme.light(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final formattedHour = selectedTime.hour.toString().padLeft(2, '0');
    final formattedMinute = selectedTime.minute.toString().padLeft(2, '0');
    setState(() => controller.text = '$formattedHour:$formattedMinute');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Starting Point', isDark),
                _buildStartPlaceInput(isDark),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Daily Time Window', isDark),
                _buildTimeSelectors(isDark),

                const SizedBox(height: 24),
                _buildSectionTitle('Travel Pace', isDark),
                _buildRouteModeSelector(isDark),

                const SizedBox(height: 24),
                _buildSectionTitle('Interests & Categories', isDark),
                _buildCategorySelector(isDark),

                const SizedBox(height: 32),
                
                Consumer<RouteProvider>(
                  builder: (context, provider, child) {
                    if (provider.errorMessage != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                Consumer<RouteProvider>(
                  builder: (context, provider, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _generateRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        child: provider.isLoading 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Generate AI Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          Consumer<RouteProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return _buildLoadingOverlay(isDark);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
      ),
    );
  }

  Widget _buildStartPlaceInput(bool isDark) {
    return TextFormField(
      controller: _startPlaceController,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        labelText: widget.hasHotel ? 'Start Place (Optional)' : 'Start Place (Required)',
        hintText: widget.hasHotel ? 'Leave blank to start from your hotel' : 'e.g. City Center',
        prefixIcon: Icon(Icons.location_on_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey),
        suffixIcon: widget.hasHotel ? const Icon(Icons.hotel, color: Color(0xFF4F46E5)) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTimeSelectors(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeInput('Start Time', Icons.wb_sunny_outlined, _startTimeController, isDark),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeInput('End Time', Icons.nights_stay_outlined, _endTimeController, isDark),
        ),
      ],
    );
  }

  Widget _buildTimeInput(String label, IconData icon, TextEditingController controller, bool isDark) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickTime(controller),
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildRouteModeSelector(bool isDark) {
    return Row(
      children: [
        _buildModeCard('Relaxed', 'shortest', Icons.directions_walk_rounded, isDark),
        const SizedBox(width: 10),
        _buildModeCard('Balanced', 'balanced', Icons.balance_rounded, isDark),
        const SizedBox(width: 10),
        _buildModeCard('Discovery', 'recommended', Icons.explore_rounded, isDark),
      ],
    );
  }

  Widget _buildModeCard(String title, String value, IconData icon, bool isDark) {
    final isSelected = _selectedRouteMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRouteMode = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF4F46E5).withValues(alpha: 0.15) 
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categoryIcons.keys.map((category) {
        final isSelected = _selectedCategories.contains(category);
        return FilterChip(
          label: Text(category.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          avatar: Icon(_categoryIcons[category], size: 18, color: isSelected ? Colors.white : const Color(0xFF4F46E5)),
          selected: isSelected,
          showCheckmark: false,
          selectedColor: const Color(0xFF4F46E5),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(category);
              } else {
                if (_selectedCategories.length > 1) {
                  _selectedCategories.remove(category);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must select at least one category.')));
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              'Optimizing Your AI Route...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing distances, opening hours, and preferences.',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}