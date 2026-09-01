import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/api_constants.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String datasourceId;
  final String title;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.datasourceId,
    required this.title,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load the conversation history.
  Future<void> _loadMessages() async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.conversations}/${widget.conversationId}/messages',
      );
      setState(() {
        _messages = List<Map<String, String>>.from(
          response.data['data'].map(
            (m) => {
              'role': m['role'].toString(),
              'content': m['content'].toString(),
            },
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  // Send a question to the data assistant.
  Future<void> _sendMessage() async {
    final query = _messageController.text.trim();
    if (query.isEmpty) return;

    // Show the user message immediately while the request is pending.
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _apiService.post(
        ApiConstants.chat,
        data: {
          'query': query,
          'conversationId': widget.conversationId,
          'datasourceId': widget.datasourceId,
        },
      );

      debugPrint('Chat response: ${response.statusCode} ${response.data}');
      final responseData = response.data;
      final responsePayload = responseData is Map ? responseData['data'] : null;
      final answer = responsePayload is Map
          ? responsePayload['answer']?.toString()
          : null;

      if (answer == null || answer.trim().isEmpty) {
        throw StateError(
          'The chat API returned no answer. Response: ${response.data}',
        );
      }

      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': answer});
        _isLoading = false;
      });

      _scrollToBottom();
    } on DioException catch (error) {
      debugPrint(
        'Chat request failed: ${error.response?.statusCode} '
        '${error.response?.data ?? error.message}',
      );
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': _chatErrorMessage(error),
        });
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Chat response parsing failed: $error');
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'The server returned an invalid answer. Check the API logs.',
        });
        _isLoading = false;
      });
    }
  }

  String _chatErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return 'Your session has expired. Please sign in again.';
    }
    if (statusCode != null) {
      return 'The chat service returned error $statusCode. Check the server logs.';
    }
    return 'Could not reach the chat service. Ensure the API is running and the base URL is correct.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'AI Data Analyst',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Conversation messages.
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      return _buildMessage(
                        message['content']!,
                        message['role'] == 'user',
                      );
                    },
                  ),
          ),

          // Message input.
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 60, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'Ask anything about your data',
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '"Which product sold the most?"',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6C63FF) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          content,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI is thinking...',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask your data anything...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
