import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const SMWeatherApp());

class SMWeatherApp extends StatelessWidget {
  const SMWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SM Weather',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const WeatherHomeScreen(),
    );
  }
}

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  final String apiKey = "YOUR_API_KEY_HERE";
  String city = "Raigarh"; // Aapki location
  Map<String, dynamic>? weatherData;
  
  // Time update karne ke liye variables
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // App open hote hi time set karna
    _currentTime = DateTime.now();
    
    // Har 1 second mein time update karna
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    
    fetchWeather();
  }

  @override
  void dispose() {
    _timer.cancel(); // App close hone par timer stop karna zaroori hai
    super.dispose();
  }

  Future<void> fetchWeather() async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching weather: $e");
    }
  }

  // Time format helpers
  String _getDayName(int day) {
    return ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][day];
  }

  String _getMonthName(int month) {
    return ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8E5E), Color(0xFF602080)], // Premium Gradient
          ),
        ),
        child: weatherData == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 15),
                      _buildSearchBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildHeroSection(),
                              _buildWeatherDetailsGrid(),
                              const SizedBox(height: 25),
                              _buildForecastSection(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // 1. Top App Bar (Ab yahan Real-Time clock hai)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
              child: const Text("SM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            const Text("SM Weather", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                Text(" $city, India", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                IconButton(
                  onPressed: fetchWeather, 
                  icon: const Icon(Icons.refresh, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // REAL TIME CLOCK TEXT
            Text(
              "${_getDayName(_currentTime.weekday)}, ${_getMonthName(_currentTime.month)} ${_currentTime.day} | "
              "${_currentTime.hour % 12 == 0 ? 12 : _currentTime.hour % 12}:${_currentTime.minute.toString().padLeft(2, '0')} "
              "${_currentTime.hour >= 12 ? 'PM' : 'AM'}",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        )
      ],
    );
  }

  // 2. Elegant Search Bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        onSubmitted: (value) {
          setState(() {
            city = value.toUpperCase(); // Text update hone par city change
          });
          fetchWeather();
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Search city...",
          hintStyle: TextStyle(color: Colors.white60),
          icon: Icon(Icons.search, color: Colors.white70),
        ),
      ),
    );
  }

  // 3. Hero Section (Temperature & Icon)
  Widget _buildHeroSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Image.network(
          "https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@4x.png",
          height: 180,
          fit: BoxFit.contain,
        ),
        Text(
          "${weatherData!['main']['temp'].toInt()}° C",
          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, letterSpacing: -2),
        ),
        Text(
          weatherData!['weather'][0]['description'].toString().toUpperCase(),
          style: const TextStyle(fontSize: 18, color: Colors.white70, letterSpacing: 2),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // 4. Glassmorphic Weather Details
  Widget _buildWeatherDetailsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _glassCard("Feels Like", "${weatherData!['main']['feels_like']}°", Icons.thermostat),
        _glassCard("Humidity", "${weatherData!['main']['humidity']}%", Icons.water_drop),
        _glassCard("Wind", "${weatherData!['wind']['speed']} km/h", Icons.air),
      ],
    );
  }

  Widget _glassCard(String title, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.white70),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // 5. 7-Day Forecast (Mock UI)
  Widget _buildForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("7-Day Forecast", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _glassForecastCard(["Mon", "Tue", "Wed", "Thu", "Fri"][index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _glassForecastCard(String day) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Icon(Icons.wb_sunny, color: Colors.orangeAccent, size: 30),
          const SizedBox(height: 5),
          const Text("32°/24°", style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
