import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/fade_in_slide.dart';
import '../widgets/feedback/error_state.dart';
import 'patient_detail_screen.dart';
import '../services/patient_service.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  bool _isError = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final List<Patient> patients = await PatientService().getPatients();
      final List<Map<String, dynamic>> mapped = patients.map((p) => {
        'id': p.id,
        'name': p.fullName,
        'age': p.age ?? 35,
        'gender': p.gender ?? 'Male',
        'condition': (p.conditions != null && p.conditions!.isNotEmpty) ? p.conditions!.first : 'Routine Checkup',
        'status': 'Stable',
        'risk': (p.conditions != null && p.conditions!.isNotEmpty) ? 'High' : 'Low',
      }).toList();

      if (mounted) {
        setState(() {
          _allPatients = mapped;
          _filteredPatients = _allPatients;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      if (mounted) {
        setState(() => _isError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        final name = patient['name'].toString().toLowerCase();
        final matchesSearch = name.contains(query.toLowerCase());
        final matchesFilter =
            _selectedFilter == 'All' || patient['risk'] == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Patient List',
            color: Theme.of(context).iconTheme.color,
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterPatients,
                    decoration: InputDecoration(
                      hintText: 'Search patients...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilterChips(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isError
                    ? ErrorState(
                        title: 'Failed to load patients',
                        message:
                            'We could not fetch the patient list. Please check your connection and try again.',
                        onRetry: _fetchPatients,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                    itemCount: _filteredPatients.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final patient = _filteredPatients[index];
                      return FadeInSlide(
                        delay: Duration(milliseconds: index * 50),
                        duration: const Duration(milliseconds: 400),
                        child: _buildPatientCard(patient),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    Color statusColor;
    Color statusBgColor;
    String risk = patient['risk'];

    if (risk == 'High') {
      statusColor = AppTheme.error;
      statusBgColor = AppTheme.error.withValues(alpha: 0.1);
    } else if (risk == 'Medium') {
      statusColor = AppTheme.warning;
      statusBgColor = AppTheme.warning.withValues(alpha: 0.1);
    } else {
      statusColor = AppTheme.success;
      statusBgColor = AppTheme.success.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.glassDecoration(context).copyWith(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Vertical Risk Bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: statusColor),
          ),
          OpenContainer(
            transitionType: ContainerTransitionType.fadeThrough,
            transitionDuration: const Duration(milliseconds: 500),
            openBuilder: (context, _) => PatientDetailScreen(
              patientName: patient['name'],
              patientId: patient['id']?.toString() ?? '1',
            ),
            closedElevation: 0,
            openElevation: 0,
            closedColor: Colors.transparent,
            openColor: Theme.of(context).scaffoldBackgroundColor,
            middleColor: Colors.transparent,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            closedBuilder: (context, openContainer) => InkWell(
              onTap: openContainer,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(width: 8), // Spacing for risk bar
                    Hero(
                      tag: 'avatar_${patient['name']}',
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: statusBgColor,
                        child: Text(
                          (patient['name'] as String).substring(0, 1),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                patient['name'],
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  risk == 'High'
                                      ? 'Critical'
                                      : (risk == 'Medium'
                                            ? 'Observation'
                                            : 'Stable'),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${patient['age']} yrs • ${patient['gender']}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                patient['condition'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('All'),
          _buildFilterChip('High', color: AppTheme.error),
          _buildFilterChip('Medium', color: AppTheme.warning),
          _buildFilterChip('Low', color: AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {Color? color}) {
    final bool isSelected = _selectedFilter == label;
    final Color activeColor = color ?? AppTheme.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
            _filterPatients(_searchController.text);
          });
        },
        selectedColor: activeColor.withValues(alpha: 0.2),
        checkmarkColor: activeColor,
        labelStyle: TextStyle(
          color: isSelected ? activeColor : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? activeColor.withValues(alpha: 0.5)
                : AppTheme.cardBorderColor(context),
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
