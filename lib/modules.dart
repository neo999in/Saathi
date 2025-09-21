import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

// ------------------ Mental Agility Drills ------------------
class MentalAgilityDrillsScreen extends StatefulWidget {
  const MentalAgilityDrillsScreen({super.key});
  @override
  State<MentalAgilityDrillsScreen> createState() => _MentalAgilityDrillsScreenState();
}

class _MentalAgilityDrillsScreenState extends State<MentalAgilityDrillsScreen> {
  bool _waiting = false;
  bool _showTarget = false;
  int _startTimestamp = 0;
  int? _lastReactionMs;
  int _bestMs = 99999;
  Timer? _timer;

  void _startRound() {
    setState(() {
      _waiting = true;
      _showTarget = false;
      _lastReactionMs = null;
    });
    final delay = Duration(milliseconds: 800 + Random().nextInt(2200));
    _timer?.cancel();
    _timer = Timer(delay, () {
      setState(() {
        _showTarget = true;
        _startTimestamp = DateTime.now().millisecondsSinceEpoch;
        _waiting = false;
      });
    });
  }

  void _onTapTarget() {
    if (!_showTarget) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final reaction = now - _startTimestamp;
    setState(() {
      _lastReactionMs = reaction;
      if (reaction < _bestMs) _bestMs = reaction;
      _showTarget = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final buttonTextColor = isLightMode ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Mental Agility Drills')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Tap the circle as fast as you can when it appears.'),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _showTarget ? _onTapTarget : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _showTarget ? 160 : 120,
                    height: _showTarget ? 160 : 120,
                    decoration: BoxDecoration(
                      color: _showTarget ? accentColor : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _showTarget
                          ? const Text('TAP!', style: TextStyle(fontSize: 28, color: Colors.white))
                          : _waiting
                          ? const Text('Wait...', style: TextStyle(fontSize: 20, color: Colors.white))
                          : const Text('Ready', style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
            if (_lastReactionMs != null)
              Text('Last: ${_lastReactionMs} ms', style: const TextStyle(fontSize: 18)),
            Text('Best: ${_bestMs == 99999 ? '-' : '$_bestMs ms'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: buttonTextColor,
              ),
              onPressed: _startRound,
              child: const Text('Start Round'),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ Cognitive Flexibility ------------------
class CognitiveFlexibilityScreen extends StatefulWidget {
  const CognitiveFlexibilityScreen({super.key});
  @override
  State<CognitiveFlexibilityScreen> createState() => _CognitiveFlexibilityScreenState();
}

class _CognitiveFlexibilityScreenState extends State<CognitiveFlexibilityScreen> {
  bool _gameStarted = false;
  bool _taskA = true;
  int _score = 0;
  Timer? _roundTimer;
  int _timeLeft = 30;

  final Random _rnd = Random();
  late String _currentShape;
  late Color _currentColor;
  late String _currentColorName;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'RED', 'color': Colors.red},
    {'name': 'GREEN', 'color': Colors.green},
    {'name': 'BLUE', 'color': Colors.blue},
    {'name': 'YELLOW', 'color': Colors.yellow},
  ];

  final List<String> _shapes = ['CIRCLE', 'SQUARE', 'TRIANGLE'];

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _score = 0;
      _timeLeft = 30;
    });
    _newPrompt();
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        if (_rnd.nextInt(100) < 30) {
          _taskA = !_taskA;
        }
        _newPrompt();
      } else {
        timer.cancel();
        _showResults();
      }
    });
  }

  void _newPrompt() {
    final colorData = _colors[_rnd.nextInt(_colors.length)];
    _currentColorName = colorData['name'] as String;
    _currentColor = colorData['color'] as Color;
    _currentShape = _shapes[_rnd.nextInt(_shapes.length)];
    setState(() {});
  }

  void _onAnswer(String answer) {
    final correct = _taskA
        ? answer.toUpperCase() == _currentColorName
        : answer.toUpperCase() == _currentShape;
    if (correct) {
      _score++;
      showToast('✅ Correct!');
    } else {
      _score = (_score > 0) ? _score - 1 : 0;
      showToast('❌ Wrong!');
    }
    _newPrompt();
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Time’s up!'),
        content: Text('Your score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _gameStarted = false);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _buildShapeWidget() {
    switch (_currentShape) {
      case 'CIRCLE':
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(color: _currentColor, shape: BoxShape.circle),
        );
      case 'SQUARE':
        return Container(
          width: 120,
          height: 120,
          color: _currentColor,
        );
      case 'TRIANGLE':
        return CustomPaint(
          size: const Size(120, 120),
          painter: _TrianglePainter(_currentColor),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final buttonTextColor = isLightMode ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Cognitive Flexibility')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: !_gameStarted
            ? _buildStartScreen(accentColor, buttonTextColor)
            : Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Task: ${_taskA ? "Identify the COLOR" : "Identify the SHAPE"}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('⏳ $_timeLeft s'),
              ],
            ),
            const SizedBox(height: 20),
            _buildShapeWidget(),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.5,
                children: (_taskA ? _colors.map((c) => c['name'] as String) : _shapes)
                    .map((e) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: buttonTextColor,
                  ),
                  onPressed: () => _onAnswer(e),
                  child: Text(e),
                ))
                    .toList(),
              ),
            ),
            Text('Score: $_score', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen(Color accentColor, Color buttonTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Look at the shape and follow the task:\n\n'
                '- If task says COLOR: choose the color of the shape\n'
                '- If task says SHAPE: choose the shape type\n',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: buttonTextColor,
            ),
            onPressed: _startGame,
            child: const Text('Start Game'),
          )
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GenerativeStorytellingScreen extends StatefulWidget {
  const GenerativeStorytellingScreen({super.key});

  @override
  State<GenerativeStorytellingScreen> createState() => _GenerativeStorytellingScreenState();
}

