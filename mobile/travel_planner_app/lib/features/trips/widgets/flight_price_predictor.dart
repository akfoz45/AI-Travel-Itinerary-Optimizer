import 'package:flutter/material.dart';
import '../services/flight_prediction_service.dart';
import '../models/trip_model.dart'; 
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class FlightPricePredictor extends StatefulWidget {
  final Trip trip; 

  const FlightPricePredictor({super.key, required this.trip});

  static void show(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FlightPricePredictor(trip: trip),
    );
  }

  @override
  State<FlightPricePredictor> createState() => _FlightPricePredictorState();
}

class _FlightPricePredictorState extends State<FlightPricePredictor> {
  final FlightPredictionService _predictionService = FlightPredictionService();

  final Geocoding _geocoding = Geocoding();

  String _departureTime = 'Morning';
  String _flightClass = 'Economy';
  String _stops = 'zero';

  bool _isLoading = false;
  double? _estimatedPrice;
  String? _errorMessage;

  final List<String> _timeOptions = ['Early_Morning', 'Morning', 'Afternoon', 'Evening', 'Night', 'Late_Night'];

  String _calculateArrivalTime(String departureTime) {
    const mapping = {
      'Early_Morning': 'Morning',
      'Morning': 'Afternoon',
      'Afternoon': 'Evening',
      'Evening': 'Night',
      'Night': 'Late_Night',
      'Late_Night': 'Early_Morning',
    };
    return mapping[departureTime] ?? 'Afternoon';
  }

  int _calculateDaysLeft() {
    try {
      final startDate = DateTime.parse(widget.trip.startDate);
      final days = startDate.difference(DateTime.now()).inDays;
      return days > 0 ? days : 1; 
    } catch (e) {
      return 15; 
    }
  }

  Future<void> _getPrediction() async {
    setState(() {
      _isLoading = true;
      _estimatedPrice = null;
      _errorMessage = null;
    });

    try {
      Position? currentPosition = await _getCurrentLocation();
      
      if (currentPosition == null) {
        setState(() {
          _errorMessage = 'Location could not be obtained. Location permission is required for flight duration calculation.';
          _isLoading = false;
        });
        return; 
      }

      double startLat = currentPosition.latitude;
      double startLng = currentPosition.longitude; 

      double destLat = 51.4700; 
      double destLng = -0.4543;
      
      try {
        List<Location> locations = await _geocoding.locationFromAddress(widget.trip.destination);
        if (locations.isNotEmpty) {
          destLat = locations.first.latitude;
          destLng = locations.first.longitude;
        }
      } catch (e) {
        debugPrint("Target city coordinates could not be found: $e");
      }

      double calculatedDuration = _calculateFlightDuration(
         startLat, startLng, destLat, destLng, 
      );

      final price = await _predictionService.predictPrice(
        departureTime: _departureTime,
        arrivalTime: _calculateArrivalTime(_departureTime), 
        flightClass: _flightClass,
        stops: _stops,
        duration: calculatedDuration, 
        daysLeft: _calculateDaysLeft(), 
      );

      setState(() {
        _estimatedPrice = price;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Prediction failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double inrToTryRate = 0.49; 
    double priceInTry = _estimatedPrice! * inrToTryRate;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF0EA5E9), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'AI Price Predictor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select your preferences to get an instant AI price estimation for ${widget.trip.destination}.',
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              _buildDropdown('Departure Time', _timeOptions, _departureTime, (val) => setState(() => _departureTime = val!)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDropdown('Class', ['Economy', 'Business'], _flightClass, (val) => setState(() => _flightClass = val!))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('Stops', ['zero', 'one', 'two_or_more'], _stops, (val) => setState(() => _stops = val!))),
                ],
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),

              if (_estimatedPrice != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('Estimated Ticket Price', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                      const SizedBox(height: 8),
                      Text(
                        '₺${priceInTry.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _getPrediction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Predict Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value, 
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.replaceAll('_', ' ')))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  double _calculateFlightDuration(double startLat, double startLng, double endLat, double endLng) {
    const double R = 6371.0; 
    
    double dLat = (endLat - startLat) * math.pi / 180.0;
    double dLng = (endLng - startLng) * math.pi / 180.0;
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
               math.cos(startLat * math.pi / 180.0) * math.cos(endLat * math.pi / 180.0) *
               math.sin(dLng / 2) * math.sin(dLng / 2);
               
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distanceKm = R * c; 
    
    const double planeSpeedKmH = 800.0;
    double durationHours = (distanceKm / planeSpeedKmH) + 0.75;
    
    return double.parse(durationHours.toStringAsFixed(2));
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; 
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; 
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null; 
    } 

    return await Geolocator.getCurrentPosition();
  }
}

