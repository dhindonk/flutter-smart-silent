import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime Noise and Buzzer Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RealtimeNoiseScreen(),
    );
  }
}

class RealtimeNoiseScreen extends StatefulWidget {
  @override
  _RealtimeNoiseScreenState createState() => _RealtimeNoiseScreenState();
}

class _RealtimeNoiseScreenState extends State<RealtimeNoiseScreen> {
  final String apiUrl = "http://192.168.169.160:8000/api"; // Replace with your server URL
  List<FlSpot> noiseData = [];
  bool isBuzzerOn = false;
  Timer? dataFetchTimer;
  double timeCounter = 0;

  @override
  void initState() {
    super.initState();
    // Start fetching data periodically
    dataFetchTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      fetchNoiseData();
    });
  }

  @override
  void dispose() {
    dataFetchTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNoiseData() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/noise'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double noiseLevel = data['noise_level']?.toDouble() ?? 0.0;

        setState(() {
          timeCounter += 1;
          noiseData.add(FlSpot(timeCounter, noiseLevel));
          if (noiseData.length > 20) {
            noiseData.removeAt(0); // Keep the graph manageable
          }
        });
      }
    } catch (e) {
      print("Error fetching noise data: $e");
    }
  }

  Future<void> toggleBuzzer() async {
    setState(() {
      isBuzzerOn = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/buzzer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': true}),
      );

      if (response.statusCode == 200) {
        print("Buzzer activated successfully");
      } else {
        print("Failed to activate buzzer");
      }
    } catch (e) {
      print("Error toggling buzzer: $e");
    }

    // Automatically turn off buzzer after 3 seconds
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      isBuzzerOn = false;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/buzzer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': false}),
      );

      if (response.statusCode == 200) {
        print("Buzzer deactivated successfully");
      } else {
        print("Failed to deactivate buzzer");
      }
    } catch (e) {
      print("Error toggling buzzer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Realtime Noise and Buzzer Control'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 20,
                  minY: 0,
                  maxY: 4095,
                  lineBarsData: [
                    LineChartBarData(
                      spots: noiseData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isBuzzerOn ? null : toggleBuzzer,
              child: Text(isBuzzerOn ? 'Buzzer On (Wait...)' : 'Toggle Buzzer'),
            ),
          ],
        ),
      ),
    );
  }
}
