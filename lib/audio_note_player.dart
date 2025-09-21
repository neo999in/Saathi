import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioNotePlayer extends StatefulWidget {
  final String filePath;
  const AudioNotePlayer({super.key, required this.filePath});

  @override
  State<AudioNotePlayer> createState() => _AudioNotePlayerState();
}

class _AudioNotePlayerState extends State<AudioNotePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _initializeAudio();

    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _currentPosition = p);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (d.inSeconds > 0) {
        setState(() => _totalDuration = d);
      }
    });
  }

  Future<void> _initializeAudio() async {
    final file = File(widget.filePath);
    if (await file.exists()) {
      await _audioPlayer.setSource(DeviceFileSource(widget.filePath));
      final duration = await _audioPlayer.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        setState(() => _totalDuration = duration);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file not found.')),
      );
    }
  }

  void _playPause() async {
    final file = File(widget.filePath);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file not found.')),
      );
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Make sure source is set
      await _audioPlayer.setSource(DeviceFileSource(widget.filePath));

      // Update duration
      final duration = await _audioPlayer.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        setState(() => _totalDuration = duration);
      }

      await _audioPlayer.resume();
    }
  }

  void _seekTo(double seconds) {
    final position = Duration(seconds: seconds.toInt());
    _audioPlayer.seek(position);
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_format(_currentPosition)),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _playPause,
              color: accentColor,
            ),
            Text(_format(_totalDuration)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[300],
            thumbColor: accentColor,
            overlayColor: accentColor.withOpacity(0.2),
          ),
          child: Slider(
            value: _currentPosition.inSeconds.toDouble().clamp(0.0, _totalDuration.inSeconds.toDouble()),
            min: 0,
            max: _totalDuration.inSeconds.toDouble().clamp(1, double.infinity),
            onChanged: _seekTo,
          ),
        ),
      ],
    );
  }
}
