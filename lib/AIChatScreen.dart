import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

final back_url='https://innergame-backend.onrender.com/';

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.black87,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AIChatScreen(),
  ));
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Language selector state
  String _selectedLanguage = 'english'; // Default English
  final List<Map<String, String>> _languages = [
    {'code': 'english', 'name': 'English'},
    {'code': 'hinglish (Hindi)', 'name': 'Hindi (English)'},
    {'code': 'hindi (Hindi Script)', 'name': 'Hindi script'},
    {'code': 'marathi (Marathi Script)', 'name': 'Marathi script'},
    {'code': 'Gujarati (Gujarati Script)', 'name': 'Gujarati script'},
    {'code': 'Sanskrit (Sanskrit Script)', 'name': 'Sanskrit script'},
  ];

  final List<String> _idleSuggestions = [
    'How can I help you today?',
    'How are you feeling right now?',
    'Is there something on your mind?',
    'Want to explore a thought together?',
    'Need help reframing a belief?',
    'Tell me what’s bothering you.',
    'Let’s talk through your emotions.',
    'Would you like a mental drill?',
    'I’m here to support you.',
    'Want to start with an affirmation?',
  ];

  late String _idleMessage;

  @override
  void initState() {
    super.initState();
    _loadLatestThread();
    _idleMessage = _idleSuggestions[Random().nextInt(_idleSuggestions.length)];
  }

  Future<void> _loadLatestThread() async {
    final prefs = await SharedPreferences.getInstance();
    final lastThreadId = prefs.getString('latest_thread_id');
    if (lastThreadId != null) {
      final threadData = prefs.getString('thread_$lastThreadId');
      if (threadData != null) {
        final thread = jsonDecode(threadData);
        final loadedMessages =
        List<Map<String, dynamic>>.from(thread['messages']);
        setState(() {
          _messages = loadedMessages
              .map((msg) => {
            'role': msg['role'].toString(),
            'text': msg['text'].toString(),
            'time': msg['time'].toString(),
          })
              .toList();
        });
      }
    }
  }

  Future<void> _saveThread() async {
    final prefs = await SharedPreferences.getInstance();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final time = TimeOfDay.fromDateTime(now).format(context);
    final title = "Session on $date at $time";
    final dateTime = now.toString();

    final thread = {
      'id': id,
      'title': title,
      'timestamp': dateTime,
      'messages': _messages,
    };

    await prefs.setString('thread_$id', jsonEncode(thread));
    List<String> threadList = prefs.getStringList('thread_ids') ?? [];
    threadList.add(id);
    await prefs.setStringList('thread_ids', threadList);
    await prefs.setString('latest_thread_id', id);
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'time': DateTime.now().toIso8601String(),
      });
      _isLoading = true;
    });

    // 1️⃣ Check internet connection first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _addNoInternetMessage();
      _controller.clear();
      return;
    }

    final url = Uri.parse(back_url + 'api/chat');
    final chatHistory = _messages
        .map((m) => {
      "role": m['role'] == 'user' ? "user" : "model",
      "parts": [
        {"text": m['text'] ?? ''}
      ]
    })
        .toList();

    final body = jsonEncode({
      "messages": chatHistory,
      "language": _selectedLanguage,
    });

    try {
      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      )
          .timeout(const Duration(seconds: 60));

      String reply = 'Something went wrong.';
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['reply'] ?? 'No reply';
      } else {
        reply = 'Error ${response.statusCode}: ${response.body}';
      }

      setState(() {
        _messages.add({
          'role': 'bot',
          'text': reply,
          'time': DateTime.now().toIso8601String(),
        });
        _isLoading = false;
      });

      await _saveThread();
    } on SocketException catch (_) {
      _addNoInternetMessage();
    } on TimeoutException catch (_) {
      _addNoInternetMessage();
    } on http.ClientException catch (_) {
      _addNoInternetMessage();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'text': 'An unexpected error occurred. Please try again.',
          'time': DateTime.now().toIso8601String(),
        });
        _isLoading = false;
      });
    }

    _controller.clear();
  }

  void _addNoInternetMessage() {
    showToast("Please connect to a stable network");
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
       title: const Text("Saathi"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    icon: Icon(
                      Icons.language,
                      color: isDark ? Colors.white : Colors.black, // Adaptive icon color
                    ),
                    dropdownColor: isDark ? Colors.grey.shade900 : Colors.white, // Adaptive dropdown background
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black, // Adaptive text color
                      fontSize: 14,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'english',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'hinglish (Hindi)',
                        child: Text('Hindi (English)'),
                      ),
                      DropdownMenuItem(
                        value: 'hindi (Hindi Script)',
                        child: Text('हिन्दी'),
                      ),
                      DropdownMenuItem(
                        value: 'marathi (Marathi Script)',
                        child: Text('मराठी'),
                      ),
                      DropdownMenuItem(
                        value: 'Gujarati (Gujarati Script)',
                        child: Text('ગુજરાતી'),
                      ),
                      DropdownMenuItem(
                        value: 'Sanskrit (Hindi Script)',
                        child: Text('संस्कृत'),
                      ),
                    ],
                  ),
                ),
              ],

            ),
          ),

          // Chat History Button
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'View past threads',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatThreadsScreen()),
              );
            },
          ),

          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete conversation',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('latest_thread_id');
              setState(() {
                _messages = [];
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _idleMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final time = DateTime.tryParse(msg['time'] ?? '');
                final timeStr = time != null
                    ? TimeOfDay.fromDateTime(time).format(context)
                    : '';

                final bubbleColor = isUser
                    ? accentColor
                    : isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200;

                final textColor = isUser
                    ? Colors.white
                    : isDark
                    ? Colors.white
                    : Colors.black;

                final timeColor = isUser
                    ? Colors.white70
                    : isDark
                    ? Colors.white60
                    : Colors.black54;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser || isDark
                          ? Border.all(color: Colors.grey.shade700)
                          : Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg['text'] ?? '',
                            style: TextStyle(
                                color: textColor, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(timeStr,
                            style: TextStyle(
                                color: timeColor, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                        ),
                        cursorColor: accentColor,
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _sendMessage(val.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) _sendMessage(text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ChatThreadsScreen and ThreadViewerScreen remain unchanged

class ChatThreadsScreen extends StatefulWidget {
  const ChatThreadsScreen({super.key});

  @override
  State<ChatThreadsScreen> createState() => _ChatThreadsScreenState();
}

class _ChatThreadsScreenState extends State<ChatThreadsScreen> {
  List<Map<String, dynamic>> _threads = [];

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final prefs = await SharedPreferences.getInstance();
    final threadIds = prefs.getStringList('thread_ids') ?? [];

    final List<Map<String, dynamic>> threads = [];

    for (final id in threadIds) {
      final threadData = prefs.getString('thread_$id');
      if (threadData != null) {
        final thread = jsonDecode(threadData);
        threads.add(thread);
      }
    }

    threads.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    setState(() {
      _threads = threads;
    });
  }

  Future<void> _deleteThread(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('thread_$id');

    List<String> threadList = prefs.getStringList('thread_ids') ?? [];
    threadList.remove(id);
    await prefs.setStringList('thread_ids', threadList);

    setState(() {
      _threads.removeWhere((t) => t['id'] == id);
    });
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this session?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _deleteThread(id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Past Sessions')),
      body: _threads.isEmpty
          ? const Center(child: Text('No threads found'))
          : ListView.builder(
        itemCount: _threads.length,
        itemBuilder: (context, index) {
          final thread = _threads[index];
          final threadId = thread['id'];

          return Dismissible(
            key: Key(threadId),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteThread(threadId),
            child: ListTile(
              title: Text(thread['title'] ?? 'Untitled'),
              subtitle: Text(thread['timestamp'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThreadViewerScreen(messages: thread['messages']),
                  ),
                );
              },
              onLongPress: () => _confirmDelete(threadId),
            ),
          );
        },
      ),
    );
  }
}

class ThreadViewerScreen extends StatelessWidget {
  final List<dynamic> messages;

  const ThreadViewerScreen({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Thread View')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isUser = msg['role'] == 'user';

          final bubbleColor = isUser
              ? accentColor
              : isDark
              ? Colors.grey.shade800
              : Colors.grey.shade200;

          final textColor = isUser
              ? Colors.white
              : isDark
              ? Colors.white
              : Colors.black;

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
                border: isUser || isDark ? Border.all(color: Colors.grey.shade700) : Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                msg['text'] ?? '',
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}