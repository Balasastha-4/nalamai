import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/fade_in_slide.dart';

class DocumentReviewScreen extends StatefulWidget {
  final String documentTitle;
  final String documentType;
  final String patientName;
  final String date;

  const DocumentReviewScreen({
    super.key,
    required this.documentTitle,
    required this.documentType,
    required this.patientName,
    required this.date,
  });

  @override
  State<DocumentReviewScreen> createState() => _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends State<DocumentReviewScreen> {
  String _approvalStatus = 'Pending';
  bool _isHighlightMode = false;
  bool _isPenMode = false;
  bool _isChecklistVisible = false;
  final List<String> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, dynamic>> _checklist = [
    {'task': 'Patient ID Verified', 'done': false},
    {'task': 'Critical Values Reviewed', 'done': false},
    {'task': 'Comparative Analysis Done', 'done': false},
    {'task': 'Clinical Summary Verified', 'done': false},
  ];

  final List<Offset?> _signaturePoints = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _updateStatus(String status) {
    setState(() {
      _approvalStatus = status;
    });
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document marked as $status'),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add(_commentController.text);
        _commentController.clear();
      });
      Navigator.pop(context); // Close bottom sheet
    }
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Clinical Notes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add clinical observation or instruction...',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Note',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${widget.patientName} • ${widget.date}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          IconButton(
            icon: Icon(
              _isChecklistVisible ? Icons.checklist_rtl : Icons.checklist,
              color: _isChecklistVisible ? AppTheme.primaryBlue : null,
            ),
            onPressed: () =>
                setState(() => _isChecklistVisible = !_isChecklistVisible),
            tooltip: 'Review Checklist',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildStatusBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildToolButton(
                  icon: Icons.edit_outlined,
                  label: 'Pen',
                  isActive: _isPenMode,
                  onTap: () => setState(() {
                    _isPenMode = !_isPenMode;
                    if (_isPenMode) _isHighlightMode = false;
                  }),
                ),
                const SizedBox(width: 12),
                _buildToolButton(
                  icon: Icons.highlight_alt,
                  label: 'Highlight',
                  isActive: _isHighlightMode,
                  onTap: () => setState(() {
                    _isHighlightMode = !_isHighlightMode;
                    if (_isHighlightMode) _isPenMode = false;
                  }),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {},
                  tooltip: 'Zoom Out',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {},
                  tooltip: 'Zoom In',
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                // Simulated Document Viewer
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mock Document Content
                          Container(
                            padding: const EdgeInsets.all(40),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LABORATORY REPORT',
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Report ID: #LAB-2026-8849',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.medical_services_outlined,
                                      size: 40,
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                _buildMockLine(width: 200),
                                const SizedBox(height: 12),
                                _buildMockLine(width: double.infinity),
                                const SizedBox(height: 8),
                                _buildMockLine(width: double.infinity),
                                const SizedBox(height: 8),
                                _buildMockLine(width: 280),
                                const SizedBox(height: 32),
                                const Text(
                                  'TEST RESULTS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Table(
                                  border: TableBorder.all(
                                    color: Colors.grey[300]!,
                                  ),
                                  children: [
                                    _buildTableRow(
                                      'Hemoglobin',
                                      '14.2 g/dL',
                                      false,
                                    ),
                                    _buildTableRow(
                                      'WBC Count',
                                      '7.5 K/uL',
                                      false,
                                    ),
                                    _buildTableRow(
                                      'Platelets',
                                      '250 K/uL',
                                      false,
                                    ),
                                    _buildTableRow(
                                      'Glucose (Fast)',
                                      '110 mg/dL',
                                      true,
                                    ), // Highlighted
                                  ],
                                ),
                                const SizedBox(height: 40),
                                if (_isHighlightMode) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.yellow.withValues(alpha: 0.3),
                                    child: const Text('Highlighted Section'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Notes FAB
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton.extended(
                    onPressed: _showCommentSheet,
                    backgroundColor: AppTheme.primaryBlue,
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Add Note'),
                  ),
                ),

                // Checklist Overlay
                if (_isChecklistVisible) _buildChecklistOverlay(),
              ],
            ),
          ),

          // Signature Pad Section
          if (_approvalStatus == 'Approved')
            FadeInSlide(child: _buildSignatureSection()),

          // Approval Actions Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'Reject',
                          color: Colors.red,
                          icon: Icons.close,
                          isSelected: _approvalStatus == 'Rejected',
                          onTap: () => _updateStatus('Rejected'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Pending',
                          color: Colors.orange,
                          icon: Icons.hourglass_empty,
                          isSelected: _approvalStatus == 'Pending',
                          onTap: () => _updateStatus('Pending'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Approve',
                          color: Colors.green,
                          icon: Icons.check,
                          isSelected: _approvalStatus == 'Approved',
                          onTap: () => _updateStatus('Approved'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    IconData icon;
    switch (_approvalStatus) {
      case 'Approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_full;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _approvalStatus,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppTheme.primaryBlue
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppTheme.primaryBlue
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockLine({required double width}) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value, bool highlight) {
    return TableRow(
      decoration: BoxDecoration(
        color: highlight ? Colors.amber.withValues(alpha: 0.1) : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.red : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistOverlay() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 280,
      child: FadeInSlide(
        slideOffset: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Review Checklist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () =>
                          setState(() => _isChecklistVisible = false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _checklist.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _checklist[index];
                    return CheckboxListTile(
                      value: item['done'],
                      onChanged: (val) => setState(() => item['done'] = val),
                      title: Text(
                        item['task'],
                        style: TextStyle(
                          fontSize: 13,
                          color: item['done'] ? Colors.grey : null,
                          decoration: item['done']
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.primaryBlue,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checklist.every((e) => e['done'])
                        ? () => setState(() => _isChecklistVisible = false)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Complete Review',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
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
              const Text(
                'Digital Signature',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _signaturePoints.clear()),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    _signaturePoints.add(
                      renderBox.globalToLocal(details.globalPosition),
                    );
                  });
                },
                onPanEnd: (details) =>
                    setState(() => _signaturePoints.add(null)),
                child: CustomPaint(
                  painter: SignaturePainter(points: _signaturePoints),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Sign above to finalize approval',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
