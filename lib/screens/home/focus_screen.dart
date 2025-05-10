import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:uptodo/screens/home/calendar_screen.dart';
import 'package:uptodo/screens/home/home_screen.dart';
import 'package:uptodo/screens/home/profile_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  bool isFocusing = false;
  Timer? timer;
  int elapsedSeconds = 0;
  final int totalSeconds = 30 * 60;

  List<double> focusData = [0, 0, 0, 0, 0, 0, 0];

  void startFocus() {
    if (elapsedSeconds == 0) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (elapsedSeconds < totalSeconds) {
          setState(() {
            elapsedSeconds++;
          });
        }
      });
    }
    setState(() {
      isFocusing = true;
    });
  }

  void stopFocus() {
    setState(() {
      isFocusing = false;
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Color getTextColor() {
    return elapsedSeconds >= (totalSeconds * 0.5) ? Colors.black : Colors.grey;
  }

  Widget _buildNavItem(String iconPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = elapsedSeconds / totalSeconds;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Focus Mode', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    formatTime(totalSeconds - elapsedSeconds),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: getTextColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "While your focus mode is on, all of your\nnotifications will be off",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isFocusing ? stopFocus : startFocus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFocusing ? Colors.red : Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isFocusing ? "Stop Focusing" : "Start Focusing",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Overview",
                      style: TextStyle(color: Colors.black, fontSize: 18)),
                  Text("This Week", style: TextStyle(color: Colors.black)),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1.7,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, interval: 1)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Text(days[value.toInt()]);
                              })),
                    ),
                    barGroups: List.generate(7, (index) {
                      return BarChartGroupData(x: index, barRods: [
                        BarChartRodData(
                            toY: focusData[index],
                            color: Colors.blue,
                            width: 14,
                            borderRadius: BorderRadius.circular(4)),
                      ]);
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem("assets/image/home_icon.png", "Home", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()));
            }),
            _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()));
            }),
            const SizedBox(width: 48),
            _buildNavItem("assets/image/clock_icon.png", "Focus", () {
              // Остаёмся на текущем экране
            }),
            _buildNavItem("assets/image/profile_icon.png", "Profile", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
          ],
        ),
      ),
    );
  }
}
