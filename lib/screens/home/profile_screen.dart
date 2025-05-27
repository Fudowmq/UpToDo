import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'focus_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uptodo/widgets/add_task_widget.dart';
import 'package:uptodo/screens/auth/login_screen.dart';
import 'package:uptodo/services/language_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  String? _imageBase64;
  String _userName = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      _userName = _currentUser!.displayName!;
    }
    _loadUserName();
  }

  Future<void> _loadProfileImage() async {
    if (_currentUser != null) {
      try {
        final querySnapshot = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: _currentUser!.uid)
            .where('type', isEqualTo: 'profile')
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty && querySnapshot.docs.first.data()['imageBase64'] != null) {
          setState(() {
            _imageBase64 = querySnapshot.docs.first.data()['imageBase64'] as String;
          });
        }
      } catch (e) {
        print('Error loading profile image: $e');
      }
    }
  }

  Future<void> _loadUserName() async {
    if (_currentUser != null) {
      try {
        final querySnapshot = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: _currentUser.uid)
            .where('type', isEqualTo: 'profile')
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty && querySnapshot.docs.first.data()['name'] != null) {
          final firestoreName = querySnapshot.docs.first.data()['name'] as String;
          if (firestoreName.isNotEmpty) {
            setState(() {
              _userName = firestoreName;
            });
          }
        }
      } catch (e) {
        print('Error loading user name: $e');
      }
    }
  }

  Future<void> _updateUserName(String newName) async {
    if (_currentUser == null) {
      print('No user is logged in');
      throw Exception('No user is currently logged in');
    }

    try {
      print('Starting update process...');
      print('User ID: ${_currentUser.uid}');
      
      // Сначала обновляем в Auth
      await _currentUser.updateDisplayName(newName);
      print('Auth display name updated successfully');

      // Обновляем локальное состояние
      setState(() {
        _userName = newName;
      });
      print('Local state updated');

      // Ищем существующий профиль в коллекции tasks
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUser.uid)
          .where('type', isEqualTo: 'profile')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // Если профиль не существует, создаем новый
        await _firestore.collection('tasks').add({
          'userId': _currentUser.uid,
          'type': 'profile',
          'name': newName,
          'email': _currentUser.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Created new profile document');
      } else {
        // Если профиль существует, обновляем его
        await _firestore.collection('tasks').doc(querySnapshot.docs.first.id).update({
          'name': newName,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('Updated existing profile document');
      }

      print('Update completed successfully');
      
      // Показываем сообщение об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('Error in _updateUserName: $e');
      print('Stack trace: ${StackTrace.current}');
      
      String errorMessage = 'Не удалось обновить имя';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Отказано в доступе. Попробуйте выйти и войти снова.';
      }
      
      // Показываем ошибку пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      rethrow;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 50,
      );

      if (pickedImage != null && _currentUser != null) {
        // Показываем индикатор загрузки
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }

        try {
          final file = File(pickedImage.path);
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);

          // Обновляем в Firestore
          final querySnapshot = await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: _currentUser!.uid)
              .where('type', isEqualTo: 'profile')
              .get();

          if (querySnapshot.docs.isEmpty) {
            await _firestore.collection('tasks').add({
              'userId': _currentUser!.uid,
              'type': 'profile',
              'imageBase64': base64Image,
              'name': _userName,
              'email': _currentUser!.email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else {
            await _firestore
                .collection('tasks')
                .doc(querySnapshot.docs.first.id)
                .update({
              'imageBase64': base64Image,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }

          setState(() {
            _image = file;
            _imageBase64 = base64Image;
          });

          // Закрываем индикатор загрузки
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Фото профиля обновлено'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (error) {
          print('Error saving image: $error');
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось сохранить фото. Попробуйте другое изображение'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Picker error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось выбрать фото. Попробуйте еще раз'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _changeName() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      barrierDismissible: false,  // Предотвращаем закрытие диалога по нажатию вне него
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(  // Используем отдельный контекст диалога
        title: const Text("Change Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new name"),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _updateUserName(value.trim()).then((_) {
                Navigator.of(dialogContext).pop();  // Используем контекст диалога
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),  // Используем контекст диалога
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                _updateUserName(newName).then((_) {
                  Navigator.of(dialogContext).pop();  // Используем контекст диалога
                }).catchError((error) {
                  print('Error in _changeName: $error');
                  _showDialog('Error', 'Failed to update name: $error');
                });
              } else {
                _showDialog('Error', 'Please enter a name');
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Enter old password"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Enter new password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final email = user?.email;
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();

              if (email != null &&
                  oldPassword.isNotEmpty &&
                  newPassword.length >= 6) {
                try {
                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: oldPassword,
                  );

                  await user!.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPassword);

                  Navigator.pop(context);
                  _showDialog("Success", "Password changed successfully.");
                } catch (e) {
                  Navigator.pop(context);
                  _showDialog(
                      "Error", "Failed to change password: ${e.toString()}");
                }
              } else {
                Navigator.pop(context);
                _showDialog("Error",
                    "Please enter valid old and new passwords (min 6 chars).");
              }
            },
            child: const Text("Save"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // ignore: use_build_context_synchronously
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Удаляем все предыдущие экраны из стека
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при выходе из системы'),
          backgroundColor: Colors.red,
        ),
      );
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

  Widget _buildProfileOption(
    IconData icon,
    String text,
    VoidCallback onTap, {
    Color? iconColor,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.black),
      onTap: onTap,
    );
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.task_alt, size: 40, color: Colors.blue.shade700),
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome to UpTodo!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your personal task management and productivity app. We help you to stay organized and perform your tasks more efficiently.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Frequently Asked Questions",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildFAQItem(
                "How to create a new task?",
                "Tap the + button at the bottom of the screen and fill in the task details.",
              ),
              const Divider(),
              _buildFAQItem(
                "How to mark task as complete?",
                "Simply tap the checkbox next to any task to mark it as complete.",
              ),
              const Divider(),
              _buildFAQItem(
                "How to use Focus Mode?",
                "Go to Focus tab and select the duration you want to stay focused.",
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it!"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _showHelpAndFeedbackDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Help & Feedback",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildHelpOption(
                Icons.email,
                "Contact Support",
                "support@uptodo.com",
              ),
              const SizedBox(height: 16),
              _buildHelpOption(
                Icons.bug_report,
                "Report a Bug",
                "Let us know if you found any issues",
              ),
              const SizedBox(height: 16),
              _buildHelpOption(
                Icons.star,
                "Rate Us",
                "Share your experience",
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpOption(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        // Здесь можно добавить соответствующие действия для каждой опции
      },
    );
  }

  void _showSupportUsDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite, size: 40, color: Colors.blue.shade700),
              ),
              const SizedBox(height: 24),
              const Text(
                "Support UpTodo",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "If you love our app, please take a moment to rate us on the store!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 32,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Maybe Later"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCurrentLanguage() async {
    final language = await LanguageService.getCurrentLanguage();
    setState(() {
      _currentLanguage = language;
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Language",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                'English',
                'en',
                'assets/image/en_flag.png',
              ),
              const SizedBox(height: 8),
              _buildLanguageOption(
                'Русский',
                'ru',
                'assets/image/ru_flag.png',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String name, String code, String flagPath) {
    final isSelected = _currentLanguage == code;
    
    return InkWell(
      onTap: () async {
        await LanguageService.setLanguage(code);
        setState(() {
          _currentLanguage = code;
        });
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.black45,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.asset(
                flagPath,
                width: 20,
                height: 14,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStats(AsyncSnapshot<QuerySnapshot> tasksSnapshot) {
    int tasksLeft = 0;
    int tasksDone = 0;

    if (tasksSnapshot.hasData) {
      for (var doc in tasksSnapshot.data!.docs) {
        // Получаем данные документа безопасным способом
        final data = doc.data() as Map<String, dynamic>;
        // Пропускаем документы профиля
        if (data.containsKey('type') && data['type'] == 'profile') continue;
        
        // Проверяем статус выполнения задачи
        if (data.containsKey('completed') && data['completed'] == true) {
          tasksDone++;
        } else {
          tasksLeft++;
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$tasksLeft tasks left",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$tasksDone tasks done",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasks')
            .where('userId', isEqualTo: _currentUser?.uid)
            .snapshots(),
        builder: (context, tasksSnapshot) {
          // Получаем данные профиля
          String? currentImageBase64;
          if (tasksSnapshot.hasData) {
            for (var doc in tasksSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('type') && data['type'] == 'profile' && data.containsKey('imageBase64')) {
                currentImageBase64 = data['imageBase64'] as String?;
                if (currentImageBase64 != null) {
                  _imageBase64 = currentImageBase64;
                }
                break;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageBase64 != null
                            ? MemoryImage(base64Decode(_imageBase64!))
                            : const AssetImage('assets/image/avatar_icon_profile.png') as ImageProvider,
                        child: _imageBase64 == null
                            ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _changeName,
                  child: Text(
                    _userName.isNotEmpty ? _userName : 'Enter your name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (tasksSnapshot.hasData) 
                  _buildTaskStats(tasksSnapshot)
                else 
                  const CircularProgressIndicator(),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Settings",
                      style: TextStyle(fontSize: 14, color: Colors.black)),
                ),
                _buildProfileOption(
                  Icons.language,
                  "Change Language",
                  _showLanguageDialog,
                ),
                _buildProfileOption(Icons.settings, "App Settings", () {
                  _showDialog(
                      "App Settings", "Настройки приложения пока недоступны.");
                }),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Account",
                      style: const TextStyle(fontSize: 14, color: Colors.black)),
                ),
                _buildProfileOption(
                    Icons.person,
                    "Change Account Name",
                    _changeName),
                _buildProfileOption(
                    Icons.lock,
                    "Change Account Password",
                    _changePassword),
                _buildProfileOption(
                    Icons.image,
                    "Change Account Image",
                    _pickImage),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("UpTodo",
                      style: const TextStyle(fontSize: 14, color: Colors.black)),
                ),
                _buildProfileOption(
                    Icons.info_outline,
                    "About Us",
                    _showAboutUsDialog),
                _buildProfileOption(
                    Icons.help_outline,
                    "FAQ",
                    _showFAQDialog),
                _buildProfileOption(
                    Icons.feedback_outlined,
                    "Help & Feedback",
                    _showHelpAndFeedbackDialog),
                _buildProfileOption(
                    Icons.favorite_outline,
                    "Support Us",
                    _showSupportUsDialog,
                    iconColor: Colors.red),
                _buildProfileOption(
                    Icons.logout,
                    "Logout",
                    _logout,
                    iconColor: Colors.red),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
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
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()));
                }, false),
                _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()));
                }, false),
                const SizedBox(width: 48),
                _buildNavItem("assets/image/clock_icon.png", "Focus", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FocusScreen()));
                }, false),
                _buildNavItem("assets/image/profile_icon.png", "Profile", () {
                  // Остаёмся на текущем экране
                }, true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
