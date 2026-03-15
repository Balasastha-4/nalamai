import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'scanned_data_screen.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  // ... (Lifecycle and Camera Initialization methods remain same)

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera on resume only if it was previously initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission'),
            content: const Text(
              'Camera permission is permanently denied. Please enable it in settings to scan documents.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan documents.'),
          ),
        );
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use the first back-facing camera
        final camera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_controller!.value.isTakingPicture) return;

      final XFile file = await _controller!.takePicture();
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ScannedDataScreen(imagePath: file.path),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = 0.0;
                  const end = 1.0;
                  const curve = Curves.easeInOut;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return FadeTransition(
                    opacity: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Edge Detection Overlay (Visual Only)
          AnimatedBuilder(
            animation: _scanAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: EdgeDetectionOverlayPainter(
                  scanValue: _scanAnimationController.value,
                ),
                child: Container(),
              );
            },
          ),

          // Top Controls
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                    const Text(
                      'Scan Document',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls (Capture)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              height: 180,
              width: double.infinity,
              child: Center(
                child: GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white.withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Instructions Text
          const Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align document within the frame',
                style: TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EdgeDetectionOverlayPainter extends CustomPainter {
  final double scanValue;

  EdgeDetectionOverlayPainter({required this.scanValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double cornerLength = 40.0;
    final double margin = 40.0;
    final Rect rect = Rect.fromLTWH(
      margin,
      size.height * 0.2,
      size.width - (margin * 2),
      size.height * 0.5,
    );

    // Draw corners
    // Top Left
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(0, cornerLength),
      paint,
    );

    // Top Right
    canvas.drawLine(
      rect.topRight,
      rect.topRight - Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(0, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - Offset(0, cornerLength),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(0, cornerLength),
      paint,
    );

    // Add semi-transparent overlay outside the scan area
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw Scanning Line
    final double scanY = rect.top + (rect.height * scanValue);
    final scanLinePaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [Colors.transparent, AppTheme.primaryBlue, Colors.transparent],
      ).createShader(Rect.fromLTWH(rect.left, scanY, rect.width, 2.0));

    canvas.drawLine(
      Offset(rect.left, scanY),
      Offset(rect.right, scanY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant EdgeDetectionOverlayPainter oldDelegate) =>
      oldDelegate.scanValue != scanValue;
}
