import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uptodo/screens/home/calendar_screen.dart';
import 'package:uptodo/screens/home/home_screen.dart';
import 'package:uptodo/screens/home/profile_screen.dart';
import 'package:uptodo/widgets/add_task_widget.dart';

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
  DateTime? focusStartTime;
  
  List<double> focusData = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadWeeklyFocusData();
  }

  Future<void> _loadWeeklyFocusData() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateStr = "${date.year}-${date.month}-${date.day}";
        
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection("focus_sessions")
              .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where("date", isEqualTo: dateStr)
              .get();

          double totalHours = 0;
          for (var doc in snapshot.docs) {
            totalHours += (doc["duration"] as num).toDouble() / 3600;
          }
          
          setState(() {
            focusData[i] = totalHours;
          });
        } catch (e) {
          print('Error loading focus data for $dateStr: $e');
          // В случае ошибки доступа оставляем значение 0 для этого дня
        }
      }
    } catch (e) {
      print('Error in _loadWeeklyFocusData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось загрузить данные фокус-режима'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void startFocus() {
    focusStartTime = DateTime.now();
    if (elapsedSeconds == 0) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (elapsedSeconds < totalSeconds) {
          setState(() {
            elapsedSeconds++;
          });
        } else {
          stopFocus();
        }
      });
    }
    setState(() {
      isFocusing = true;
    });
  }

  Future<void> stopFocus() async {
    if (focusStartTime != null && isFocusing && FirebaseAuth.instance.currentUser != null) {
      final duration = elapsedSeconds;
      final now = DateTime.now();
      final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      try {
        // Создаем данные для сохранения
        final sessionData = {
          "userId": FirebaseAuth.instance.currentUser!.uid,
          "date": date,
          "startTime": Timestamp.fromDate(focusStartTime!),
          "endTime": Timestamp.fromDate(now),
          "duration": duration,
          "createdAt": FieldValue.serverTimestamp(),
        };

        // Пробуем сохранить данные
        await FirebaseFirestore.instance
            .collection("focus_sessions")
            .add(sessionData)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Превышено время ожидания при сохранении');
              },
            );

        print('Focus session saved successfully: $sessionData');
        
        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Сохранено: ${duration ~/ 60} минут фокусировки'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Обновляем статистику
        await _loadWeeklyFocusData();
      } catch (e) {
        print('Error saving focus session: $e');
        String errorMessage = 'Не удалось сохранить сессию фокусировки';
        
        if (e is FirebaseException) {
          switch (e.code) {
            case 'permission-denied':
              errorMessage = 'Нет прав доступа для сохранения данных';
              break;
            case 'unavailable':
              errorMessage = 'Сервер недоступен. Проверьте подключение';
              break;
            default:
              errorMessage = 'Ошибка Firebase: ${e.message}';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    timer?.cancel();
    setState(() {
      isFocusing = false;
      elapsedSeconds = 0;
      focusStartTime = null;
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

  Widget _buildNavItem(String iconPath, String label, VoidCallback onTap, bool isActive) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: isActive ? Colors.blueAccent : Colors.white70,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.blueAccent : Colors.white70,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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
      floatingActionButton: const AddTaskWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900],
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem("assets/image/home_icon.png", "Home", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }, false),
                _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarScreen()),
                  );
                }, false),
                const SizedBox(width: 48),
                _buildNavItem("assets/image/clock_icon.png", "Focus", () {
                  // Остаёмся на текущем экране
                }, true),
                _buildNavItem("assets/image/profile_icon.png", "Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                }, false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
