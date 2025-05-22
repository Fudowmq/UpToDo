import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskWidget extends StatefulWidget {
  const AddTaskWidget({super.key});

  @override
  State<AddTaskWidget> createState() => _AddTaskWidgetState();
}

class _AddTaskWidgetState extends State<AddTaskWidget> {
  int? _selectedPriority;
  String? _selectedCategory;
  DateTime? selectedDateTime;
  bool hasTime = false;
  final TextEditingController taskController = TextEditingController();
  final TextEditingController descController = TextEditingController();

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
  
  get addTask => null;

  void _showAddTaskModal(BuildContext context) {
    void pickDateTime(BuildContext context) async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );

      if (pickedDate != null) {
        final bool? useTimeAlso = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Add Time?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Do you want to add specific time for this task?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Date Only',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Add Time'),
                ),
              ],
            );
          },
        );

        if (useTimeAlso == true) {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  alwaysUse24HourFormat: true,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    timePickerTheme: TimePickerThemeData(
                      hourMinuteShape: const CircleBorder(),
                    ),
                  ),
                  child: child!,
                ),
              );
            },
          );

          if (pickedTime != null) {
            setState(() {
              selectedDateTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              hasTime = true;
            });
          }
        } else {
          setState(() {
            selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
            );
            hasTime = false;
          });
        }
      }
    }

    void addTask() async {
      String title = taskController.text.trim();
      String description = descController.text.trim();

      if (title.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Введите название задачи")));
        return;
      }

      try {
        await FirebaseFirestore.instance.collection("tasks").add({
          "title": title,
          "description": description,
          "time": selectedDateTime != null ? Timestamp.fromDate(selectedDateTime!) : null,
          "hasTime": hasTime,
          "priority": _selectedPriority,
          "completed": false,
          "category": _selectedCategory ?? "Without a category",
          "userId": FirebaseAuth.instance.currentUser?.uid,
        });
        Navigator.pop(context);
      } catch (e) {
        print("Error adding task: $e");
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: taskController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Task Name",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Description",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.timer, color: Colors.white),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );

                              if (pickedDate != null) {
                                final bool? useTimeAlso = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      title: const Text(
                                        'Add Time?',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'Do you want to add specific time for this task?',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text(
                                            'Date Only',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                          child: const Text('Add Time'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (useTimeAlso == true) {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder: (BuildContext context, Widget? child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true,
                                        ),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            timePickerTheme: TimePickerThemeData(
                                              hourMinuteShape: const CircleBorder(),
                                            ),
                                          ),
                                          child: child!,
                                        ),
                                      );
                                    },
                                  );

                                  if (pickedTime != null) {
                                    setState(() {
                                      selectedDateTime = DateTime(
                                        pickedDate.year,
                                        pickedDate.month,
                                        pickedDate.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );
                                      hasTime = true;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    selectedDateTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                    );
                                    hasTime = false;
                                  });
                                }
                              }
                            },
                          ),
                          selectedDateTime != null
                              ? Text(
                                  hasTime
                                      ? '${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}'
                                      : '${selectedDateTime!.day.toString().padLeft(2, '0')}.${selectedDateTime!.month.toString().padLeft(2, '0')}.${selectedDateTime!.year}',
                                  style: const TextStyle(color: Colors.grey),
                                )
                              : const SizedBox(),
                          IconButton(
                            icon: const Icon(Icons.label, color: Colors.white),
                            onPressed: () {
                              _showCategoryDialog(context);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.flag, color: Colors.white),
                            onPressed: () {
                              _showPriorityDialog(context);
                            },
                          ),
                        ],
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
      },
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        style: const TextStyle(color: Colors.white, fontSize: 12),
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
              backgroundColor: const Color.fromARGB(255, 55, 55, 55),
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
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
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
                                _selectedPriority = tempSelectedPriority;
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

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: Colors.blueAccent,
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        _showAddTaskModal(context);
      },
    );
  }
}
