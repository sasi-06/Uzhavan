import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/widgets/free_open_street_map.dart';
import '../services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final bool isFarmer;
  const LocationPickerScreen({Key? key, required this.isFarmer}) : super(key: key);

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final LocationService _locationService = LocationService();
  LatLng? _selectedLocation;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedVillage;
  bool _isLoading = false;

  // Mock data for fallback picker as discussed in open questions
  final List<String> states = ['Tamil Nadu', 'Karnataka', 'Kerala'];
  final Map<String, List<String>> districts = {
    'Tamil Nadu': ['Thoothukudi', 'Coimbatore', 'Madurai'],
    'Karnataka': ['Bangalore', 'Mysore'],
  };
  final Map<String, List<String>> villages = {
    'Thoothukudi': ['Kovilpatti', 'Tiruchendur', 'Vilathikulam'],
    'Coimbatore': ['Pollachi', 'Mettupalayam'],
  };

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoading = true);
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _reverseGeocode(position.latitude, position.longitude);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    final result = await _locationService.reverseGeocode(lat, lng);
    if (result != null) {
      setState(() {
        _selectedVillage = result['village'];
        _selectedDistrict = result['district'];
        _selectedState = result['state'];
      });
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _reverseGeocode(location.latitude, location.longitude);
  }

  void _saveLocation() {
    if (_selectedLocation == null && _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }
    
    var lat = _selectedLocation?.latitude;
    var lng = _selectedLocation?.longitude;
    
    if (lat == null || lng == null) {
      if (_selectedDistrict == 'Thoothukudi') { lat = 8.7642; lng = 78.1348; }
      else if (_selectedDistrict == 'Coimbatore') { lat = 11.0168; lng = 76.9558; }
      else if (_selectedDistrict == 'Madurai') { lat = 9.9252; lng = 78.1198; }
      else if (_selectedDistrict == 'Bangalore') { lat = 12.9716; lng = 77.5946; }
      else if (_selectedDistrict == 'Mysore') { lat = 12.2958; lng = 76.6394; }
      else { lat = 13.0827; lng = 80.2707; } // Default Chennai
    }
    
    final locationData = {
      'lat': lat,
      'lng': lng,
      'village': _selectedVillage,
      'district': _selectedDistrict,
      'state': _selectedState,
    };
    
    Navigator.pop(context, locationData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFarmer ? 'Set Farm Location' : 'Set Service Area'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Expanded(
              flex: 1,
              child: _selectedLocation == null 
                  ? const Center(child: Text('Map View Unavailable'))
                  : FreeOpenStreetMap(
                      latitude: _selectedLocation!.latitude,
                      longitude: _selectedLocation!.longitude,
                      initialZoom: 12,
                      markerTitle: _selectedVillage ?? 'Selected Location',
                    ),
            ),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Or Select Manually:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // State Picker
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      hint: const Text('Select State', style: TextStyle(fontSize: 20)),
                      items: states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 20)))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedState = val;
                        _selectedDistrict = null;
                        _selectedVillage = null;
                      }),
                    ),
                    const SizedBox(height: 10),
                    // District Picker
                    if (_selectedState != null && districts[_selectedState] != null)
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        hint: const Text('Select District', style: TextStyle(fontSize: 20)),
                        items: districts[_selectedState!]!.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 20)))).toList(),
                        onChanged: (val) => setState(() {
                          _selectedDistrict = val;
                          _selectedVillage = null;
                        }),
                      ),
                    const SizedBox(height: 10),
                    // Village Picker
                    if (_selectedDistrict != null && villages[_selectedDistrict] != null)
                      DropdownButtonFormField<String>(
                        value: _selectedVillage,
                        hint: const Text('Select Village', style: TextStyle(fontSize: 20)),
                        items: villages[_selectedDistrict!]!.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 20)))).toList(),
                        onChanged: (val) => setState(() => _selectedVillage = val),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 20),
                      ),
                      onPressed: _saveLocation,
                      child: const Text('Confirm Location'),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
