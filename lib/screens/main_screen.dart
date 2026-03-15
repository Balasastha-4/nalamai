import 'package:flutter/material.dart';
import 'package:nalamai/screens/chat_screen.dart';
import 'package:nalamai/screens/health_screen.dart';
import 'package:nalamai/screens/home_screen.dart';
import 'package:nalamai/screens/reports_screen.dart';
import 'package:nalamai/screens/scanner_screen.dart';
import 'package:nalamai/theme/app_theme.dart';
import 'package:nalamai/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Key _reportsKey = UniqueKey();

  void _onItemTapped(int index) {
    if (index == 3) {
      // Option A: Push ChatScreen as a full-screen page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
        if (index == 4) {
          _reportsKey = UniqueKey();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const HealthScreen(),
      const ScannerScreen(), // Centered placeholder, effectively
      const ChatScreen(),
      ReportsScreen(key: _reportsKey),
    ];

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Keep FAB stationary (ChatScreen handles keyboard manually)
      appBar: AppBar(
        title: const Text('Smart Healthcare'),
        actions: [
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.secondaryTeal,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: screens[_selectedIndex],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).cardColor,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Dash',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.monitor_heart_outlined,
                label: 'Health',
                index: 1,
              ),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.description_outlined,
                label: 'Reports',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : Theme.of(context).unselectedWidgetColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : Theme.of(context).unselectedWidgetColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
