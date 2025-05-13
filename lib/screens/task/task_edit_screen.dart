import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskEditScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const TaskEditScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDateTime;
  String? _selectedCategory;
  int? _selectedPriority;

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
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskData['title']);
    _descriptionController = TextEditingController(text: widget.taskData['description'] ?? '');
    _selectedDateTime = (widget.taskData['time'] as Timestamp?)?.toDate();
    _selectedCategory = widget.taskData['category'];
    _selectedPriority = widget.taskData['priority'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              "Select Category",
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
                        color: Colors.white,
                      ),
                    ),
                    const Divider(color: Colors.white24),
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
                              boxShadow: const [
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
                                Icon(
                                  Icons.flag,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$priority",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
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
                            foregroundColor: Colors.white,
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

  Future<void> _updateTask() async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'time': _selectedDateTime != null ? Timestamp.fromDate(_selectedDateTime!) : null,
        'category': _selectedCategory,
        'priority': _selectedPriority,
      });
      
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating task')),
      );
    }
  }

  Future<void> _deleteTask() async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .delete();
      
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // Включить режим редактирования
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _titleController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () {
                    // Редактировать заголовок
                  },
                ),
              ],
            ),
            if (_descriptionController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 8),
                child: Text(
                  _descriptionController.text,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.access_time,
              title: 'Task Time:',
              value: _selectedDateTime != null 
                ? widget.taskData['hasTime'] == true
                    ? 'Today at ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                    : '${_selectedDateTime!.day.toString().padLeft(2, '0')}.${_selectedDateTime!.month.toString().padLeft(2, '0')}.${_selectedDateTime!.year}'
                : 'Not set',
            ),
            _buildOptionTile(
              icon: Icons.category,
              title: 'Category:',
              value: _selectedCategory ?? 'No category',
            ),
            _buildOptionTile(
              icon: Icons.flag,
              title: 'Priority:',
              value: _selectedPriority?.toString() ?? 'Default',
            ),
            _buildOptionTile(
              icon: Icons.subtitles,
              title: 'Subtask',
              value: 'Add subtask',
            ),
            const Spacer(),
            _buildDeleteButton(),
            const SizedBox(height: 16),
            _buildEditButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _deleteTask,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 16),
            Text(
              'Delete Task',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Edit Task',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}