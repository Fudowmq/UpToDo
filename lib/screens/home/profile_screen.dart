import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  String _userName = 'Enter your name';

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
        });
      }
    } catch (e) {
      _showDialog('Error', 'Failed to pick image: $e');
    }
  }

  void _changeName() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                await user?.updateDisplayName(newName);

                // Обновление локального состояния
                setState(() {
                  _userName = newName;
                });
              }
              Navigator.pop(context);
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
                  // Реаутентификация
                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: oldPassword,
                  );

                  await user!.reauthenticateWithCredential(credential);

                  // Смена пароля
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

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
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

  Widget _buildProfileOption(IconData icon, String text, VoidCallback onTap,
      {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : const AssetImage('assets/image/avatar_icon_profile.png')
                        as ImageProvider,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _userName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("0 Task left",
                      style: TextStyle(color: Colors.black)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("0 Task done",
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Settings",
                  style: TextStyle(fontSize: 14, color: Colors.black)),
            ),
            _buildProfileOption(Icons.settings, "App Settings", () {
              _showDialog(
                  "App Settings", "Настройки приложения пока недоступны.");
            }),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Account",
                  style: TextStyle(fontSize: 14, color: Colors.black)),
            ),
            _buildProfileOption(
                Icons.person, "Change account name", _changeName),
            _buildProfileOption(
                Icons.lock, "Change account password", _changePassword),
            _buildProfileOption(
                Icons.image, "Change account Image", _pickImage),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Uptodo",
                  style: TextStyle(fontSize: 14, color: Colors.black)),
            ),
            _buildProfileOption(Icons.info_outline, "About US", () {
              _showDialog("About Us",
                  "Это приложение создано для управления вашими задачами.");
            }),
            _buildProfileOption(Icons.help_outline, "FAQ", () {
              _showDialog("FAQ",
                  "1. Как использовать?\n2. Как создать задачу?\n3. Как включить фокус-режим?");
            }),
            _buildProfileOption(Icons.feedback_outlined, "Help & Feedback", () {
              _showDialog("Help & Feedback",
                  "Для обратной связи напишите нам на uptodo@example.com");
            }),
            _buildProfileOption(Icons.favorite_outline, "Support US", () {
              _showDialog("Support Us",
                  "Поддержите нас, оставив отзыв в магазине приложений!");
            }),
            _buildProfileOption(Icons.logout, "Log out", _logout,
                iconColor: Colors.red),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem("assets/image/home_icon.png", "Home", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()));
            }),
            _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()));
            }),
            const SizedBox(width: 48),
            _buildNavItem("assets/image/clock_icon.png", "Focus", () {
              // Остаёмся на текущем экране
            }),
            _buildNavItem("assets/image/profile_icon.png", "Profile", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
          ],
        ),
      ),
    );
  }
}
