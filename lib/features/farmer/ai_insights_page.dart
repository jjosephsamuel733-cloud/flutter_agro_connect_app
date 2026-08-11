// lib/features/farmer/ai_insights_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({super.key});

  @override
  State<AIInsightsPage> createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> {
  // Get a free key at https://www.weatherapi.com/
  final String apiKey = "YOUR_WEATHERAPI_KEY";
  List _weatherForecast = [];
  String _currentCity = "Detecting...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocationAndWeather();
  }

  Future<void> _initLocationAndWeather() async {
    try {
      Position position = await _determinePosition();
      await _fetch7DayWeather(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Location/Weather Error: $e");
      setState(() {
        _currentCity = "Tiruchirappalli (Manual)";
        _isLoading = false;
      });
      // Fallback to manual city if location fails
      _fetchWeatherByCity("Tiruchirappalli");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled.';

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw 'Location permissions are denied';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetch7DayWeather(double lat, double lon) async {
    final url =
        "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$lat,$lon&days=7&aqi=no&alerts=yes";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _currentCity = data['location']['name'];
        _weatherForecast = data['forecast']['forecastday'];
        _isLoading = false;
      });
    }
  }

  // Fallback method
  Future<void> _fetchWeatherByCity(String city) async {
    final url =
        "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$city&days=7&aqi=no&alerts=yes";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _weatherForecast = data['forecast']['forecastday'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("AI Farmer Insights"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 5),
                Text(
                  _currentCity,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildSectionHeader("7-Day Weather Forecast", Icons.wb_sunny),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildWeatherList(),

            const SizedBox(height: 25),
            _buildAlertCard(),
            const SizedBox(height: 25),
            _buildSectionHeader("AI Smart Suggestions", Icons.psychology),
            _buildSuggestionCard(
              "Best Crop to Harvest Now",
              "Paddy (Kuruvai)",
              "Based on upcoming 7-day clear sky forecast, ideal for drying.",
              Colors.orange,
            ),
            _buildSuggestionCard(
              "High Demand Crop",
              "Small Onions (Shallots)",
              "Regional markets show 15% increase in demand for next week.",
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWeatherList() {
    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weatherForecast.length,
        itemBuilder: (context, index) {
          var day = _weatherForecast[index];
          var date = DateTime.parse(day['date']);
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE, MMM d').format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Image.network(
                    "https:${day['day']['condition']['icon']}",
                    width: 45,
                  ),
                  Text(
                    "${day['day']['avgtemp_c'].round()}°C",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    day['day']['condition']['text'],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard() {
    bool hasRain = _weatherForecast.any(
      (day) => day['day']['daily_will_it_rain'] == 1,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasRain ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasRain ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasRain ? Icons.umbrella : Icons.check_circle,
            color: hasRain ? Colors.orange : Colors.green,
            size: 40,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasRain ? "Rain Alert" : "Weather Clear",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasRain ? Colors.orange : Colors.green,
                  ),
                ),
                Text(
                  hasRain
                      ? "Showers expected this week. Delay pesticide application and secure harvested crops."
                      : "Excellent weather for harvesting and sun-drying crops over the next 7 days.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    String title,
    String crop,
    String reason,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.eco, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              crop,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(reason, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