class _GenerativeStorytellingScreenState extends State<GenerativeStorytellingScreen> {
  String? selectedEmotion;
  final TextEditingController _challengeController = TextEditingController();
  String? generatedStory;
  bool showBreathingGuide = false;
  bool isLoading = false;

  final Map<String, String> emotions = {
    '😟': 'Anxious',
    '😣': 'Frustrated',
    '😡': 'Angry',
    '😢': 'Sad',
    '😌': 'Calm',
  };

  final List<String> hintExamples = [
    'e.g., I feel nervous about exams',
    'e.g., I’m scared to try something new',
    'e.g., I don’t feel strong enough',
    'e.g., I feel stuck and hopeless',
    'e.g., I am afraid of failing again',
    'e.g., I keep overthinking about everything',
  ];
  late String randomHint;

  @override
  void initState() {
    super.initState();
    randomHint = _getRandomHint();
  }

  String _getRandomHint() {
    final random = Random();
    return hintExamples[random.nextInt(hintExamples.length)];
  }

  Future<void> generateStory() async {
    if (selectedEmotion == null || _challengeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an emotion and describe your challenge.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      generatedStory = null;
    });

    try {
      final response = await http.post(
        Uri.parse(back_url + 'api/story'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emotion": selectedEmotion,
          "belief": _challengeController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          generatedStory = data['story'] ?? 'No story generated.';
          showBreathingGuide = true;
        });
      } else {
        showToast("Error: ${response.statusCode}");
      }
    } catch (e) {
      showToast("Please connect to a stable network");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generative Storytelling"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Step 1: Select Emotion
            const Text("Step 1: Choose Your Current Emotion",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emotions.keys.map((emoji) {
                final isSelected = selectedEmotion == emotions[emoji];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedEmotion = emotions[emoji];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            /// Step 2: Describe Challenge
            const Text("Step 2: Describe your challenge or situation",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isLightMode ? Colors.grey.shade200 : Colors.grey.shade800,
                border: Border.all(
                  color: isLightMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _challengeController,
                  maxLines: null,
                  minLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: randomHint,
                    hintStyle: textTheme.bodyLarge?.copyWith(
                      color: textTheme.bodyLarge?.color?.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  style: textTheme.bodyLarge,
                  cursorColor: accentColor,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Generate Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isLightMode ? Colors.black : Colors.white,
                ),
                onPressed: isLoading ? null : generateStory,
                child: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text("Generate Story"),
              ),
            ),

            const SizedBox(height: 20),

            /// Step 3: Generated Story
            if (generatedStory != null) ...[
              const Text("Step 3: Your Personalized Story",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLightMode
                      ? Colors.teal.shade50
                      : Colors.teal.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  generatedStory!,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}



class NameItToReframeItScreen extends StatefulWidget {
  const NameItToReframeItScreen({super.key});

  @override
  State<NameItToReframeItScreen> createState() => _NameItToReframeItScreenState();
}

class _NameItToReframeItScreenState extends State<NameItToReframeItScreen> {
  String? selectedEmotion;
  final TextEditingController _beliefController = TextEditingController();
  String? reframedThought;
  bool showBreathingGuide = false;
  bool isLoading = false;

  final Map<String, String> emotions = {
    '😟': 'Anxious',
    '😣': 'Frustrated',
    '😡': 'Angry',
    '😢': 'Sad',
    '😌': 'Calm',
  };

  final List<String> hintExamples = [
    'e.g., I’ll fail this presentation',
    'e.g., I’m not good enough',
    'e.g., They probably think I’m annoying',
    'e.g., I can’t handle this situation',
    'e.g., I always mess things up',
    'e.g., I don’t deserve success',
    'e.g., I’ll never get over this',
    'e.g., Everyone is judging me',
    'e.g., I must be perfect all the time',
    'e.g., If I don’t get this right, I’m a failure',
  ];
  late String randomHint;

  @override
  void initState() {
    super.initState();
    randomHint = _getRandomHint();
  }

  String _getRandomHint() {
    final random = Random();
    return hintExamples[random.nextInt(hintExamples.length)];
  }

  Future<void> generateReframe() async {
    if (selectedEmotion == null || _beliefController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an emotion and enter your thought.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      reframedThought = null;
    });

    try {
      final response = await http.post(
        Uri.parse(back_url+'api/reframe'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emotion": selectedEmotion,
          "belief": _beliefController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reframedThought = data['reframe'];
          showBreathingGuide = true;
        });
      } else {
        showToast("Error: ${response.statusCode}");
      }
    } catch (e) {
      showToast("Please connect to a stable network");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget breathingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 15),
      duration: const Duration(seconds: 15),
      onEnd: () {
        if (mounted) setState(() {});
      },
      builder: (context, value, child) {
        String phase;
        double scale;
        Color color;

        if (value < 5) {
          phase = "Inhale";
          scale = 1.0 + (0.5 * (value / 5));
          color = Colors.greenAccent.withOpacity(0.6);
        } else if (value < 10) {
          phase = "Hold";
          scale = 1.5;
          color = Colors.blueAccent.withOpacity(0.6);
        } else {
          phase = "Exhale";
          scale = 1.5 - (0.5 * ((value - 10) / 5));
          color = Colors.purpleAccent.withOpacity(0.6);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              alignment: Alignment.center,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: Center(
                    child: Text(
                      phase,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Breathe ${phase.toLowerCase()}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Name It to Reframe It"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Step 1: Name the Emotion",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emotions.keys.map((emoji) {
                final isSelected = selectedEmotion == emotions[emoji];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedEmotion = emotions[emoji];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text("Step 2: What's the thought behind this emotion?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isLightMode ? Colors.grey.shade200 : Colors.grey.shade800,
                border: Border.all(
                  color: isLightMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _beliefController,
                  maxLines: null,
                  minLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: randomHint,
                    hintStyle: textTheme.bodyLarge?.copyWith(
                      color: textTheme.bodyLarge?.color?.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  style: textTheme.bodyLarge,
                  cursorColor: accentColor,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isLightMode ? Colors.black : Colors.white,
                ),
                onPressed: isLoading ? null : generateReframe,
                child: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text("Generate Reframe"),
              ),
            ),

            const SizedBox(height: 20),

            if (reframedThought != null) ...[
              const Text("Step 3: Your Empowering Reframe",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLightMode
                      ? Colors.teal.shade50
                      : Colors.teal.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reframedThought!,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (showBreathingGuide) ...[
              const Text("Step 4: Ground the Reframe",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Take 3 slow breaths while repeating your new belief."),
              const SizedBox(height: 20),
              Center(child: breathingAnimation()),
            ],
          ],
        ),
      ),
    );
  }
}


