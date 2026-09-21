import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final FlutterTts _tts = FlutterTts();

  final YOLOViewController _controller = YOLOViewController();

  String _status = 'Loading object detector...';

  String _lastSpoken = '';

  DateTime _lastSpeechTime =
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS setup error: $e');
    }
  }

  void _onDetectionResults(List<YOLOResult> results) {
    if (!mounted) {
      return;
    }

    if (results.isEmpty) {
      setState(() {
        _status = 'No object detected';
      });
      return;
    }

    final List<String> detectedObjects = [];

    for (final result in results.take(3)) {
      final String label = result.className;

      final int confidence =
          (result.confidence * 100).round();

      final String position =
          _getPosition(result);

      final String distance =
          _getDistance(result);

      detectedObjects.add(
        '$label $confidence%\n'
        '$position • $distance',
      );
    }

    setState(() {
      _status = detectedObjects.join('\n\n');
    });

    _speakDetection(results.first);
  }

  String _getPosition(YOLOResult result) {
    // normalizedBox values are between 0 and 1.
    final Rect box = result.normalizedBox;

    final double centerX = box.center.dx;

    if (centerX < 0.33) {
      return 'LEFT';
    }

    if (centerX > 0.66) {
      return 'RIGHT';
    }

    return 'CENTER';
  }

  String _getDistance(YOLOResult result) {
    // Use the normalized bounding-box area.
    //
    // Larger object in the camera frame
    // = approximately closer.
    //
    // This is a relative estimate, NOT actual
    // physical distance in metres.

    final Rect box = result.normalizedBox;

    final double width = box.width.abs();
    final double height = box.height.abs();

    final double area = width * height;

    if (area >= 0.35) {
      return 'NEAR';
    }

    if (area >= 0.12) {
      return 'MEDIUM';
    }

    return 'FAR';
  }

  Future<void> _speakDetection(
    YOLOResult result,
  ) async {
    final String label = result.className;

    final double confidence =
        result.confidence;

    // Ignore detections below 40%.
    if (confidence < 0.40) {
      return;
    }

    final String position =
        _getPosition(result);

    final String distance =
        _getDistance(result);

    final String message =
        '$label, $position, $distance';

    final DateTime now = DateTime.now();

    final bool enoughTimePassed =
        now
                .difference(_lastSpeechTime)
                .inMilliseconds >
            2500;

    final bool objectChanged =
        message != _lastSpoken;

    if (!enoughTimePassed && !objectChanged) {
      return;
    }

    _lastSpeechTime = now;
    _lastSpoken = message;

    try {
      await _tts.stop();

      await _tts.speak(message);
    } catch (e) {
      debugPrint(
        'TTS error: $e',
      );
    }
  }

  @override
  void dispose() {
    _tts.stop();

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text(
          'VisionGuide',
        ),
      ),

      body: Stack(
        fit: StackFit.expand,

        children: [
          YOLOView(
            modelPath: 'yolo26n',

            controller: _controller,

            task: YOLOTask.detect,

            confidenceThreshold: 0.40,

            onResult: _onDetectionResults,

            onModelLoad:
                (modelPath, task) {
              if (!mounted) {
                return;
              }

              setState(() {
                _status =
                    'Point the camera at an object';
              });
            },

            onModelError:
                (error, modelPath, task) {
              if (!mounted) {
                return;
              }

              setState(() {
                _status =
                    'Detector error';
              });

              debugPrint(
                'YOLO model error: $error',
              );
            },
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 25,

            child: Container(
              padding:
                  const EdgeInsets.all(16),

              decoration:
                  BoxDecoration(
                color: Colors.black
                    .withOpacity(0.78),

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.visibility,

                    color: Colors.white,

                    size: 30,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    _status,

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      color: Colors.white,

                      fontSize: 20,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'YOLO object detection active',

                    style:
                        TextStyle(
                      color:
                          Colors.white70,

                      fontSize: 14,
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