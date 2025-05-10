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
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String text, VoidCallback onTap, {Color? iconColor}) {
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
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/image/avatar_icon_profile.png'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your name',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("10 Task left", style: TextStyle(color: Colors.black)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("5 Task done", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Settings", style: TextStyle(fontSize: 14, color: Colors.black)),
            ),
            _buildProfileOption(Icons.settings, "App Settings", () {}),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Account", style: TextStyle(fontSize: 14, color: Colors.black)),
            ),
            _buildProfileOption(Icons.person, "Change account name", () {}),
            _buildProfileOption(Icons.lock, "Change account password", () {}),
            _buildProfileOption(Icons.image, "Change account Image", () {}),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Uptodo", style: TextStyle(fontSize: 14, color: Colors.black)),
            ),
            _buildProfileOption(Icons.info_outline, "About US", () {}),
            _buildProfileOption(Icons.help_outline, "FAQ", () {}),
            _buildProfileOption(Icons.feedback_outlined, "Help & Feedback", () {}),
            _buildProfileOption(Icons.favorite_outline, "Support US", () {}),
            _buildProfileOption(Icons.logout, "Log out", () {}, iconColor: Colors.red),
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }),
            _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
            }),
            const SizedBox(width: 48),
            _buildNavItem("assets/image/clock_icon.png", "Focus", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusScreen()));
            }),
            _buildNavItem("assets/image/profile_icon.png", "Profile", () {}),
          ],
        ),
      ),
    );
  }
}
