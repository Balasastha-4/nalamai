import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/medical_record.dart';

class ReportDetailScreen extends StatelessWidget {
  final MedicalRecord record;

  const ReportDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Report Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing Report...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Doctor Details'),
                  const SizedBox(height: 12),
                  _buildDoctorCard(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Clinical Notes'),
                  const SizedBox(height: 12),
                  _buildNotesSection(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Prescriptions'),
                  const SizedBox(height: 12),
                  _buildMedicinesList(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Attachments'),
                  const SizedBox(height: 12),
                  _buildDocumentsList(context),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Light Blue
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LAB REPORT',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            record.diagnosis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Hero(
                      tag: 'icon_${record.id}',
                      child: Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        record.formattedDate,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _buildHeaderInfo(
                context,
                Icons.access_time,
                '10:30 AM',
              ), // Mock time
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.secondaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.secondaryTeal,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.doctor,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  record.specialty,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {}, // Future profile view
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(
          context,
        ).textTheme.labelLarge?.color?.withValues(alpha: 0.6),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.cardBorderColor(context)
              : const Color(0xFFFFECB3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.format_quote_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Observation',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.notes.isNotEmpty
                ? record.notes
                : 'No additional notes provided.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : const Color(0xFF5D4037),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesList(BuildContext context) {
    if (record.medicines.isEmpty) {
      return Text(
        'No medicines.',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      );
    }
    return Column(
      children: record.medicines.map((med) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      '1 Tablet • After Meal', // Mock dosage
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentsList(BuildContext context) {
    if (record.documents.isEmpty) {
      return Text(
        'No attachments.',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      );
    }
    return Column(
      children: record.documents.map((doc) {
        final isPdf = doc.endsWith('.pdf');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.cardBorderColor(context)),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPdf
                    ? Colors.red.withAlpha(30)
                    : Colors.blue.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.image,
                color: isPdf ? Colors.red : Colors.blue,
              ),
            ),
            title: Text(
              doc,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '2.4 MB • 12 Feb 2026', // Mock metadata
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              onPressed: () {},
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading Report PDF...')),
              );
            },
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text(
              'Download Full Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
