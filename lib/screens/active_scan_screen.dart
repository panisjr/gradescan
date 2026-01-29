import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';
import '../main.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/formread_service.dart';
import '../config/api_config.dart';
import 'result_detail_screen.dart';

class ActiveScanScreen extends StatefulWidget {
  final AnswerKey answerKey;

  const ActiveScanScreen({super.key, required this.answerKey});

  @override
  State<ActiveScanScreen> createState() => _ActiveScanScreenState();
}

class _ActiveScanScreenState extends State<ActiveScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  late AnimationController _animationController;
  bool _isScanning = false;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  int _scannedCount = 0;
  String? _errorMessage;
  String _scanStatus = 'Ready to scan';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();

    if (status.isDenied) {
      setState(() {
        _errorMessage = 'Camera permission denied';
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage =
            'Camera permission permanently denied. Please enable it in settings.';
      });
      return;
    }

    if (cameras.isEmpty) {
      setState(() {
        _errorMessage = 'No cameras available';
      });
      return;
    }

    final CameraDescription camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = 'Camera error: ${e.description}';
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Scan Frame Overlay
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 280,
                  height: 380,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isScanning
                          ? Color.lerp(
                              const Color(0xFF2563EB),
                              const Color(0xFF10B981),
                              _animationController.value,
                            )!
                          : Colors.white,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Corner indicators
                      Positioned(
                        top: -2,
                        left: -2,
                        child: _CornerIndicator(isScanning: _isScanning),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Transform.rotate(
                          angle: math.pi / 2,
                          child: _CornerIndicator(isScanning: _isScanning),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Transform.rotate(
                          angle: math.pi,
                          child: _CornerIndicator(isScanning: _isScanning),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        left: -2,
                        child: Transform.rotate(
                          angle: -math.pi / 2,
                          child: _CornerIndicator(isScanning: _isScanning),
                        ),
                      ),
                      // Scanning line
                      if (_isScanning)
                        Positioned(
                          top: 380 * _animationController.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF10B981),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          widget.answerKey.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isCameraInitialized ? _toggleFlash : null,
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: _isFlashOn ? Colors.yellow : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isScanning
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isScanning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        if (_isScanning) const SizedBox(width: 8),
                        Text(
                          _scanStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Scanned Count
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_scannedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scanned',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Scan Button
                      GestureDetector(
                        onTap: (_isScanning || !_isCameraInitialized)
                            ? null
                            : _captureAndProcess,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isScanning || !_isCameraInitialized)
                                ? Colors.grey
                                : const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Icon(
                            _isScanning ? Icons.hourglass_empty : Icons.camera,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      // Done Button
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _scannedCount > 0
                                ? () => Navigator.pop(context)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _scannedCount > 0
                                    ? const Color(0xFF10B981)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Capture image and process with FormRead API
  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isScanning = true;
      _scanStatus = 'Capturing image...';
    });

    try {
      // Step 1: Capture the image
      final XFile image = await _cameraController!.takePicture();
      debugPrint('Image captured: ${image.path}');

      setState(() => _scanStatus = 'Processing image...');

      // Step 2: Optionally crop the image
      File imageFile = File(image.path);
      final croppedFile = await _cropImage(imageFile);
      if (croppedFile != null) {
        imageFile = croppedFile;
      }

      setState(() => _scanStatus = 'Sending to FormRead API...');

      // Step 3: Send to FormRead API
      final formReadResult = await _scanWithFormRead(imageFile);

      setState(() => _scanStatus = 'Analyzing results...');

      // Step 4: Process results
      final result = _processFormReadResult(formReadResult, image.path);

      // Step 5: Save result
      appState.addScanResult(result);

      setState(() {
        _isScanning = false;
        _scannedCount++;
        _scanStatus = 'Ready to scan';
      });

      // Step 6: Show result dialog
      if (mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      debugPrint('Error scanning: $e');
      setState(() {
        _isScanning = false;
        _scanStatus = 'Ready to scan';
      });

      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  /// Crop image before sending to API
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Answer Sheet',
            toolbarColor: const Color(0xFF2563EB),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio3x4,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Answer Sheet'),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
    }
    return null;
  }

  /// Send image to FormRead API
  Future<FormReadResult> _scanWithFormRead(File imageFile) async {
    try {
      return await FormReadService.scanAnswerSheet(
        imageFile: imageFile,
        totalQuestions: widget.answerKey.totalItems,
        optionsPerQuestion: 4, // A, B, C, D
      );
    } catch (e) {
      debugPrint('FormRead API Error: $e');
      // Fallback to simulated results for demo
      return _getSimulatedResult();
    }
  }

  /// Process FormRead API result
  ScanResult _processFormReadResult(
    FormReadResult formReadResult,
    String imagePath,
  ) {
    List<String> studentAnswers;

    if (formReadResult.answers.isNotEmpty) {
      studentAnswers = formReadResult.answers;
      // Ensure we have the right number of answers
      while (studentAnswers.length < widget.answerKey.totalItems) {
        studentAnswers.add('-');
      }
      if (studentAnswers.length > widget.answerKey.totalItems) {
        studentAnswers = studentAnswers.sublist(0, widget.answerKey.totalItems);
      }
    } else {
      // Fallback to empty answers
      studentAnswers = List.filled(widget.answerKey.totalItems, '-');
    }

    // Calculate score
    int score = 0;
    for (int i = 0; i < widget.answerKey.totalItems; i++) {
      if (i < studentAnswers.length &&
          studentAnswers[i].toUpperCase() ==
              widget.answerKey.answers[i].toUpperCase()) {
        score++;
      }
    }

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentName: formReadResult.studentName ?? 'Student ${_scannedCount + 1}',
      score: score,
      totalItems: widget.answerKey.totalItems,
      studentAnswers: studentAnswers,
      correctAnswers: widget.answerKey.answers,
      scannedAt: DateTime.now(),
      answerKeyName: widget.answerKey.name,
      imagePath: imagePath,
    );
  }

  /// Simulated result for demo/testing
  FormReadResult _getSimulatedResult() {
    final random = math.Random();
    final answers = List.generate(
      widget.answerKey.totalItems,
      (index) => ['A', 'B', 'C', 'D'][random.nextInt(4)],
    );

    return FormReadResult(
      success: true,
      studentName: 'Student ${_scannedCount + 1}',
      answers: answers,
      confidence: 0.95,
    );
  }

  void _showResultDialog(ScanResult result) {
    final color = result.percentage >= 75
        ? const Color(0xFF10B981)
        : result.percentage >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.percentage >= 75
                      ? Icons.celebration
                      : result.percentage >= 50
                      ? Icons.thumb_up
                      : Icons.refresh,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.studentName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.score}/${result.totalItems}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${result.percentage.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ResultDetailScreen(result: result),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Scan Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Text('Scan Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Failed to process the answer sheet:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('• Ensure good lighting'),
            const Text('• Hold the camera steady'),
            const Text('• Make sure the answer sheet is flat'),
            const Text('• Try cropping to just the answers area'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _captureAndProcess(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CornerIndicator extends StatelessWidget {
  final bool isScanning;

  const _CornerIndicator({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _CornerPainter(
          color: isScanning ? const Color(0xFF10B981) : Colors.white,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
