import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import 'package:waveform_recorder/waveform_recorder.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _textController = TextEditingController();
  final _waveController = WaveformRecorderController();
  final _amplitudes = List<Amplitude>.empty(growable: true);

  @override
  void dispose() {
    _textController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('WaveForm Example')),
          body: ListenableBuilder(
            listenable: _waveController,
            builder: (context, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _waveController.isRecording
                              ? WaveformRecorder(
                                  height: 48,
                                  controller: _waveController,
                                  onRecordingStopped: _onRecordingStopped,
                                )
                              : TextField(
                                  controller: _textController,
                                  maxLines: 1,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const Gap(8),
                      if (_waveController.isRecording)
                        IconButton(
                          tooltip: _waveController.isPaused
                              ? 'Resume Recording'
                              : 'Pause Recording',
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _waveController.isPaused
                                  ? Colors.purple
                                  : Colors.orange,
                            ),
                            child: Center(
                              child: Icon(
                                _waveController.isPaused
                                    ? Icons.fiber_manual_record
                                    : Icons.pause,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          onPressed: _togglePauseRecording,
                        ),
                      if (_waveController.isRecording)
                        IconButton(
                          tooltip: 'Cancel Recording',
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          onPressed: _cancelRecording,
                        ),
                      IconButton(
                        tooltip: _waveController.isRecording
                            ? 'Stop Recording'
                            : 'Start Recording',
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _waveController.isRecording
                                ? Colors.blue
                                : Colors.green,
                          ),
                          child: Center(
                            child: Icon(
                              _waveController.isRecording
                                  ? Icons.stop
                                  : Icons.mic,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onPressed: _toggleRecording,
                      ),
                      IconButton(
                        tooltip: _waveController.isRecording
                            ? ''
                            : _waveController.file != null
                                ? 'Play Recording'
                                : 'No recording to play',
                        onPressed: !_waveController.isRecording &&
                                _waveController.file != null
                            ? _playRecording
                            : null,
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !_waveController.isRecording &&
                                    _waveController.file != null
                                ? Colors.yellow
                                : Colors.grey,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _waveController.file != null
                            ? 'Delete Recording'
                            : '',
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _waveController.file != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onPressed: _waveController.file != null
                            ? _deleteRecording
                            : null,
                      ),
                    ],
                  ),
                ),
                if (!_waveController.isRecording && _amplitudes.isNotEmpty)
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 300,
                        height: 100,
                        child: AnimatedWaveList(
                          stream: Stream.fromIterable(_amplitudes),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Future<void> _toggleRecording() async {
    if (_waveController.isRecording) {
      await _waveController.stopRecording();
    } else {
      await _waveController.startRecording();
      _waveController.amplitudeStream.listen(_amplitudes.add);
    }
  }

  Future<void> _cancelRecording() async {
    await _waveController.cancelRecording();
    _textController.text = 'canceled';
  }

  Future<void> _togglePauseRecording() => switch (_waveController.isPaused) {
        true => _waveController.resumeRecording(),
        false => _waveController.pauseRecording(),
      };

  Future<void> _onRecordingStopped() async {
    final file = _waveController.file;
    if (file == null) return;

    _textController.text = ''
        '${file.name}: '
        '${_waveController.length.inMilliseconds / 1000} seconds';

    debugPrint('XFile properties:');
    debugPrint('  path: ${file.path}');
    debugPrint('  name: ${file.name}');
    debugPrint('  mimeType: ${file.mimeType}');

    // download file from web to ensure it's a playable set of bytes
    // assert(await () async {
    //   await PlatformHelper.downloadFile(file);
    //   return true;
    // }());
  }

  Future<void> _deleteRecording() async {
    final file = _waveController.file;
    if (file == null) return;

    _amplitudes.clear();
    _waveController.clear();
    if (!kIsWeb) await File(file.path).delete();
    _textController.text = '';
  }

  Future<void> _playRecording() async {
    final file = _waveController.file;
    if (file == null) return;
    final source = kIsWeb ? UrlSource(file.path) : DeviceFileSource(file.path);
    await AudioPlayer().play(source);
  }
}
