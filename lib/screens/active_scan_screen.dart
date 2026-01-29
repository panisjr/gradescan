import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:math' as math;
import 'dart:io';
import '../main.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/ocr_service.dart';
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
  bool _useCloudOCR = false; // Toggle for cloud vs on-device

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
                  // Answer Key Badge
                  GestureDetector(
                    onTap: () => _showOCRSettings(),
                    child: Container(
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
                          Icon(
                            _useCloudOCR ? Icons.cloud : Icons.phone_android,
                            color: Colors.white,
                            size: 16,
                          ),
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

  void _showOCRSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'OCR Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: const Text('On-Device (ML Kit)'),
              subtitle: const Text('Free, fast, works offline'),
              trailing: Radio<bool>(
                value: false,
                groupValue: _useCloudOCR,
                onChanged: (value) {
                  setState(() => _useCloudOCR = false);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() => _useCloudOCR = false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud, color: Color(0xFF10B981)),
              ),
              title: const Text('Cloud (OCR.space)'),
              subtitle: const Text('More accurate, requires internet'),
              trailing: Radio<bool>(
                value: true,
                groupValue: _useCloudOCR,
                onChanged: (value) {
                  setState(() => _useCloudOCR = true);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() => _useCloudOCR = true);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Use good lighting and hold the camera steady for best results.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Capture image and process with OCR
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

      setState(
        () => _scanStatus = _useCloudOCR
            ? 'Sending to cloud OCR...'
            : 'Running on-device OCR...',
      );

      // Step 3: Run OCR
      final ocrResult = await OCRService.scan(
        imageFile: imageFile,
        totalQuestions: widget.answerKey.totalItems,
        optionsPerQuestion: 4,
        preferCloud: _useCloudOCR,
      );

      debugPrint('OCR Result: $ocrResult');

      setState(() => _scanStatus = 'Analyzing results...');

      // Step 4: Process results
      final result = _processOCRResult(ocrResult, image.path);

      // Step 5: Save result
      appState.addScanResult(result);

      setState(() {
        _isScanning = false;
        _scannedCount++;
        _scanStatus = 'Ready to scan';
      });

      // Step 6: Show result dialog
      if (mounted) {
        _showResultDialog(result, ocrResult);
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

  /// Crop image before OCR
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Answer Sheet',
            toolbarColor: const Color(0xFF2563EB),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
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

  /// Process OCR result into ScanResult
  ScanResult _processOCRResult(OMRResult ocrResult, String imagePath) {
    List<String> studentAnswers = ocrResult.answers;

    // Ensure we have the right number of answers
    while (studentAnswers.length < widget.answerKey.totalItems) {
      studentAnswers.add('-');
    }
    if (studentAnswers.length > widget.answerKey.totalItems) {
      studentAnswers = studentAnswers.sublist(0, widget.answerKey.totalItems);
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

    // Generate student name
    String studentName =
        ocrResult.studentName ??
        'Student ${DateTime.now().millisecondsSinceEpoch % 1000}';

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentName: studentName,
      score: score,
      totalItems: widget.answerKey.totalItems,
      studentAnswers: studentAnswers,
      correctAnswers: widget.answerKey.answers,
      scannedAt: DateTime.now(),
      answerKeyName: widget.answerKey.name,
      imagePath: imagePath,
    );
  }

  void _showResultDialog(ScanResult result, OMRResult ocrResult) {
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
                      : Icons.sentiment_dissatisfied,
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
              const SizedBox(height: 4),
              // OCR confidence indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ocrResult.confidence >= 0.7
                        ? Icons.verified
                        : Icons.warning_amber,
                    size: 14,
                    color: ocrResult.confidence >= 0.7
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(ocrResult.confidence * 100).toStringAsFixed(0)}% detection • ${ocrResult.provider}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              // Detected answers preview
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Detected: ${result.studentAnswers.join(", ")}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
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
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditAnswersDialog(result);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      child: const Text('Next'),
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

  void _showEditAnswersDialog(ScanResult result) {
    List<String> editedAnswers = List.from(result.studentAnswers);
    final options = ['A', 'B', 'C', 'D', '-'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text('Edit Answers'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: result.totalItems,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${index + 1}.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...options.map(
                        (opt) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            label: Text(opt),
                            selected: editedAnswers[index] == opt,
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(
                              color: editedAnswers[index] == opt
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              setDialogState(() {
                                editedAnswers[index] = opt;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        editedAnswers[index] == result.correctAnswers[index]
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            editedAnswers[index] == result.correctAnswers[index]
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the result with edited answers
                int newScore = 0;
                for (int i = 0; i < result.totalItems; i++) {
                  if (editedAnswers[i] == result.correctAnswers[i]) {
                    newScore++;
                  }
                }

                final updatedResult = ScanResult(
                  id: result.id,
                  studentName: result.studentName,
                  score: newScore,
                  totalItems: result.totalItems,
                  studentAnswers: editedAnswers,
                  correctAnswers: result.correctAnswers,
                  scannedAt: result.scannedAt,
                  answerKeyName: result.answerKeyName,
                  imagePath: result.imagePath,
                );

                // Update in app state (you might need to implement update method)
                // For now, remove old and add new
                appState.scanResults.removeWhere((r) => r.id == result.id);
                appState.addScanResult(updatedResult);

                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Updated: ${updatedResult.score}/${updatedResult.totalItems}',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
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
            const Text(
              'Tips for better scanning:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTip(Icons.wb_sunny, 'Ensure good, even lighting'),
            _buildTip(Icons.crop_free, 'Crop to show only answers'),
            _buildTip(Icons.straighten, 'Keep the paper flat'),
            _buildTip(Icons.pan_tool, 'Hold camera steady'),
            _buildTip(Icons.cloud, 'Try cloud OCR for better accuracy'),
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
              _captureAndProcess();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
