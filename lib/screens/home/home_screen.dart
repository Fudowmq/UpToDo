import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedPriority;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {
      "name": "Grocery",
      "icon": Icons.local_grocery_store,
      "color": Colors.greenAccent
    },
    {"name": "Work", "icon": Icons.work, "color": Colors.orangeAccent},
    {"name": "Sport", "icon": Icons.sports, "color": Colors.lightGreenAccent},
    {
      "name": "Design",
      "icon": Icons.design_services,
      "color": Colors.cyanAccent
    },
    {"name": "University", "icon": Icons.school, "color": Colors.blueAccent},
    {"name": "Social", "icon": Icons.people, "color": Colors.pinkAccent},
    {"name": "Music", "icon": Icons.music_note, "color": Colors.purpleAccent},
    {"name": "Health", "icon": Icons.favorite, "color": Colors.tealAccent},
    {"name": "Movie", "icon": Icons.movie, "color": Colors.lightBlueAccent},
    {"name": "Home", "icon": Icons.home, "color": Colors.amberAccent},
    {"name": "Create New", "icon": Icons.add, "color": Colors.white70},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Index", style: TextStyle(color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: AssetImage("assets/image/avatar.png"),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tasks")
            .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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

          String formatDateTime(DateTime dateTime, BuildContext context) {
            DateTime now = DateTime.now();
            DateTime today = DateTime(now.year, now.month, now.day);
            DateTime tomorrow = today.add(const Duration(days: 1));
            DateTime taskDate =
                DateTime(dateTime.year, dateTime.month, dateTime.day);

            String dateString;
            if (taskDate == today) {
              dateString = "Today";
            } else if (taskDate == tomorrow) {
              dateString = "Tomorrow";
            } else {
              dateString = "${dateTime.day}.${dateTime.month}.${dateTime.year}";
            }

            String timeString =
                TimeOfDay.fromDateTime(dateTime).format(context);
            return "$dateString в $timeString";
          }

          var tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                child: Dismissible(
                  key: Key(task.id), // Уникальный ключ для анимации удаления
                  direction: DismissDirection
                      .startToEnd, // Проведение влево для удаления
                  onDismissed: (direction) {
                    FirebaseFirestore.instance
                        .collection("tasks")
                        .doc(task.id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Задача '${task["title"]}' удалена")),
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
                          // Верхняя строка (чекбокс + название)
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  FirebaseFirestore.instance
                                      .collection("tasks")
                                      .doc(task.id)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Задача '${task["title"]}' выполнена и удалена")),
                                  );
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  task["title"],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          // Время выполнения
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
                                                                              .grey, // Цвет по умолчанию
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.school,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 5),
                                    Text(task["category"] ?? "Без категории",
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),

                              // Приоритет (флажок)
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddTaskModal(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem("assets/image/home_icon.png", "Index", () {}),
            _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {}),
            const SizedBox(width: 48), // Отступ под FloatingActionButton
            _buildNavItem("assets/image/clock_icon.png", "Focus", () {}),
            _buildNavItem("assets/image/profile_icon.png", "Profile", () {}),
          ],
        ),
      ),
    );
  }


  Widget _buildNavItem(String iconPath, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8), // Округление
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 24, height: 24), // Кастомная иконка
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }


  void _showAddTaskModal(BuildContext context) {
    TextEditingController taskController = TextEditingController();
    TextEditingController descController = TextEditingController();

    DateTime? selectedDateTime; // Добавляем переменную

    void pickDateTime(BuildContext context) async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );

      if (pickedDate != null) {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          print("Выбрано время: $selectedDateTime"); // Отладка
        }
      }
    }

    void addTask() async {
      String title = taskController.text.trim();
      String description = descController.text.trim();

      if (title.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Введите название задачи")));
        return;
      }

      try {
        await FirebaseFirestore.instance.collection("tasks").add({
          "title": title,
          "description": description,
          "time": selectedDateTime != null
              ? Timestamp.fromDate(selectedDateTime!)
              : null,
          "priority": _selectedPriority,
          "completed": false,
          "category": _selectedCategory ??
              "Без категории", // Устанавливаем "Без категории", если null
          "userId": FirebaseAuth.instance.currentUser?.uid,
        });

        // ignore: empty_catches
      } catch (e) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Task",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taskController,
                decoration: InputDecoration(
                  hintText: "Task Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  hintText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Раздвигаем элементы
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 0), // Минимальный отступ слева
                    child: Row(
                      // Группа иконок слева
                      children: [
                        IconButton(
                          icon: const Icon(Icons.timer),
                          onPressed: () {
                            pickDateTime(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.label),
                          onPressed: () {
                            _showCategoryDialog(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.flag),
                          onPressed: () {
                            _showPriorityDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: addTask,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text(
              "Choose Category",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(_categories.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = _categories[index]["name"];
                      print("Выбрана категория: $_selectedCategory"); // DEBUG
                    });

                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _categories[index]["color"],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _categories[index]["icon"],
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _categories[index]["name"],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPriorityDialog(BuildContext context) {
    int? tempSelectedPriority = _selectedPriority;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor:
                  const Color.fromARGB(255, 55, 55, 55), // Светлый фон
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Task Priority",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 столбца
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2, // Отношение сторон
                      ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        int priority = index + 1;
                        bool isSelected = tempSelectedPriority == priority;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              tempSelectedPriority = priority;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : const Color.fromARGB(255, 110, 108, 108),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/image/flag.png",
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.flag,
                                        color: Colors.red);
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$priority",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (tempSelectedPriority != null) {
                              setState(() {
                                _selectedPriority =
                                    tempSelectedPriority; // Обновляем значение
                              });
                            }
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
