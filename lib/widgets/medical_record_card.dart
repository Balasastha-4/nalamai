import 'package:flutter/material.dart';
import '../models/medical_record.dart';
import '../theme/app_theme.dart';
import '../screens/report_detail_screen.dart';

class MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;
  final Color color;

  const MedicalRecordCard({
    super.key,
    required this.record,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.cardBorderColor(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            record.diagnosis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Hero(
                    tag: 'icon_${record.id}',
                    child: Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.formattedDate,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.doctor,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  if (record.notes.isNotEmpty) ...[
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.notes,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (record.medicines.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Medicines',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: record.medicines
                          .map(
                            (med) => Chip(
                              label: Text(
                                med,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: color.withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (record.documents.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Documents',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: record.documents.map((doc) {
                        IconData icon = Icons.insert_drive_file;
                        Color iconColor = Colors.grey;
                        if (doc.endsWith('.pdf')) {
                          icon = Icons.picture_as_pdf;
                          iconColor = Colors.red;
                        } else if (doc.endsWith('.jpg') ||
                            doc.endsWith('.png')) {
                          icon = Icons.image;
                          iconColor = Colors.blue;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: iconColor),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  doc,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReportDetailScreen(record: record),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Full Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
