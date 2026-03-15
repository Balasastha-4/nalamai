import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DoctorSearchDelegate extends SearchDelegate<String> {
  final List<String> recentSearches = [
    'Sarah Smith',
    'John Richardson',
    'Viral Fever',
    'Cardiology',
  ];

  final List<String> allData = [
    'Sarah Smith',
    'John Richardson',
    'Emily Chen',
    'Michael Brown',
    'William Taylor',
    'Emma Wilson',
    'Viral Fever',
    'Cardiology',
    'Orthopedics',
    'Dermatology',
    'Hypertension',
    'Allergic Dermatitis',
    'Ankle Sprain',
  ];

  @override
  String get searchFieldLabel => 'Search patients, ailments...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: theme.iconTheme,
        elevation: 0,
        titleSpacing: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 18),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: Theme.of(context).scaffoldBackgroundColor);
    }
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching patient or record for "$query"',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? recentSearches
        : allData
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          final isRecent = query.isEmpty;

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                isRecent ? Icons.history : Icons.search,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            title: Text(
              suggestion,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: isRecent
                ? Icon(
                    Icons.north_west,
                    size: 16,
                    color: Theme.of(context).dividerColor,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            onTap: () {
              query = suggestion;
              showResults(context);
            },
          );
        },
      ),
    );
  }
}
