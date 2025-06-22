import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uptodo/screens/home/calendar_screen.dart';
import 'package:uptodo/screens/home/home_screen.dart';
import 'package:uptodo/screens/home/profile_screen.dart';
import 'package:uptodo/widgets/add_task_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dnd/flutter_dnd.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final user = FirebaseAuth.instance.currentUser;

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
              FocusTimerWidget(),
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
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('focus_sessions')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No focus sessions this week',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  final now = DateTime.now();
                  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                  Map<String, int> minutesPerDay = {};
                  for (int i = 0; i < 7; i++) {
                    final date = startOfWeek.add(Duration(days: i));
                    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    minutesPerDay[dateStr] = 0;
                  }
                  for (var doc in snapshot.data!.docs) {
                    try {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = data['date']?.toString();
                      final durationRaw = data['duration'];
                      int? duration;
                      if (durationRaw is int) {
                        duration = durationRaw;
                      } else if (durationRaw is num) {
                        duration = durationRaw.toInt();
                      } else if (durationRaw != null) {
                        duration = int.tryParse(durationRaw.toString());
                      }
                      if (date != null && duration != null && minutesPerDay.containsKey(date)) {
                        minutesPerDay[date] = (minutesPerDay[date] ?? 0) + (duration ~/ 60);
                      }
                    } catch (e) {
                      debugPrint('Error parsing focus_sessions doc: $e');
                    }
                  }
                  final focusMinutes = minutesPerDay.values.toList();
                  final allZero = focusMinutes.every((m) => m == 0);
                  if (allZero) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No focus sessions this week',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final min = focusMinutes[i];
                        final h = min ~/ 60;
                        final m = min % 60;
                        String label = h > 0 ? '${h}h${m > 0 ? ' $m' : ''}m' : '${m}m';
                        double barHeight = min == 0 ? 8 : 40 + (min * 1.2).clamp(0, 100);
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: min == 0 ? Colors.grey[400] : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 18,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: min == 0 ? Colors.grey[200] : Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                days[i],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  );
                },
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
}

class FocusTimerWidget extends StatefulWidget {
  @override
  State<FocusTimerWidget> createState() => _FocusTimerWidgetState();
}

class _FocusTimerWidgetState extends State<FocusTimerWidget> {
  bool isFocusing = false;
  Timer? timer;
  int elapsedSeconds = 0;
  final int totalSeconds = 30 * 60;
  DateTime? focusStartTime;
  List<double> focusData = [0, 0, 0, 0, 0, 0, 0];

  static const String _focusActiveKey = 'focus_active';
  static const String _focusStartKey = 'focus_start';
  static const String _focusElapsedKey = 'focus_elapsed';

  @override
  void initState() {
    super.initState();
    _restoreFocusState();
    _loadWeeklyFocusData();
  }

  Future<void> _restoreFocusState() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(_focusActiveKey) ?? false;
    if (active) {
      final startMillis = prefs.getInt(_focusStartKey);
      final elapsed = prefs.getInt(_focusElapsedKey) ?? 0;
      if (startMillis != null) {
        focusStartTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
        final now = DateTime.now();
        final diff = now.difference(focusStartTime!).inSeconds + elapsed;
        if (diff < totalSeconds) {
          setState(() {
            isFocusing = true;
            elapsedSeconds = diff;
          });
          _startTimer();
        } else {
          // Сессия истекла
          await _clearFocusState();
        }
      }
    }
  }

  Future<void> _saveFocusState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusActiveKey, isFocusing);
    await prefs.setInt(_focusElapsedKey, elapsedSeconds);
    if (focusStartTime != null) {
      await prefs.setInt(_focusStartKey, focusStartTime!.millisecondsSinceEpoch);
    }
  }

  Future<void> _clearFocusState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_focusActiveKey);
    await prefs.remove(_focusStartKey);
    await prefs.remove(_focusElapsedKey);
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (elapsedSeconds < totalSeconds) {
        setState(() {
          elapsedSeconds++;
        });
        _saveFocusState();
      } else {
        stopFocus();
      }
    });
  }

  void startFocus() async {
    focusStartTime = DateTime.now();
    setState(() {
      isFocusing = true;
      elapsedSeconds = 0;
    });
    await _saveFocusState();
    _startTimer();
    // Включаем DND
    await _enableDND();
  }

  Future<void> stopFocus() async {
    timer?.cancel();
    setState(() {
      isFocusing = false;
      elapsedSeconds = 0;
      focusStartTime = null;
    });
    await _clearFocusState();
    // Выключаем DND
    await _disableDND();
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
        
        // Локально обновляем график мгновенно
        final weekDayIndex = now.weekday - 1; // 0 - Monday, 6 - Sunday
        setState(() {
          focusData[weekDayIndex] += duration / 3600;
        });

        // Показываем уведомление об успехе
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Сохранено: ${duration ~/ 60} минут фокусировки'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _enableDND() async {
    try {
      final isGranted = await FlutterDnd.isNotificationPolicyAccessGranted;
      if (isGranted == false) {
        FlutterDnd.gotoPolicySettings();
      }
      await FlutterDnd.setInterruptionFilter(FlutterDnd.INTERRUPTION_FILTER_NONE);
    } catch (e) {
      debugPrint('DND enable error: $e');
    }
  }

  Future<void> _disableDND() async {
    try {
      await FlutterDnd.setInterruptionFilter(FlutterDnd.INTERRUPTION_FILTER_ALL);
    } catch (e) {
      debugPrint('DND disable error: $e');
    }
  }

  Future<void> _loadWeeklyFocusData() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection("focus_sessions")
              .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where("date", isEqualTo: dateStr)
              .get();

          print('date: $dateStr, docs: ' + snapshot.docs.map((d) => d.data().toString()).join(", "));

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
      // debug print for all week
      List<int> focusMinutes = focusData.map((h) => (h * 60).round()).toList();
      print('focusData (hours): ' + focusData.toString());
      print('focusMinutes: ' + focusMinutes.toString());
    } catch (e) {
      print('Error in _loadWeeklyFocusData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось загрузить данные фокус-режима'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Color getTextColor() {
    return elapsedSeconds >= (totalSeconds * 0.5) ? Colors.black : Colors.grey;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = elapsedSeconds / totalSeconds;
    return Column(
      children: [
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
        ElevatedButton(
          onPressed: isFocusing ? stopFocus : startFocus,
          style: ElevatedButton.styleFrom(
            backgroundColor: isFocusing ? Colors.red : Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      ],
    );
  }
}
