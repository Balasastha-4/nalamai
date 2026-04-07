import 'package:flutter/material.dart';

/// AnimatedHealthCard widget for displaying health metrics with animations
/// Used in preventive care and health monitoring screens
class AnimatedHealthCard extends StatefulWidget {
  final String title;
  final String? value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;
  final bool showTrend;
  final double? trendValue;
  final String? trendLabel;
  final bool isLoading;
  final Duration animationDuration;

  const AnimatedHealthCard({
    super.key,
    required this.title,
    this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.onTap,
    this.trailing,
    this.child,
    this.showTrend = false,
    this.trendValue,
    this.trendLabel,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedHealthCard> createState() => _AnimatedHealthCardState();
}

class _AnimatedHealthCardState extends State<AnimatedHealthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;
    final effectiveBgColor =
        widget.backgroundColor ?? effectiveColor.withOpacity(0.1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(scale: _scaleAnimation, child: child),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [effectiveBgColor, effectiveBgColor.withOpacity(0.5)],
              ),
            ),
            child: widget.isLoading
                ? _buildLoadingState(theme)
                : _buildContent(theme, effectiveColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 32,
          width: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, Color effectiveColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: effectiveColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        const SizedBox(height: 16),
        // Use child widget if provided, otherwise show value
        if (widget.child != null)
          widget.child!
        else if (widget.value != null)
          Row(
            children: [
              Text(
                widget.value!,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: effectiveColor,
                ),
              ),
              if (widget.showTrend && widget.trendValue != null) ...[
                const SizedBox(width: 12),
                _buildTrendIndicator(theme),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildTrendIndicator(ThemeData theme) {
    final isPositive = widget.trendValue! >= 0;
    final trendColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: trendColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${widget.trendValue!.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.trendLabel != null) ...[
            const SizedBox(width: 4),
            Text(
              widget.trendLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: trendColor.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A variant of AnimatedHealthCard specifically for risk indicators
class RiskIndicatorCard extends StatelessWidget {
  final String title;
  final double riskScore;
  final String riskLevel; // low, medium, high, critical
  final String? description;
  final VoidCallback? onTap;

  const RiskIndicatorCard({
    super.key,
    required this.title,
    required this.riskScore,
    required this.riskLevel,
    this.description,
    this.onTap,
  });

  Color _getRiskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon() {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Icons.check_circle_outline;
      case 'medium':
        return Icons.warning_amber_outlined;
      case 'high':
        return Icons.error_outline;
      case 'critical':
        return Icons.dangerous_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor();

    return AnimatedHealthCard(
      title: title,
      value: '${riskScore.toStringAsFixed(0)}%',
      subtitle: description ?? 'Risk Level: ${riskLevel.toUpperCase()}',
      icon: _getRiskIcon(),
      color: riskColor,
      onTap: onTap,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: riskColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          riskLevel.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: riskColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Progress card showing workflow or adherence progress
class ProgressHealthCard extends StatelessWidget {
  final String title;
  final double progress;
  final String progressLabel;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const ProgressHealthCard({
    super.key,
    required this.title,
    required this.progress,
    required this.progressLabel,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: effectiveColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: effectiveColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    progressLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: effectiveColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: effectiveColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(effectiveColor),
                      minHeight: 8,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Workflow step card showing individual workflow status
class WorkflowStepCard extends StatelessWidget {
  final String stepName;
  final String status; // pending, in_progress, completed, failed
  final String? description;
  final String? agentName;
  final DateTime? completedAt;
  final VoidCallback? onTap;

  const WorkflowStepCard({
    super.key,
    required this.stepName,
    required this.status,
    this.description,
    this.agentName,
    this.completedAt,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.grey;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getStatusIcon(), color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (agentName != null)
                      Text(
                        'Agent: $agentName',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase().replaceAll('_', ' '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
