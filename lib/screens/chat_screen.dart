import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/agent_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;
  final List<AgentActionInfo> agentActions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.agentActions = const [],
  });
}

/// Represents a single AI agent action/tool call
class AgentActionInfo {
  final String toolName;
  final Map<String, dynamic> parameters;
  final String result;

  AgentActionInfo({
    required this.toolName,
    this.parameters = const {},
    this.result = '',
  });

  /// Human-readable tool name
  String get displayName {
    switch (toolName) {
      case 'get_patient_vitals':
        return '📊 Fetched Patient Vitals';
      case 'get_appointments':
        return '📅 Checked Appointments';
      case 'get_medical_history':
        return '📋 Retrieved Medical History';
      case 'book_appointment':
        return '✅ Booked Appointment';
      case 'get_medications':
        return '💊 Checked Medications';
      case 'get_available_doctors':
        return '👨‍⚕️ Found Available Doctors';
      case 'analyze_symptoms':
        return '🔍 Analyzed Symptoms';
      case 'get_health_risk':
        return '⚠️ Assessed Health Risk';
      case 'predict_no_show':
        return '📈 Predicted No-Show Risk';
      default:
        return '🤖 $toolName';
    }
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AgentService _agentService = AgentService();
  bool _isTyping = false;
  // Suggested replies shown above keyboard
  final List<String> _suggestedReplies = [];

  @override
  void initState() {
    super.initState();
    // Allow keyboard to push content up
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
      _suggestedReplies.clear();
    });
    _scrollToBottom();

