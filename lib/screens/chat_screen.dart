import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;
  final List<String> actionsTaken;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.actionsTaken = const [],
  });
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
  final AiService _aiService = AiService();
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
      _suggestedReplies.clear(); // Clear suggestions on user input
    });
    _scrollToBottom();

    final userId = await AuthService().getUserId() ?? "1";

    // Call the real Python AI Microservice
    _aiService.sendChatMessage(
      text, 
      userId, 
      vitals: {
        'heart_rate': 85,
        'systolic_bp': 120,
        'diastolic_bp': 80,
        'spo2': 98
      }
    ).then((response) {
      if (mounted) {
        _addBotMessage(
          response['reply'] ?? 'I could not process that.',
          actionsTaken: List<String>.from(response['actions_taken'] ?? []),
        );
      }
    }).catchError((error) {
       if (mounted) {
         _addBotMessage("Sorry, I'm having trouble connecting to the medical net right now.");
       }
    });
  }

  void _addBotMessage(String text, {List<String> actionsTaken = const []}) {
    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: text, 
          isUser: false, 
          timestamp: DateTime.now(),
          actionsTaken: actionsTaken,
        ),
      );
      // Add contextual suggestions based on response
      if (text.toLowerCase().contains('appointment')) {
        _suggestedReplies.addAll(['Book Appointment', 'Cancel', 'Not now']);
      } else if (text.toLowerCase().contains('fever')) {
        _suggestedReplies.addAll(['Check Symptoms', 'Call Emergency']);
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

  // Removed _getBotResponse as it's now handled by the Python backend

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
                Icons.smart_toy_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. AI Assistant',
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
                    Text(
                      'Always Active',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey[600]),
            onPressed: () {},
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
                      hintText: 'Type a message...',
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
              Icons.smart_toy_rounded,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
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
                if (!isUser && message.actionsTaken.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology_alt, size: 14, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              "AI Actions Taken",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...message.actionsTaken.map((action) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "• $action",
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                // Time timestamp
              ],
            ),
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
            Icons.smart_toy_rounded,
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
          child: const _TypingDots(),
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
                Icons.health_and_safety_outlined,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hi, I\'m Dr. AI!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal health companion.\nHow can I help you today?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
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
                    icon: Icons.search_rounded,
                    label: 'Check Symptoms',
                    onTap: () => onSuggestionSelected('Check Symptoms'),
                  ),
                  _SuggestionCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Book Appointment',
                    onTap: () => onSuggestionSelected('Book Appointment'),
                  ),
                  _SuggestionCard(
                    icon: Icons.medication_rounded,
                    label: 'Pill Reminder',
                    onTap: () => onSuggestionSelected('Set Pill Reminder'),
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
