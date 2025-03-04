import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreenDB extends StatelessWidget {
  const HomeScreenDB({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Мои задачи")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tasks")
            .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy("time")
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
              int priority = int.tryParse(task["priority"].toString()) ?? 1; 

              return ListTile(
                leading: Image.asset("assets/image/flag.png", width: 24, height: 24),
                title: Text(task["title"]),
                subtitle: Text(
                  "${task["description"]} | ${DateTime.parse(task["time"]).toLocal()} | Приоритет: $priority",
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

  void _showAddTaskModal(BuildContext context) {
    // Вызов функции добавления задачи
  }
}
