import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'document_review_screen.dart';

class PendingReportsScreen extends StatelessWidget {
  const PendingReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Pending Reports'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          titleTextStyle: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          iconTheme: Theme.of(context).iconTheme,
          bottom: TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            indicatorColor: AppTheme.primaryBlue,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Critical'),
              Tab(text: 'Routine'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportsList(context, filter: 'All'),
            _buildReportsList(context, filter: 'High'),
            _buildReportsList(context, filter: 'Routine'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(BuildContext context, {required String filter}) {
    // Demo Data
    final allReports = [
      {
        'patient': 'John Doe',
        'title': 'Blood Analysis',
        'type': 'PDF',
        'date': 'Feb 07, 2026',
        'severity': 'High',
      },
      {
        'patient': 'Sarah Connor',
        'title': 'X-Ray Chest',
        'type': 'Image',
        'date': 'Feb 06, 2026',
        'severity': 'High',
      },
      {
        'patient': 'Mike Ross',
        'title': 'Annual Checkup',
        'type': 'PDF',
        'date': 'Feb 05, 2026',
        'severity': 'Routine',
      },
      {
        'patient': 'Harvey Specter',
        'title': 'MRI Scan',
        'type': 'Image',
        'date': 'Feb 04, 2026',
        'severity': 'Routine',
      },
    ];

    final filteredReports = filter == 'All'
        ? allReports
        : allReports.where((r) => r['severity'] == filter).toList();

    if (filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending reports',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredReports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        final isCritical = report['severity'] == 'High';

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withAlpha(20),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: isCritical
                ? Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCritical
                    ? Theme.of(context).colorScheme.error.withAlpha(26)
                    : Theme.of(context).primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description,
                color: isCritical
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              report['title']!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${report['patient']} • ${report['date']}'),
                if (isCritical)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Critical Priority',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentReviewScreen(
                      documentTitle: report['title']!,
                      documentType: report['type']!,
                      patientName: report['patient']!,
                      date: report['date']!,
                    ),
                  ),
                );
              },
              child: const Text('Review'),
            ),
          ),
        );
      },
    );
  }
}
