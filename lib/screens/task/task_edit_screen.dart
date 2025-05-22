import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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
  Timer? _debounce;
  bool _isEditingTitle = false;
  bool _isEditingDescription = false;

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
    _isEditingTitle = false;
    _isEditingDescription = false;

    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showDateTimePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final bool? useTimeAlso = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Add Time?',
              style: TextStyle(color: Colors.black),
            ),
            content: const Text(
              'Do you want to add specific time for this task?',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Date Only',
                  style: TextStyle(color: Colors.black87),
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
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
        );

        if (pickedTime != null) {
          setState(() {
            _selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            widget.taskData['hasTime'] = true;
          });
        }
      } else {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
          );
          widget.taskData['hasTime'] = false;
        });
      }
      
      _saveChanges();
    }
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              "Choose Category",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
                    _saveChanges();
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
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
              child: const Text(
                "Закрыть",
                style: TextStyle(color: Colors.white),
              ),
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task name cannot be empty')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'time': _selectedDateTime != null ? Timestamp.fromDate(_selectedDateTime!) : null,
        'category': _selectedCategory ?? 'Without a category',
        'priority': _selectedPriority ?? 0,
        'lastModified': Timestamp.now(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully')),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
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

  // Функция для автоматического сохранения изменений
  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'time': _selectedDateTime != null ? Timestamp.fromDate(_selectedDateTime!) : null,
        'hasTime': widget.taskData['hasTime'],
        'category': _selectedCategory ?? 'Without a category',
        'priority': _selectedPriority ?? 0,
        'lastModified': Timestamp.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  // Debounce для автосохранения при вводе текста
  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _saveChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 60,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                bool currentStatus = widget.taskData['completed'] ?? false;
                                widget.taskData['completed'] = !currentStatus;
                                FirebaseFirestore.instance
                                    .collection('tasks')
                                    .doc(widget.taskId)
                                    .update({'completed': !currentStatus});
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.taskData['completed'] == true ? Colors.blue : Colors.transparent,
                                border: Border.all(
                                  color: widget.taskData['completed'] == true ? Colors.blue : Colors.grey[400]!,
                                  width: 2
                                ),
                              ),
                              child: widget.taskData['completed'] == true
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: !_isEditingTitle
                                ? Text(
                                    _titleController.text,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      decoration: widget.taskData['completed'] == true
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.grey[400],
                                    ),
                                  )
                                : TextField(
                                    controller: _titleController,
                                    autofocus: true,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "Task Name",
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                    onSubmitted: (value) {
                                      setState(() {
                                        _isEditingTitle = false;
                                        _saveChanges();
                                      });
                                    },
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.grey[600],
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditingTitle = true;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isEditingDescription = true;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: !_isEditingDescription
                              ? Text(
                                  _descriptionController.text.isEmpty 
                                      ? "Add description" 
                                      : _descriptionController.text,
                                  style: TextStyle(
                                    color: _descriptionController.text.isEmpty 
                                        ? Colors.grey[500]
                                        : Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                )
                              : TextField(
                                  controller: _descriptionController,
                                  autofocus: true,
                                  maxLines: null,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Add description",
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      _isEditingDescription = false;
                                      _saveChanges();
                                    });
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildOptionTile(
                        icon: Icons.access_time_rounded,
                        title: 'Task Time',
                        value: _selectedDateTime != null 
                          ? widget.taskData['hasTime'] == true
                              ? 'Today at ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                              : '${_selectedDateTime!.day.toString().padLeft(2, '0')}.${_selectedDateTime!.month.toString().padLeft(2, '0')}.${_selectedDateTime!.year}'
                          : 'Not set',
                        onTap: () => _showDateTimePicker(),
                      ),
                      Divider(color: Colors.grey[200], height: 1),
                      _buildOptionTile(
                        icon: Icons.category_rounded,
                        title: 'Task Category',
                        value: _selectedCategory ?? 'Without a category',
                        onTap: () => _showCategoryDialog(context),
                      ),
                      Divider(color: Colors.grey[200], height: 1),
                      _buildOptionTile(
                        icon: Icons.flag_rounded,
                        title: 'Task Priority',
                        value: _selectedPriority?.toString() ?? '0',
                        onTap: () => _showPriorityDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Task?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _deleteTask();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete Task',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}