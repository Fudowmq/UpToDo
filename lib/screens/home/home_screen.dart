import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uptodo/screens/home/calendar_screen.dart';
import 'package:uptodo/screens/home/focus_screen.dart';
import 'package:uptodo/screens/home/profile_screen.dart';
import 'package:uptodo/widgets/add_task_widget.dart';

enum TaskFilter { today, tomorrow, week }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TaskFilter _selectedFilter = TaskFilter.today;
  int _selectedIndex = 0;
  final List<String> _labels = ["Home", "Calendar", "Focus", "Profile"];

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case TaskFilter.today:
        return DateTime(now.year, now.month, now.day);
      case TaskFilter.tomorrow:
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      case TaskFilter.week:
        final weekday = now.weekday;
        final startOfWeek = now.subtract(Duration(days: weekday - 1));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case TaskFilter.today:
        return DateTime(now.year, now.month, now.day + 1);
      case TaskFilter.tomorrow:
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 1);
      case TaskFilter.week:
        final weekday = now.weekday;
        final endOfWeek = now.add(Duration(days: 7 - weekday + 1));
        return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
    }
  }

  String get _filterLabel {
    switch (_selectedFilter) {
      case TaskFilter.today:
        return 'Today';
      case TaskFilter.tomorrow:
        return 'Tomorrow';
      case TaskFilter.week:
        return 'This week';
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CalendarScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FocusScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Index",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage("assets/image/avatar_icon_profile.png"),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтр слева сверху
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Material(
                elevation: 4,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: null, // Не нужен, т.к. DropdownButton сам обрабатывает
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaskFilter>(
                        value: _selectedFilter,
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                        borderRadius: BorderRadius.circular(16),
                        isDense: true,
                        itemHeight: 48,
                        items: [
                          DropdownMenuItem(
                            value: TaskFilter.today,
                            child: _selectedFilter == TaskFilter.today
                                ? Row(children: [Icon(Icons.today, color: Colors.blueAccent, size: 22), SizedBox(width: 8), Text('Today', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))])
                                : Row(children: [Icon(Icons.today, color: Colors.white, size: 22), SizedBox(width: 8), Text('Today')]),
                          ),
                          DropdownMenuItem(
                            value: TaskFilter.tomorrow,
                            child: _selectedFilter == TaskFilter.tomorrow
                                ? Row(children: [Icon(Icons.calendar_today, color: Colors.greenAccent, size: 22), SizedBox(width: 8), Text('Tomorrow', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))])
                                : Row(children: [Icon(Icons.calendar_today, color: Colors.white, size: 22), SizedBox(width: 8), Text('Tomorrow')]),
                          ),
                          DropdownMenuItem(
                            value: TaskFilter.week,
                            child: _selectedFilter == TaskFilter.week
                                ? Row(children: [Icon(Icons.date_range, color: Colors.amberAccent, size: 22), SizedBox(width: 8), Text('This week', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))])
                                : Row(children: [Icon(Icons.date_range, color: Colors.white, size: 22), SizedBox(width: 8), Text('This week')]),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedFilter = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("tasks")
                  .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where("time", isGreaterThanOrEqualTo: _startDate)
                  .where("time", isLessThan: _endDate)
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 150),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset("assets/image/home_screen_image.png",
                              height: 300),
                          const SizedBox(height: 0),
                          const Text(
                            "What do you want to do today?",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Tap + to add your tasks",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var tasks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];

                    return Stack(
                      children: [
                        if (task["completed"] == true)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        Opacity(
                          opacity: task["completed"] == true ? 0.6 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                            child: Dismissible(
                              key: Key(task.id),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) {
                                FirebaseFirestore.instance
                                    .collection("tasks")
                                    .doc(task.id)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Task '${task["title"]}' deleted")),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              FirebaseFirestore.instance
                                                  .collection("tasks")
                                                  .doc(task.id)
                                                  .update({"completed": !(task["completed"] ?? false)});
                                            },
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: task["completed"] == true ? Colors.blueAccent : Colors.transparent,
                                                border: Border.all(
                                                    color: task["completed"] == true ? Colors.blueAccent : Colors.white, width: 2),
                                              ),
                                              child: task["completed"] == true
                                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              task["title"],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: task["completed"] == true ? Colors.grey[400] : Colors.white,
                                                decoration: task["completed"] == true ? TextDecoration.lineThrough : null,
                                                shadows: task["completed"] == true
                                                    ? [Shadow(color: Colors.black26, blurRadius: 2)]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        task["time"] != null
                                            ? formatDateTime(
                                                task["time"].toDate().toLocal(), context)
                                            : "No time set",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[400]),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: task["category"] == "Music"
                                                  ? Colors.purpleAccent
                                                  : task["category"] == "Movie"
                                                      ? Colors.lightBlueAccent
                                                      : task["category"] == "Work"
                                                          ? Colors.orangeAccent
                                                          : task["category"] == "Sport"
                                                              ? Colors.lightGreenAccent
                                                              : task["category"] == "Design"
                                                                  ? Colors.cyanAccent
                                                                  : task["category"] ==
                                                                          "University"
                                                                      ? Colors.blueAccent
                                                                      : task["category"] ==
                                                                              "Social"
                                                                          ? Colors
                                                                              .pinkAccent
                                                                          : task["category"] ==
                                                                                  "Health"
                                                                              ? Colors
                                                                                  .tealAccent
                                                                              : task["category"] ==
                                                                                      "Home"
                                                                                  ? Colors
                                                                                      .amberAccent
                                                                                  : task["category"] ==
                                                                                          "Grocery"
                                                                                      ? Colors
                                                                                          .greenAccent
                                                                                      : Colors
                                                                                          .grey,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.school,
                                                    color: Colors.white, size: 16),
                                                const SizedBox(width: 5),
                                                Text(task["category"] ?? "No category",
                                                    style: TextStyle(color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[700]!),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.flag,
                                                    color: Colors.grey[400], size: 16),
                                                const SizedBox(width: 5),
                                                Text("${task["priority"]}",
                                                    style:
                                                        TextStyle(color: Colors.grey[400])),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
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
                  // Остаёмся на текущем экране
                }, true),
                _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarScreen()),
                  );
                }, false),
                const SizedBox(width: 48),
                _buildNavItem("assets/image/clock_icon.png", "Focus", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FocusScreen()),
                  );
                }, false),
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

  String formatDateTime(DateTime dateTime, BuildContext context) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateString;
    if (taskDate == today) {
      dateString = "Today";
    } else if (taskDate == tomorrow) {
      dateString = "Tomorrow";
    } else {
      dateString = "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}";
    }

    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String timeString = "$hour:$minute";
    
    return "$dateString at $timeString";
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case "Music":
        return Colors.purpleAccent;
      case "Movie":
        return Colors.lightBlueAccent;
      case "Work":
        return Colors.orangeAccent;
      case "Sport":
        return Colors.lightGreenAccent;
      case "Design":
        return Colors.cyanAccent;
      case "University":
        return Colors.blueAccent;
      case "Social":
        return Colors.pinkAccent;
      case "Health":
        return Colors.tealAccent;
      case "Home":
        return Colors.amberAccent;
      case "Grocery":
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case "Music":
        return Icons.music_note;
      case "Movie":
        return Icons.movie;
      case "Work":
        return Icons.work;
      case "Sport":
        return Icons.sports;
      case "Design":
        return Icons.design_services;
      case "University":
        return Icons.school;
      case "Social":
        return Icons.people;
      case "Health":
        return Icons.favorite;
      case "Home":
        return Icons.home;
      case "Grocery":
        return Icons.local_grocery_store;
      default:
        return Icons.category;
    }
  }

  Color _priorityColor(dynamic priority) {
    switch (priority) {
      case 1:
        return Colors.greenAccent;
      case 2:
        return Colors.lightBlueAccent;
      case 3:
        return Colors.amberAccent;
      case 4:
        return Colors.orangeAccent;
      case 5:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
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
