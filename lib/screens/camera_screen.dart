import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // ------------------------------------------------------------
  // TEXT TO SPEECH
  // ------------------------------------------------------------

  final FlutterTts _tts = FlutterTts();

  // YOLO controller
  final YOLOViewController _controller = YOLOViewController();

  // ------------------------------------------------------------
  // UI STATE
  // ------------------------------------------------------------

  String _status = 'Starting VisionGuide...';

  String _objectName = 'Waiting for object';

  String _position = '—';

  String _distance = '—';

  double _confidence = 0.0;

  // ------------------------------------------------------------
  // SPEECH CONTROL
  // ------------------------------------------------------------

  String _lastSpokenMessage = '';

  DateTime _lastSpeechTime =
      DateTime.fromMillisecondsSinceEpoch(0);

  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------

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

  // ============================================================
  // PHASE 3 + PHASE 4
  // PROCESS YOLO DETECTION
  // ============================================================

  void _onDetectionResults(List<YOLOResult> results) {
    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // No object detected
    // ----------------------------------------------------------

    if (results.isEmpty) {
      setState(() {
        _status = 'Scanning surroundings...';

        _objectName = 'No object';

        _position = '—';

        _distance = '—';

        _confidence = 0.0;
      });

      return;
    }

    // ----------------------------------------------------------
    // Select the most relevant object
    //
    // We choose the object with the largest bounding box.
    // Larger box generally means the object is closer.
    // ----------------------------------------------------------

    final sortedResults = [...results];

    sortedResults.sort(
      (a, b) {
        final areaA =
            a.normalizedBox.width.abs() *
            a.normalizedBox.height.abs();

        final areaB =
            b.normalizedBox.width.abs() *
            b.normalizedBox.height.abs();

        return areaB.compareTo(areaA);
      },
    );

    final YOLOResult mainObject =
        sortedResults.first;

    // ----------------------------------------------------------
    // PHASE 3
    // Determine object position
    // ----------------------------------------------------------

    final String position =
        _getPosition(mainObject);

    // ----------------------------------------------------------
    // PHASE 4
    // Estimate relative distance
    // ----------------------------------------------------------

    final String distance =
        _getDistance(mainObject);

    final String objectName =
        mainObject.className;

    final double confidence =
        mainObject.confidence;

    // ----------------------------------------------------------
    // UPDATE SCREEN
    // ----------------------------------------------------------

    setState(() {
      _status = 'Object detected';

      _objectName = objectName;

      _position = position;

      _distance = distance;

      _confidence = confidence;
    });

    // ----------------------------------------------------------
    // VOICE OUTPUT
    // ----------------------------------------------------------

    _speakDetection(
      mainObject,
      position,
      distance,
    );
  }

  // ============================================================
  // PHASE 3
  // OBJECT POSITION
  // ============================================================

  String _getPosition(YOLOResult result) {
    final Rect box =
        result.normalizedBox;

    // Bounding-box center
    final double centerX =
        box.center.dx;

    // LEFT THIRD
    if (centerX < 0.33) {
      return 'LEFT';
    }

    // RIGHT THIRD
    if (centerX > 0.66) {
      return 'RIGHT';
    }

    // MIDDLE THIRD
    return 'CENTER';
  }

  // ============================================================
  // PHASE 4
  // RELATIVE DISTANCE ESTIMATION
  // ============================================================

  String _getDistance(YOLOResult result) {
    final Rect box =
        result.normalizedBox;

    // Calculate bounding-box area
    final double width =
        box.width.abs();

    final double height =
        box.height.abs();

    final double area =
        width * height;

    // ----------------------------------------------------------
    // LARGE OBJECT
    // Object occupies large portion of camera frame
    // ----------------------------------------------------------

    if (area >= 0.35) {
      return 'NEAR';
    }

    // ----------------------------------------------------------
    // MEDIUM OBJECT
    // ----------------------------------------------------------

    if (area >= 0.12) {
      return 'MEDIUM';
    }

    // ----------------------------------------------------------
    // SMALL OBJECT
    // ----------------------------------------------------------

    return 'FAR';
  }

  // ============================================================
  // VOICE GUIDANCE
  // ============================================================

  Future<void> _speakDetection(
    YOLOResult result,
    String position,
    String distance,
  ) async {
    final double confidence =
        result.confidence;

    // Ignore low-confidence detections
    if (confidence < 0.40) {
      return;
    }

    final String objectName =
        result.className;

    // Example:
    // "Chair, left, medium"

    final String message =
        '$objectName, $position, $distance';

    final DateTime now =
        DateTime.now();

    final bool enoughTimePassed =
        now
            .difference(_lastSpeechTime)
            .inMilliseconds >
        2500;

    final bool objectChanged =
        message != _lastSpokenMessage;

    // Prevent the same message from
    // being spoken continuously.

    if (!enoughTimePassed &&
        !objectChanged) {
      return;
    }

    _lastSpeechTime = now;

    _lastSpokenMessage = message;

    try {
      await _tts.stop();

      await _tts.speak(message);
    } catch (e) {
      debugPrint(
        'TTS error: $e',
      );
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    _tts.stop();

    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // USER INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,

        title: const Text(
          'VisionGuide',
        ),

        centerTitle: true,
      ),

      body: Stack(
        fit: StackFit.expand,

        children: [

          // ----------------------------------------------------
          // CAMERA + YOLO
          // ----------------------------------------------------

          YOLOView(
            modelPath: 'yolo26n',

            controller: _controller,

            task: YOLOTask.detect,

            confidenceThreshold: 0.40,

            onResult:
                _onDetectionResults,

            onModelLoad:
                (modelPath, task) {
              if (!mounted) {
                return;
              }

              setState(() {
                _status =
                    'VisionGuide is ready';
              });
            },

            onModelError:
                (error, modelPath, task) {
              if (!mounted) {
                return;
              }

              setState(() {
                _status =
                    'Camera / AI error';
              });

              debugPrint(
                'YOLO model error: $error',
              );
            },
          ),

          // ----------------------------------------------------
          // TOP STATUS
          // ----------------------------------------------------

          Positioned(
            top: 20,
            left: 20,
            right: 20,

            child: Container(
              padding:
                  const EdgeInsets.all(14),

              decoration:
                  BoxDecoration(
                color:
                    Colors.black.withOpacity(
                  0.75,
                ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 14,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      _status,

                      style:
                          const TextStyle(
                        color: Colors.white,

                        fontSize: 16,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------
          // INFORMATION PANEL
          // ----------------------------------------------------

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,

            child: Container(
              padding:
                  const EdgeInsets.all(18),

              decoration:
                  BoxDecoration(
                color:
                    Colors.black.withOpacity(
                  0.88,
                ),

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                border:
                    Border.all(
                  color: Colors.white24,
                ),
              ),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  // Object
                  Row(
                    children: [

                      const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 30,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: Text(
                          _objectName,

                          style:
                              const TextStyle(
                            color: Colors.white,

                            fontSize: 24,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        '${(_confidence * 100).round()}%',

                        style:
                            const TextStyle(
                          color:
                              Colors.white70,

                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ------------------------------------------------
                  // POSITION + DISTANCE
                  // ------------------------------------------------

                  Row(
                    children: [

                      Expanded(
                        child:
                            _infoCard(
                          Icons
                              .compare_arrows,
                          'POSITION',
                          _position,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            _infoCard(
                          Icons
                              .social_distance,
                          'DISTANCE',
                          _distance,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Real-time visual assistance',

                    style:
                        TextStyle(
                      color:
                          Colors.white60,

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

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _infoCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 10,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child: Column(
        children: [

          Icon(
            icon,

            color: Colors.white,

            size: 28,
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            title,

            style:
                const TextStyle(
              color:
                  Colors.white60,

              fontSize: 11,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            value,

            style:
                const TextStyle(
              color: Colors.white,

              fontSize: 18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
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
}*/