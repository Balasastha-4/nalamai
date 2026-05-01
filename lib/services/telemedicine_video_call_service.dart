import 'dart:async';
import 'interfaces/video_call_service_interface.dart';

class TelemedicineVideoCallService implements VideoCallService {
  final _callStatusController = StreamController<CallStatus>.broadcast();

  @override
  Stream<CallStatus> get callStatus => _callStatusController.stream;

  @override
  Future<void> startCall(String physicianId) async {
    _callStatusController.add(CallStatus.connecting);
    await Future.delayed(const Duration(seconds: 1));
    _callStatusController.add(CallStatus.connected);
  }

  @override
  Future<void> joinCall(String roomId) async {
    _callStatusController.add(CallStatus.connecting);
    await Future.delayed(const Duration(seconds: 1));
    _callStatusController.add(CallStatus.connected);
  }

  @override
  Future<void> endCall() async {
    _callStatusController.add(CallStatus.disconnected);
  }

  void dispose() {
    _callStatusController.close();
  }
}
