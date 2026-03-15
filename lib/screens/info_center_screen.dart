import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InfoCenterScreen extends StatelessWidget {
  const InfoCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Health Awareness'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Categories'),
            const SizedBox(height: 12),
            _buildCategories(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Featured Insights'),
            const SizedBox(height: 12),
            _buildFeaturedCard(
              context: context,
              title: 'Understanding Diabetes',
              description:
                  'Learn about Type 1 and Type 2 diabetes, symptoms, and management strategies.',
              icon: Icons.water_drop,
              color: Colors.blue.shade100,
              iconColor: Colors.blue,
            ),
            _buildFeaturedCard(
              context: context,
              title: 'Heart Health Tips',
              description:
                  'Simple lifestyle changes to keep your heart healthy and strong.',
              icon: Icons.favorite,
              color: Colors.red.shade100,
              iconColor: Colors.red,
            ),
            _buildFeaturedCard(
              context: context,
              title: 'Balanced Diet Guide',
              description:
                  'What does a balanced plate look like? tips for daily nutrition.',
              icon: Icons.restaurant,
              color: Colors.green.shade100,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 24),
            _buildEmergencySection(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search health topics...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = [
      {'icon': Icons.healing, 'label': 'Diseases', 'color': Colors.purple},
      {'icon': Icons.restaurant_menu, 'label': 'Diet', 'color': Colors.orange},
      {'icon': Icons.fitness_center, 'label': 'Exercise', 'color': Colors.blue},
      {
        'icon': Icons.health_and_safety,
        'label': 'Prevention',
        'color': Colors.teal,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withAlpha(26), // 0.1 opacity
                shape: BoxShape.circle,
              ),
              child: Icon(
                cat['icon'] as IconData,
                color: cat['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat['label'] as String,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8), // ~0.03 opacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Read More',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_in_talk, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency Help',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quick access to ambulance and contacts.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Placeholder for calling action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling Emergency Services...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text('Call 911'),
          ),
        ],
      ),
    );
  }
}
