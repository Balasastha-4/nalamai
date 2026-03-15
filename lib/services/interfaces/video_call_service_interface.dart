abstract class VideoCallService {
  Future<void> startCall(String physicianId);
  Future<void> joinCall(String roomId);
  Future<void> endCall();
  Stream<CallStatus> get callStatus;
}

enum CallStatus { connecting, connected, disconnected, failed }
