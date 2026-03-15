import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/medical_record.dart';
import '../widgets/feedback/empty_state.dart';
import '../widgets/feedback/skeleton_loader.dart';
import 'analytics_screen.dart';
import '../widgets/medical_record_card.dart';
import '../services/api_service.dart';
import '../services/reports_service.dart';
import '../models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<MedicalRecord> _allRecords = [];
  List<MedicalRecord> _filteredRecords = [];
  String _selectedFilter = 'All';
  // 0: Timeline, 1: Analytics
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    
    _searchController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _filterRecords(_searchController.text);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    
    List<MedicalRecord> backendRecords = [];
    List<MedicalRecord> mappedLocalRecords = [];

    // 1. Fetch from Local Storage (Instant)
    try {
      final List<Report> localReports = await ReportsService().getReports();
      debugPrint('DEBUG: Fetched ${localReports.length} local reports');
      mappedLocalRecords = localReports.map((report) {
        return MedicalRecord(
          id: 'local_${report.id}',
          date: DateTime.tryParse(report.date) ?? DateTime.now(),
          doctor: report.doctorName,
          specialty: 'Scanned Prescription',
          diagnosis: report.diagnosis,
          medicines: report.medicines,
          documents: [report.imagePath],
          notes: 'Device stored document.',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching local reports: $e');
    }

    // 2. Fetch from Backend (Network dependent)
    try {
      backendRecords = await _apiService.getMedicalRecords();
      debugPrint('DEBUG: Fetched ${backendRecords.length} backend records');
    } catch (e) {
      debugPrint('Error fetching backend records: $e');
    }

    if (mounted) {
      setState(() {
        _allRecords = [...backendRecords, ...mappedLocalRecords];
        // Sort by date descending
        _allRecords.sort((a, b) => b.date.compareTo(a.date));
        _filteredRecords = _allRecords;
        _isLoading = false;
        debugPrint('DEBUG: Total combined records: ${_allRecords.length}');
        _filterRecords(_searchController.text);
      });
    }
  }

  void _filterRecords(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        final matchesQuery =
            record.diagnosis.toLowerCase().contains(lowerQuery) ||
            record.doctor.toLowerCase().contains(lowerQuery) ||
            record.formattedDate.toLowerCase().contains(lowerQuery);

        final matchesFilter =
            _selectedFilter == 'All' ||
            (_selectedFilter == 'Prescriptions' &&
                record.medicines.isNotEmpty) ||
            (_selectedFilter == 'Lab Reports' &&
                record.documents.any(
                  (doc) => doc.toLowerCase().contains('report'),
                )) ||
            (_selectedFilter == 'Vaccinations' &&
                record.diagnosis.toLowerCase().contains(
                  'vaccin',
                )); // Example logic

        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                toolbarHeight: 65, // Allow height for search bar + padding
                title: _buildSearchBar(),
                centerTitle: true,
                automaticallyImplyLeading: false,
              ),
              SliverToBoxAdapter(child: _buildFilterChips()),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabDelegate(
                  TabBar(
                    labelColor: AppTheme.primaryBlue,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color,
                    indicatorColor: AppTheme.primaryBlue,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Timeline'),
                      Tab(text: 'Trends'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: _fetchRecords,
                child: _isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 100,
                        ),
                        itemCount: 5,
                        itemBuilder: (context, index) =>
                            const SkeletonListTile(),
                      )
                    : _filteredRecords.isEmpty
                        ? const EmptyState(
                            title: 'No medical history found',
                            message:
                                'Try adjusting your search or filters to find what you are looking for.',
                            icon: Icons.history_toggle_off,
                          )
                        : _buildGroupedList(),
              ),
              const AnalyticsView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search records...',
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            size: 20,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.cardBorderColorDark.withValues(alpha: 0.3)
              : AppTheme.cardBorderColorLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildChip('All', true),
          const SizedBox(width: 8),
          _buildChip('Prescriptions', false),
          const SizedBox(width: 8),
          _buildChip('Lab Reports', false),
          const SizedBox(width: 8),
          _buildChip('Vaccinations', false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == label,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? label : 'All';
          _filterRecords(_searchController.text);
        });
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: _selectedFilter == label
            ? AppTheme.primaryBlue
            : Theme.of(context).textTheme.bodySmall?.color,
        fontWeight: _selectedFilter == label
            ? FontWeight.bold
            : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _selectedFilter == label
              ? AppTheme.primaryBlue.withValues(alpha: 0.5)
              : AppTheme.cardBorderColor(context),
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildGroupedList() {
    // 1. Sort records by Date
    _filteredRecords.sort((a, b) => b.date.compareTo(a.date));

    // 2. Group by Month-Year
    Map<String, List<MedicalRecord>> grouped = {};
    for (var record in _filteredRecords) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final groupKey = '${months[record.date.month - 1]} ${record.date.year}';
      grouped.putIfAbsent(groupKey, () => []).add(record);
    }

    final groupKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final key = groupKeys[groupIndex];
        final records = grouped[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 8),
              child: Text(
                key,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            // Items
            ...records.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final isLastInGroup = index == records.length - 1;
              // Calculate global index for staggering if needed, or just local
              final globalIndex = groupIndex * 5 + index; // approx

              return _TimelineItem(
                record: record,
                isFirst: false, // Handled differently in grouped view
                isLast: isLastInGroup && groupIndex == groupKeys.length - 1,
                // If it's the last item in a group, we might still want a line connecting to next group?
                // For now, let's break line between groups for visual separation of months.
                showBottomLine: !isLastInGroup,
                animationDelay: globalIndex * 100,
              );
            }),
            const SizedBox(height: 24), // Space between groups
          ],
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final MedicalRecord record;
  final bool isFirst;
  final bool isLast;
  final bool showBottomLine;
  final int animationDelay;

  const _TimelineItem({
    required this.record,
    required this.isFirst,
    required this.isLast,
    this.showBottomLine = true,
    required this.animationDelay,
  });

  IconData _getIconForDiagnosis(String diagnosis) {
    if (diagnosis.contains('Fever') || diagnosis.contains('Flu')) {
      return Icons.thermostat;
    } else if (diagnosis.contains('Hypertension') ||
        diagnosis.contains('Heart')) {
      return Icons.favorite;
    } else if (diagnosis.contains('Dermatitis') || diagnosis.contains('Skin')) {
      return Icons.healing;
    } else if (diagnosis.contains('Sprain') ||
        diagnosis.contains('Fracture') ||
        diagnosis.contains('Bone')) {
      return Icons.personal_injury;
    } else {
      return Icons.medical_services;
    }
  }

  Color _getColorForDiagnosis(String diagnosis) {
    if (diagnosis.contains('Fever')) return Colors.orange;
    if (diagnosis.contains('Hypertension')) return Colors.red;
    if (diagnosis.contains('Dermatitis')) return Colors.purple;
    if (diagnosis.contains('Sprain')) return Colors.blue;
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForDiagnosis(record.diagnosis);
    final color = _getColorForDiagnosis(record.diagnosis);
    const double topOffset = 24.0; // Distance to center of node

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Stack(
        children: [
          // Timeline Line & Node
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 50,
            child: Column(
              children: [
                SizedBox(
                  height: topOffset,
                  child: Center(
                    child: Container(width: 2, color: Colors.transparent),
                  ),
                ),
                // Node
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                // Bottom Line
                Expanded(
                  child: showBottomLine
                      ? Center(
                          child: CustomPaint(
                            size: const Size(2, double.infinity),
                            painter: _DashedLinePainter(),
                          ),
                        )
                      : Container(),
                ),
              ],
            ),
          ),
          // Content Card
          Padding(
            padding: const EdgeInsets.only(left: 48.0, bottom: 24.0),
            child: MedicalRecordCard(record: record, color: color),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) {
    return false;
  }
}
