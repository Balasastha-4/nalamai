import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../services/telemedicine_video_call_service.dart';
import '../services/interfaces/video_call_service_interface.dart';
import '../theme/app_theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final bool isInitiator;

  const VideoCallScreen({
    super.key,
    required this.roomId,
    this.isInitiator = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _cameraController;
  final TelemedicineVideoCallService _callService = TelemedicineVideoCallService();
  StreamSubscription? _statusSub;

  String _statusLabel = "Connecting...";
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initCallAndCamera();
  }

  Future<void> _initCallAndCamera() async {
    // 1. Initialize camera
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }

    // 2. Connect to the video call
    _statusSub = _callService.callStatus.listen((status) {
      if (!mounted) return;
      setState(() {
        switch (status) {
          case CallStatus.connecting:
            _statusLabel = "Dialing & handshake...";
            break;
          case CallStatus.connected:
            _statusLabel = "In Call";
            _isConnected = true;
            break;
          case CallStatus.disconnected:
            _statusLabel = "Call Ended";
            _isConnected = false;
            break;
          case CallStatus.failed:
            _statusLabel = "Call Failed";
            _isConnected = false;
            break;
        }
      });
    });

    if (widget.isInitiator) {
      await _callService.startCall(widget.roomId);
    } else {
      await _callService.joinCall(widget.roomId);
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _cameraController?.dispose();
    _callService.endCall();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
  }

  Future<void> _hangUp() async {
    await _callService.endCall();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video View (Main Viewport)
            Positioned.fill(
              child: _isConnected
                  ? Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryBlue,
                              child: Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.isInitiator ? 'Dr. Sarah Smith' : 'Patient #${widget.roomId}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Video transmission established.',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          _statusLabel,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    ),
            ),

            // Local Camera Preview (PIP overlay on bottom-right)
            if (_cameraController != null && _cameraController!.value.isInitialized && !_isVideoOff)
              Positioned(
                right: 16,
                bottom: 120,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),

            // Control Actions Panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Audio
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _isMuted ? Colors.red : Colors.grey[800],
                      child: IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                        onPressed: _toggleMute,
                      ),
                    ),

                    // End Call / Hang Up
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _hangUp,
                      ),
                    ),

                    // Video toggle
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _isVideoOff ? Colors.red : Colors.grey[800],
                      child: IconButton(
                        icon: Icon(
                          _isVideoOff ? Icons.videocam_off : Icons.videocam,
                          color: Colors.white,
                        ),
                        onPressed: _toggleVideo,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Call Meta Overlay (App Title/ID)
            Positioned(
              top: 24,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 8),
                        Text(
                          _statusLabel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _hangUp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
