import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:vta_app/src/services/signalr_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  final HubConnection hubConnection;
  final String sessionId;
  final String myUserId;
  final String remoteUserId;
  
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  
  // Callbacks for UI updates
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(String)? onError;

  WebRTCService({
    required this.hubConnection,
    required this.sessionId,
    required this.myUserId,
    required this.remoteUserId,
  });

  // ICE servers configuration with COTURN server
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:localhost:3478',
          'turn:localhost:3478',
          'turn:localhost:3478?transport=tcp',
        ],
        'username': 'testuser',
        'credential': 'testpass',
      }
    ],
    'sdpSemantics': 'unified-plan',
  };

  // Peer connection constraints
  final Map<String, dynamic> _pcConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  // Media constraints - landscape orientation
  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': {
      'facingMode': 'user',
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
      'aspectRatio': {'ideal': 1.77778}, // 16:9
    }
  };

  Future<void> initialize() async {
    try {
      print('[WebRTC] Starting initialization');
      
      // Get local media stream FIRST (before peer connection)
      print('[WebRTC] Requesting user media');
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      print('[WebRTC] Got user media stream');
      onLocalStream?.call(_localStream!);

      // Set up SignalR listeners for WebRTC signaling
      _setupSignalRCallbacks();
      
      // Create peer connection AFTER getting media
      print('[WebRTC] Creating peer connection');
      final pc = await createPeerConnection(_configuration, _pcConstraints);
      
      if (pc == null) {
        throw Exception('Failed to create peer connection');
      }
      
      print('[WebRTC] Peer connection object created');
      print('[WebRTC] Setting up peer connection handlers');
      
      // Set up connection state handlers
      pc.onConnectionState = (RTCPeerConnectionState state) {
        print('[WebRTC] Connection state: $state');
      };
      
      pc.onIceConnectionState = (RTCIceConnectionState state) {
        print('[WebRTC] ICE connection state: $state');
      };
      
      pc.onIceGatheringState = (RTCIceGatheringState state) {
        print('[WebRTC] ICE gathering state: $state');
      };
      
      // Set up ICE candidate handler
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        print('[WebRTC] ICE candidate: ${candidate.candidate}');
        hubConnection.invoke('SendIceCandidate', args: [
          sessionId,
          remoteUserId,
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        ]);
      };

      // Set up remote stream handler
      pc.onTrack = (RTCTrackEvent event) {
        print('[WebRTC] Received remote track: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          // Always update the remote stream reference
          _remoteStream = event.streams[0];
          // Call the callback to update the renderer with the latest stream
          // This ensures both audio and video tracks are included
          onRemoteStream?.call(_remoteStream!);
          print('[WebRTC] Updated remote stream with ${event.track.kind} track');
        }
      };

      // Add local tracks to peer connection
      print('[WebRTC] Adding local tracks to peer connection');
      final tracks = _localStream!.getTracks();
      print('[WebRTC] Found ${tracks.length} tracks to add');
      
      for (var track in tracks) {
        print('[WebRTC] Adding track: ${track.kind} (${track.id})');
        await pc.addTrack(track, _localStream!);
        print('[WebRTC] Successfully added track: ${track.kind}');
      }

      // Store peer connection only after successfully adding all tracks
      _peerConnection = pc;
      print('[WebRTC] Initialized successfully');
      
      // NOW flush any queued WebRTC messages (offers, answers) from SignalR
      final signalR = SignalRService();
      signalR.flushWebRTCQueue();
      
      // Add any pending ICE candidates that arrived early
      if (_pendingIceCandidates.isNotEmpty) {
        print('[WebRTC] Adding ${_pendingIceCandidates.length} pending ICE candidates');
        for (var candidate in _pendingIceCandidates) {
          try {
            await _peerConnection!.addCandidate(candidate);
          } catch (e) {
            print('[WebRTC] Error adding pending ICE candidate: $e');
          }
        }
        _pendingIceCandidates.clear();
      }
    } catch (e) {
      print('[WebRTC] Initialization error: $e');
      onError?.call('Failed to initialize: $e');
      rethrow;
    }
  }

  void _setupSignalRCallbacks() {
    final signalR = SignalRService();
    
    // Register callbacks in SignalR service
    signalR.onReceiveOffer = (receivedSessionId, offer) async {
      if (receivedSessionId != sessionId) {
        print('[WebRTC] Ignoring offer for different session: $receivedSessionId != $sessionId');
        return;
      }
      
      print('[WebRTC] Received offer');
      try {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );
        
        // Create answer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        
        // Send answer back
        await hubConnection.invoke('SendAnswer', args: [
          sessionId,
          remoteUserId,
          {
            'sdp': answer.sdp,
            'type': answer.type,
          }
        ]);
        print('[WebRTC] Sent answer');
      } catch (e) {
        print('[WebRTC] Error handling offer: $e');
        onError?.call('Failed to handle offer: $e');
      }
    };

    signalR.onReceiveAnswer = (receivedSessionId, answer) async {
      if (receivedSessionId != sessionId) {
        print('[WebRTC] Ignoring answer for different session: $receivedSessionId != $sessionId');
        return;
      }
      
      print('[WebRTC] Received answer');
      try {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], answer['type']),
        );
      } catch (e) {
        print('[WebRTC] Error handling answer: $e');
        onError?.call('Failed to handle answer: $e');
      }
    };

    signalR.onReceiveIceCandidate = (receivedSessionId, candidateData) async {
      if (receivedSessionId != sessionId) {
        print('[WebRTC] Ignoring ICE candidate for different session: $receivedSessionId != $sessionId');
        return;
      }
      
      print('[WebRTC] Received ICE candidate');
      try {
        final candidate = RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        );
        
        if (_peerConnection == null) {
          print('[WebRTC] Peer connection not ready, queuing ICE candidate');
          _pendingIceCandidates.add(candidate);
        } else {
          await _peerConnection!.addCandidate(candidate);
          print('[WebRTC] Successfully added ICE candidate');
        }
      } catch (e) {
        print('[WebRTC] Error adding ICE candidate: $e');
      }
    };
  }

  Future<void> startCall() async {
    try {
      print('[WebRTC] Starting call (creating offer)');
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      // Send offer via SignalR
      await hubConnection.invoke('SendOffer', args: [
        sessionId,
        remoteUserId,
        {
          'sdp': offer.sdp,
          'type': offer.type,
        }
      ]);
      print('[WebRTC] Sent offer');
    } catch (e) {
      print('[WebRTC] Error starting call: $e');
      onError?.call('Failed to start call: $e');
    }
  }

  void toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream! .getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  void toggleCamera() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = !videoTrack.enabled;
    }
  }

  Future<void> dispose() async {
    print('[WebRTC] Disposing...');
    
    // Clear SignalR callbacks
    final signalR = SignalRService();
    if (signalR.onReceiveOffer != null || signalR.onReceiveAnswer != null || signalR.onReceiveIceCandidate != null) {
      print('[WebRTC] Clearing SignalR callbacks for session: $sessionId');
      signalR.onReceiveOffer = null;
      signalR.onReceiveAnswer = null;
      signalR.onReceiveIceCandidate = null;
    }
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    await _peerConnection?.close();
    _peerConnection?.dispose();
  }
}