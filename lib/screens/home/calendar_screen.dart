import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uptodo/screens/home/home_screen.dart';
import 'package:uptodo/screens/home/profile_screen.dart';
import 'focus_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Stream<List<Task>> _getTasksForDay(DateTime day) {
    return FirebaseFirestore.instance
        .collection("tasks")
        .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where("time",
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(day.year, day.month, day.day)))
        .where("time",
            isLessThan: Timestamp.fromDate(
                DateTime(day.year, day.month, day.day)
                    .add(const Duration(days: 1))))
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Task(
          doc["title"],
          doc["category"] ?? "Без категории",
          (doc["time"] as Timestamp).toDate(),
          doc["priority"] ?? "Низкий",
        );
      }).toList();
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay ?? _focusedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _getTasksForDay(_selectedDay ?? _focusedDay),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Нет задач на выбранный день"));
                }

                var tasks = snapshot.data!;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(task: task),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.radio_button_unchecked,
                                color: Colors.black),
                            const SizedBox(width: 10),
                            Text(
                              task.title,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem("assets/image/home_icon.png", "Home", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }),
            _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            }),
            const SizedBox(width: 48),
            _buildNavItem("assets/image/clock_icon.png", "Focus", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FocusScreen()),
              );
            }),
            _buildNavItem("assets/image/profile_icon.png", "Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String category;
  final DateTime time;
  final String priority;

  Task(this.title, this.category, this.time, this.priority);
}

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Приоритет: ${task.priority}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Категория: ${task.category}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
                'Дата и время: ${DateFormat('dd MMM yyyy, HH:mm').format(task.time)}',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить задачу'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text('Форма для добавления задачи'),
      ),
    );
  }
}
