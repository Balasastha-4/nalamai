import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/report_model.dart';
import '../widgets/feedback/success_feedback.dart';
import '../services/reports_service.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';

class ScannedDataScreen extends StatefulWidget {
  final String imagePath;

  const ScannedDataScreen({super.key, required this.imagePath});

  @override
  State<ScannedDataScreen> createState() => _ScannedDataScreenState();
}

class _ScannedDataScreenState extends State<ScannedDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _doctorController;
  late TextEditingController _diagnosisController;
  late TextEditingController _medicineController;
  List<String> _medicines = [];

  bool _isSaving = false;
  bool _isAnalyzing = true;
  final AiService _aiService = AiService();

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );
    _doctorController = TextEditingController(text: 'Scanning Document...');
    _diagnosisController = TextEditingController(
      text: 'Extracting text from image...',
    );
    _medicineController = TextEditingController();
    _medicines = [];
    _processImageOCR();
  }

  Future<void> _processImageOCR() async {
    try {
      final authService = AuthService();
      final userId = await authService.getUserId() ?? "1";
      final response = await _aiService.extractTextFromImage(
        widget.imagePath,
        userId,
      );
      final String extractedText =
          response['agent_response']?.toString().trim() ??
          response['extracted_text']?.toString().trim() ??
          '';

      setState(() {
        _doctorController.text = 'Unknown Doctor (Please Edit)';
        _diagnosisController.text = extractedText.isNotEmpty
            ? extractedText
            : 'No text could be found.';
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _doctorController.text = 'Error processing image';
        _diagnosisController.text = 'Failed to connect to AI OCR Microservice.';
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _doctorController.dispose();
    _diagnosisController.dispose();
    _medicineController.dispose();
    super.dispose();
  }

  void _addMedicine() {
    if (_medicineController.text.isNotEmpty) {
      setState(() {
        _medicines.add(_medicineController.text);
        _medicineController.clear();
      });
    }
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  Future<void> _saveReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final report = Report(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _dateController.text,
          doctorName: _doctorController.text,
          diagnosis: _diagnosisController.text,
          medicines: _medicines,
          imagePath: widget.imagePath,
        );

        // Save to backend via ReportsService
        await ReportsService().saveReport(report);
        debugPrint('Saved Report: ${report.doctorName}, ${report.diagnosis}');

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SuccessFeedback(
                  message: 'Report saved successfully!',
                  onDismissed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error in _saveReport: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save report: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Review Extracted Data',
                style: TextStyle(
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.imagePath), fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isAnalyzing
                                  ? 'Extracting Details...'
                                  : 'Edit Details',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_isAnalyzing)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter Date' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _doctorController,
                        decoration: InputDecoration(
                          labelText: 'Doctor Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter Name' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _diagnosisController,
                        decoration: InputDecoration(
                          labelText: 'Diagnosis',
                          prefixIcon: const Icon(Icons.medical_services),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter Diagnosis' : null,
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Medicines',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _medicines.asMap().entries.map((entry) {
                          return Chip(
                            label: Text(entry.value),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeMedicine(entry.key),
                            backgroundColor: AppTheme.primaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _medicineController,
                              decoration: InputDecoration(
                                hintText: 'Add medicine...',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                              ),
                              onSubmitted: (_) => _addMedicine(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: AppTheme.primaryBlue,
                              ),
                              onPressed: _addMedicine,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_isSaving || _isAnalyzing)
                              ? null
                              : _saveReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppTheme.primaryBlue.withValues(
                              alpha: 0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Save Report',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
