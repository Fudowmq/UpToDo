import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'focus_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildNavItem(String iconPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black, // Чёрный цвет текста
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Белый фон
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Убирает стрелку "назад"
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/profile_avatar.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Name',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'User Info or Bio',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Логика выхода из аккаунта
              },
              child: const Text('Logout'),
            ),
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }),
            _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
            }),
            const SizedBox(width: 48),
            _buildNavItem("assets/image/clock_icon.png", "Focus", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusScreen()));
            }),
            _buildNavItem("assets/image/profile_icon.png", "Profile", () {
            }),
          ],
        ),
      ),
    );
  }
}
