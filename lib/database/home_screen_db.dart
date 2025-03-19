import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreenDB extends StatelessWidget {
  const HomeScreenDB({super.key});

  BuildContext? get context => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Мои задачи")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tasks")
            .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy("time", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Нет задач"));
          }

          var tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];
              var category = task["category"] ?? "Без категории";

              return ListTile(
                leading: Icon(Icons.category, color: Colors.white),
                title: Text(task["title"]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task["description"]),
                    Text(
                      task["time"] != null && task["time"] is Timestamp
                          ? DateFormat("d MMM yyyy, HH:mm").format(
                              (task["time"] as Timestamp).toDate().toLocal())
                          : "No time set",
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                    Text("Приоритет: ${task["priority"]}"),
                    Text("Категория: ${task["category"] ?? "Без категории"}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent)),
                  ],
                ),
                trailing: Checkbox(
                  value: task["completed"],
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection("tasks")
                        .doc(task.id)
                        .update({"completed": value});
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddTaskModal(context);
        },
      ),
    );
  }

  void addTask(String title, String description, int priority,
      DateTime? selectedTime, String category) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(content: Text("Введите название задачи")),
      );
      return;
    }

    if (selectedTime == null) {
      print("❌ ОШИБКА: selectedTime = null");
      return;
    }

    print("Попытка добавить задачу...");
    print("DEBUG: title = '$title'");
    print("DEBUG: description = '$description'");
    print("DEBUG: priority = $priority");
    print("DEBUG: category = '$category'");
    print("DEBUG: selectedTime (локальное) = $selectedTime");
    print("DEBUG: selectedTime (UTC) = ${selectedTime.toUtc()}");

    try {
      await FirebaseFirestore.instance.collection("tasks").add({
        "title": title,
        "description": description,
        "time": Timestamp.fromDate(selectedTime.toUtc()),
        "priority": priority,
        "completed": false,
        "category": category,
        "userId": FirebaseAuth.instance.currentUser?.uid,
      });

      print("✅ Задача успешно добавлена!");
    } catch (e) {
      print("❌ Ошибка при добавлении задачи: $e");
    }
  }

  void _showAddTaskModal(BuildContext context) {
    TextEditingController taskController = TextEditingController();
    TextEditingController descController = TextEditingController();
    TextEditingController priorityController = TextEditingController();
    DateTime selectedTime = DateTime.now();
    String selectedCategory = "Без категории";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      hintText: "Task Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      hintText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: priorityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Priority (1-10)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Выбранное время: ${DateFormat("d MMM yyyy, HH:mm").format(selectedTime)}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedTime),
                        );

                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text("Выбрать время"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      String category = await _showCategoryDialog(context);
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Text("Выбрать категорию"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      int? priority = int.tryParse(priorityController.text);
                      if (priority == null || priority < 1 || priority > 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Введите число от 1 до 10")),
                        );
                        return;
                      }
                      addTask(taskController.text, descController.text,
                          priority, selectedTime, selectedCategory);
                      Navigator.pop(context);
                    },
                    child: Text("Добавить задачу"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _showCategoryDialog(BuildContext context) async {
    List<String> categories = ["Работа", "Личное", "Учеба", "Спорт", "Другое"];
    String selectedCategory = "Без категории";

    return await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Выберите категорию"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: categories
                    .map((category) => ListTile(
                          title: Text(category),
                          onTap: () {
                            Navigator.pop(context, category);
                          },
                        ))
                    .toList(),
              ),
            );
          },
        ) ??
        selectedCategory;
  }
}