    try {
      // Call the AGENTIC AI endpoint (with function calling & multi-agent system)
      final response = await _agentService.chat(
        message: text,
        context: {'mode': 'agentic'},
      );

      if (mounted) {
        if (response['status'] == 'error') {
          _addBotMessage(
            response['response']?.toString() ??
                'The AI service returned an error. Check that the Python service is running on port 8000.',
          );
          return;
        }

        // Parse agent actions from the response
        final List<AgentActionInfo> actions = [];
        final actionsList = response['actions_taken'];
        if (actionsList != null && actionsList is List) {
          for (final action in actionsList) {
            if (action is Map<String, dynamic>) {
              actions.add(AgentActionInfo(
                toolName: action['tool_name'] ?? 'unknown',
                parameters: action['parameters'] is Map<String, dynamic>
                    ? action['parameters']
                    : {},
                result: action['result']?.toString() ?? '',
              ));
            }
          }
        }

        // Parse suggestions from the response
        final List<String> suggestions = [];
        final suggestionsList = response['suggestions'];
        if (suggestionsList != null && suggestionsList is List) {
          for (final s in suggestionsList) {
            suggestions.add(s.toString());
          }
        }

        _addBotMessage(
          response['reply'] ?? response['response'] ?? 'I could not process that.',
          agentActions: actions,
          suggestions: suggestions,
        );
      }
    } catch (error) {
      if (mounted) {
        _addBotMessage(
            "Sorry, I'm having trouble connecting to the AI service right now. Please make sure the AI service is running on port 8000.");
      }
    }
  }

  void _addBotMessage(String text,
      {List<AgentActionInfo> agentActions = const [],
      List<String> suggestions = const []}) {
    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          agentActions: agentActions,
        ),
      );
      // Add suggestions from AI or contextual defaults
      _suggestedReplies.clear();
      if (suggestions.isNotEmpty) {
        _suggestedReplies.addAll(suggestions);
      } else if (text.toLowerCase().contains('appointment')) {
        _suggestedReplies
            .addAll(['Book Appointment', 'Cancel', 'Not now']);
      } else if (text.toLowerCase().contains('risk')) {
        _suggestedReplies
            .addAll(['Show details', 'Get recommendations', 'Thanks']);
      } else {
        _suggestedReplies.addAll(['Thank you', 'One more question']);
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Standard behavior: resize body when keyboard opens
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: const Icon(
                Icons.psychology_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Health Agent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Agentic AI • Multi-Agent System',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey[600]),
            onPressed: () => _showAgentInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isTyping
                ? _EmptyState(onSuggestionSelected: _handleSubmitted)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: const _TypingIndicatorBubble(),
                        );
                      }
                      final bool isLast = index == _messages.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 10 : 16),
                        child: _ChatBubble(message: _messages[index]),
                      );
                    },
                  ),
          ),
          if (_suggestedReplies.isNotEmpty) _buildSuggestedReplies(),
          _buildInputArea(context),
        ],
      ),
    );
  }

  void _showAgentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Agentic AI System'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This chat is powered by a Multi-Agent AI system with specialized agents:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              _AgentInfoItem(icon: '🎯', name: 'Master Agent', desc: 'Orchestrates all agents'),
              _AgentInfoItem(icon: '📅', name: 'Scheduling Agent', desc: 'Smart appointment booking'),
              _AgentInfoItem(icon: '📊', name: 'Predictive Agent', desc: 'Risk assessment & no-show prediction'),
              _AgentInfoItem(icon: '🔍', name: 'Initiation Agent', desc: 'Patient eligibility checks'),
              _AgentInfoItem(icon: '📋', name: 'HRA Agent', desc: 'Health Risk Assessment'),
              _AgentInfoItem(icon: '🏥', name: 'Pre-Visit Agent', desc: 'Visit preparation'),
              _AgentInfoItem(icon: '💊', name: 'Prevention Plan Agent', desc: 'Personalized care plans'),
              _AgentInfoItem(icon: '📝', name: 'Post-Visit Agent', desc: 'Documentation & SOAP notes'),
              _AgentInfoItem(icon: '💰', name: 'Billing Agent', desc: 'Billing & claims'),
              _AgentInfoItem(icon: '🔄', name: 'Follow-Up Agent', desc: 'Adherence tracking'),
              _AgentInfoItem(icon: '📧', name: 'Notification Agent', desc: 'Reminders & alerts'),
              SizedBox(height: 12),
              Text(
                'Design Patterns: Reflection, Planning, Tool-Use',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedReplies() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(_suggestedReplies[index]),
            backgroundColor: Theme.of(context).cardColor,
            elevation: 1,
            side: BorderSide(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            ),
            labelStyle: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
            onPressed: () => _handleSubmitted(_suggestedReplies[index]),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: Colors.grey[600],
                  onPressed: () {}, // Attachment logic
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2632) // Solid opaque dark color
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.transparent, // Could add focus border
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Ask the AI Agent...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _handleSubmitted(_textController.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
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

class _AgentInfoItem extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;

  const _AgentInfoItem({required this.icon, required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(text: '$name: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            child: const Icon(
              Icons.psychology_rounded,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? LinearGradient(
                          colors: [AppTheme.primaryBlue, const Color(0xFF4A90E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser
                      ? null // Use gradient
                      : (isDark ? const Color(0xFF2D3748) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: isUser
                        ? const Radius.circular(24)
                        : const Radius.circular(4),
                    bottomRight: isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(24),
                  ),
                  boxShadow: isUser || !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : (isDark ? Colors.white : AppTheme.textDark),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Time timestamp
                  ],
                ),
              ),
              // Agent Actions Card - Shows PROOF of Agentic AI working
              if (!isUser && message.agentActions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2332)
                        : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.psychology_alt,
                              size: 14,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Agentic AI Actions",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${message.agentActions.length} tool${message.agentActions.length > 1 ? 's' : ''} used',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...message.agentActions.map((action) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                action.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isUser) const SizedBox(width: 20), // Spacer
      ],
    );
  }
}

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: const Icon(
            Icons.psychology_rounded,
            size: 14,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D3748) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TypingDots(),
              const SizedBox(width: 8),
              Text(
                'Agent thinking...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(
                    alpha:
                        (index == 0
                            ? _controller.value < 0.3
                            : index == 1
                            ? _controller.value > 0.3 && _controller.value < 0.6
                            : _controller.value > 0.6)
                        ? 1.0
                        : 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Function(String) onSuggestionSelected;

  const _EmptyState({required this.onSuggestionSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Health Agent',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by Multi-Agent Agentic AI\nwith autonomous decision-making',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  SizedBox(width: 6),
                  Text(
                    '11 Specialized Agents Active',
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _SuggestionCard(
                    icon: Icons.favorite_rounded,
                    label: 'Check My Vitals',
                    onTap: () => onSuggestionSelected('Check my vitals'),
                  ),
                  _SuggestionCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Book Appointment',
                    onTap: () => onSuggestionSelected('Book an appointment for me'),
                  ),
                  _SuggestionCard(
                    icon: Icons.search_rounded,
                    label: 'Analyze Symptoms',
                    onTap: () => onSuggestionSelected('I have headache and fever'),
                  ),
                  _SuggestionCard(
                    icon: Icons.shield_rounded,
                    label: 'Health Risk',
                    onTap: () => onSuggestionSelected('What is my health risk?'),
                  ),
                  _SuggestionCard(
                    icon: Icons.history_rounded,
                    label: 'Medical History',
                    onTap: () => onSuggestionSelected('Show my medical history'),
                  ),
                  _SuggestionCard(
                    icon: Icons.medication_rounded,
                    label: 'Medications',
                    onTap: () => onSuggestionSelected('What medications am I on?'),
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

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100, // Fixed width for grid-like look
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D3748) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
