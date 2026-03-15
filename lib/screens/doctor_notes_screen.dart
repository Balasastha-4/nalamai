import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/fade_in_slide.dart';

class DoctorNotesScreen extends StatefulWidget {
  final String reportTitle;
  final String date;
  final String patientName;

  const DoctorNotesScreen({
    super.key,
    required this.reportTitle,
    required this.date,
    required this.patientName,
  });

  @override
  State<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends State<DoctorNotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  String _selectedTag = 'Normal';
  // Demo Data - Local State
  final List<Map<String, String>> _notes = [
    {
      'date': 'Feb 07, 2026 10:30 AM',
      'text': 'Patient reports mild discomfort. Prescribed rest.',
      'doctor': 'Dr. Smith',
      'tag': 'Normal',
    },
    {
      'date': 'Feb 01, 2026 09:15 AM',
      'text': 'Initial observation shows stable vitals.',
      'doctor': 'Dr. Smith',
      'tag': 'Normal',
    },
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _notes.insert(0, {
          'date': 'Now',
          'text': _noteController.text.trim(),
          'doctor': 'Dr. Smith',
          'tag': _selectedTag,
        });
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Clinical Notes'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: Column(
        children: [
          // Context Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(context),
              width: double.infinity,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_ind,
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.reportTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.patientName} • ${widget.date}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Notes List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return FadeInSlide(
                  delay: Duration(milliseconds: index * 100),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getTagColor(
                                      note['tag'] ?? 'Normal',
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  note['doctor']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              note['date']!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note['text']!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Note Editor
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Note',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTagSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Type your observation here...',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.mic_none,
                              color: AppTheme.primaryBlue,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dictation coming soon!'),
                                ),
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _saveNote,
                      backgroundColor: AppTheme.primaryBlue,
                      elevation: 2,
                      child: const Icon(Icons.send, color: Colors.white),
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

  Widget _buildTagSelector() {
    return Row(
      children: [
        _buildTagChip('Normal', Colors.green),
        const SizedBox(width: 8),
        _buildTagChip('Abnormal', Colors.orange),
        const SizedBox(width: 8),
        _buildTagChip('Urgent', Colors.red),
      ],
    );
  }

  Widget _buildTagChip(String label, Color color) {
    final isSelected = _selectedTag == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTag = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Abnormal':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.green;
    }
  }
}
