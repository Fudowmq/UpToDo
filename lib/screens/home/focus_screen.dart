import 'package:flutter/material.dart';
import 'package:uptodo/screens/home/calendar_screen.dart';
import 'package:uptodo/screens/home/home_screen.dart';
import 'package:uptodo/screens/home/profile_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
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

  @override
  Widget build(BuildContext context) {
    final apps = [
      {'name': 'Instagram', 'time': '4h', 'icon': Icons.camera_alt},
      {'name': 'Twitter', 'time': '3h', 'icon': Icons.alternate_email},
      {'name': 'Facebook', 'time': '3h', 'icon': Icons.facebook},
      {'name': 'Telegram', 'time': '3h', 'icon': Icons.send},
      {'name': 'Gmail', 'time': '45min', 'icon': Icons.email},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Focus Mode',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey,
                      child: Text(
                        "00:00",
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "While your focus mode is on, all of your\nnotifications will be off",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text("Start Focusing"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Overview",
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                  Text(
                    "This Week",
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 100,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Text(
                  "Chart Placeholder",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Applications",
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return Card(
                      color: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(app['icon'] as IconData,
                            color: Colors.black87),
                        title: Text(app['name'] as String,
                            style: const TextStyle(color: Colors.black)),
                        subtitle: Text(
                          "You spent ${app['time']} on ${app['name']} today",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Colors.black38, size: 16),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
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
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }),
            _buildNavItem("assets/image/calendar_icon.png", "Calendar", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
            }),
            const SizedBox(width: 48),
            _buildNavItem("assets/image/clock_icon.png", "Focus", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const FocusScreen()));
            }),
            _buildNavItem("assets/image/profile_icon.png", "Profile", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
          ],
        ),
      ),
    );
  }
}
