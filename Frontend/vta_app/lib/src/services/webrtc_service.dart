import 'package:flutter/foundation.dart';
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
  
  bool hasLocalVideo = false;
  bool hasLocalAudio = false;
  bool hasRemoteVideo = false;
  bool hasRemoteAudio = false;
    
  bool _remoteOffersVideo = false;
  bool _remoteOffersAudio = false;

  // Callbacks for UI updates
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(String)? onError;
  Function(bool hasVideo, bool hasAudio)? onLocalMediaAvailability;
  Function(bool hasVideo, bool hasAudio)? onRemoteMediaAvailability;
  Function()? onConnectionEstablished;

  WebRTCService({
    required this.hubConnection,
    required this.sessionId,
    required this.myUserId,
    required this.remoteUserId,
  });

  // ICE/TURN/STUN servers configuration with COTURN server
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

  // Media constraints
  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': {
      'facingMode': 'user',
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
      'aspectRatio': {'ideal': 1.77778}, // 16:9
    }
  };

  Future<void> _requestUserMedia() async {
    // Try to get both video and audio
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      hasLocalVideo = _localStream!.getVideoTracks().isNotEmpty;
      hasLocalAudio = _localStream!.getAudioTracks().isNotEmpty;
      debugPrint('[WebRTC] Got both video and audio');
      return;
    } catch (e) {
      debugPrint('[WebRTC] Failed to get both video and audio: $e');
    }
    
    // Try video only
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': _mediaConstraints['video'],
      });
      hasLocalVideo = _localStream!.getVideoTracks().isNotEmpty;
      hasLocalAudio = false;
      debugPrint('[WebRTC] Got video only');
      return;
    } catch (e) {
      debugPrint('[WebRTC] Failed to get video: $e');
    }
    
    // Try audio only
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
      });
      hasLocalVideo = false;
      hasLocalAudio = _localStream!.getAudioTracks().isNotEmpty;
      debugPrint('[WebRTC] Got audio only');
      return;
    } catch (e) {
      debugPrint('[WebRTC] Failed to get audio: $e');
    }
    
    // Continue without media
    debugPrint('[WebRTC] No media available, continuing with data channel only');
    hasLocalVideo = false;
    hasLocalAudio = false;
    _localStream = null;
  }

  Future<void> initialize() async {
    try {
      debugPrint('[WebRTC] Starting initialization');
      
      // Try to get local media with fallbacks
      debugPrint('[WebRTC] Requesting user media');
      await _requestUserMedia();
      
      if (_localStream != null) {
        debugPrint('[WebRTC] Got local media stream (video: $hasLocalVideo, audio: $hasLocalAudio)');
        onLocalStream?.call(_localStream!);
        onLocalMediaAvailability?.call(hasLocalVideo, hasLocalAudio);
      } else {
        debugPrint('[WebRTC] No local media available, continuing without it');
        onLocalMediaAvailability?.call(false, false);
      }

      // Set up SignalR listeners for WebRTC signaling
      _setupSignalRCallbacks();
      
      // Create peer connection after getting media
      debugPrint('[WebRTC] Creating peer connection');
      final pc = await createPeerConnection(_configuration, _pcConstraints);
      
      debugPrint('[WebRTC] Peer connection object created');
      debugPrint('[WebRTC] Setting up peer connection handlers');
      
      // Set up connection state handlers
      pc.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('[WebRTC] Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          onConnectionEstablished?.call();
        }
      };
      
      pc.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('[WebRTC] ICE connection state: $state');
      };
      
      pc.onIceGatheringState = (RTCIceGatheringState state) {
        debugPrint('[WebRTC] ICE gathering state: $state');
      };
      
      // Set up ICE candidate handler
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        debugPrint('[WebRTC] ICE candidate: ${candidate.candidate}');
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
        debugPrint('[WebRTC] Received remote track: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          
          if (event.track.kind == 'video') {
            hasRemoteVideo = true;
            debugPrint('[WebRTC] Remote video track received');
          } else if (event.track.kind == 'audio') {
            hasRemoteAudio = true;
            debugPrint('[WebRTC] Remote audio track received');
          }
          
          onRemoteStream?.call(_remoteStream!);
          onRemoteMediaAvailability?.call(hasRemoteVideo, hasRemoteAudio);
          
          debugPrint('[WebRTC] Remote media state: video=$hasRemoteVideo, audio=$hasRemoteAudio');
        }
      };

      // Add local tracks to peer connection
      if (_localStream != null) {
        debugPrint('[WebRTC] Adding local tracks to peer connection');
        final tracks = _localStream!.getTracks();
        debugPrint('[WebRTC] Found ${tracks.length} tracks to add');
        
        for (var track in tracks) {
          debugPrint('[WebRTC] Adding track: ${track.kind} (${track.id})');
          await pc.addTrack(track, _localStream!);
          debugPrint('[WebRTC] Successfully added track: ${track.kind}');
        }
      } else {
        debugPrint('[WebRTC] No local media tracks to add');
      }

      _peerConnection = pc;
      debugPrint('[WebRTC] Initialized successfully');
      
      final signalR = SignalRService();
      signalR.flushWebRTCQueue();
      
      if (_pendingIceCandidates.isNotEmpty) {
        debugPrint('[WebRTC] Adding ${_pendingIceCandidates.length} pending ICE candidates');
        for (var candidate in _pendingIceCandidates) {
          try {
            await _peerConnection!.addCandidate(candidate);
          } catch (e) {
            debugPrint('[WebRTC] Error adding pending ICE candidate: $e');
          }
        }
        _pendingIceCandidates.clear();
      }
    } catch (e) {
      debugPrint('[WebRTC] Initialization error: $e');
      onError?.call('Failed to initialize: $e');
      rethrow;
    }
  }

  bool _sdpHasVideo(String? sdp) {
    if (sdp == null) return false;
    return sdp.contains('m=video') && !sdp.contains('m=video 0');
  }
  
  bool _sdpHasAudio(String? sdp) {
    if (sdp == null) return false;
    return sdp.contains('m=audio') && !sdp.contains('m=audio 0');
  }

  bool _isValidSession(String receivedSessionId) {
    return receivedSessionId == sessionId;
  }

  void _handleRemoteDescription(String? sdp, String context) {
    // Parse SDP to check what media the remote peer is offering
    _remoteOffersVideo = _sdpHasVideo(sdp);
    _remoteOffersAudio = _sdpHasAudio(sdp);
    
    debugPrint('[WebRTC] Remote peer offers in $context: video=$_remoteOffersVideo, audio=$_remoteOffersAudio');
    
    // Notify if remote offers no media
    if (!_remoteOffersVideo && !_remoteOffersAudio) {
      debugPrint('[WebRTC] Remote peer has no media tracks in $context');
      hasRemoteVideo = false;
      hasRemoteAudio = false;
      onRemoteMediaAvailability?.call(false, false);
    }
  }

  void _setupSignalRCallbacks() {
    final signalR = SignalRService();
    
    // Register callbacks in SignalR service
    signalR.onReceiveOffer = (receivedSessionId, offer) async {
      if (!_isValidSession(receivedSessionId)) {
        debugPrint('[WebRTC] Ignoring offer for different session: $receivedSessionId != $sessionId');
        return;
      }
      
      debugPrint('[WebRTC] Received offer');
      try {
        final sdp = offer['sdp'] as String?;
        final type = offer['type'] as String?;
        
        if (sdp == null || type == null) {
          throw Exception('Invalid offer: sdp or type is null');
        }
        
        _handleRemoteDescription(sdp, 'offer');
        
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, type),
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
        debugPrint('[WebRTC] Sent answer');
      } catch (e) {
        debugPrint('[WebRTC] Error handling offer: $e');
        onError?.call('Failed to handle offer: $e');
      }
    };

    signalR.onReceiveAnswer = (receivedSessionId, answer) async {
      if (!_isValidSession(receivedSessionId)) {
        debugPrint('[WebRTC] Ignoring answer for different session: $receivedSessionId != $sessionId');
        return;
      }
      
      debugPrint('[WebRTC] Received answer');
      try {
        final sdp = answer['sdp'] as String?;
        final type = answer['type'] as String?;
        
        if (sdp == null || type == null) {
          throw Exception('Invalid answer: sdp or type is null');
        }
        
        _handleRemoteDescription(sdp, 'answer');
        
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, type),
        );
      } catch (e) {
        debugPrint('[WebRTC] Error handling answer: $e');
        onError?.call('Failed to handle answer: $e');
      }
    };

    signalR.onReceiveIceCandidate = (receivedSessionId, candidateData) async {
      if (!_isValidSession(receivedSessionId)) {
        debugPrint('[WebRTC] Ignoring ICE candidate for different session: $receivedSessionId != $sessionId');
        return;
      }
      
      debugPrint('[WebRTC] Received ICE candidate');
      try {
        final candidateString = candidateData['candidate'] as String?;
        final sdpMid = candidateData['sdpMid'] as String?;
        final sdpMLineIndex = candidateData['sdpMLineIndex'] as int?;
        
        if (candidateString == null) {
          debugPrint('[WebRTC] Invalid ICE candidate: candidate is null');
          return;
        }
        
        final candidate = RTCIceCandidate(
          candidateString,
          sdpMid,
          sdpMLineIndex,
        );
        
        if (_peerConnection == null) {
          debugPrint('[WebRTC] Peer connection not ready, queuing ICE candidate');
          _pendingIceCandidates.add(candidate);
        } else {
          await _peerConnection!.addCandidate(candidate);
          debugPrint('[WebRTC] Successfully added ICE candidate');
        }
      } catch (e) {
        debugPrint('[WebRTC] Error adding ICE candidate: $e');
      }
    };
  }

  Future<void> startCall() async {
    try {
      debugPrint('[WebRTC] Starting call (creating offer)');
      
      // Adding transceivers for video and audio to ensure we can receive them even if we don't have them locally to send
      if (!hasLocalVideo) {
        debugPrint('[WebRTC] Adding recvonly video transceiver');
        await _peerConnection!.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
        );
      }
      
      if (!hasLocalAudio) {
        debugPrint('[WebRTC] Adding recvonly audio transceiver');
        await _peerConnection!.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
        );
      }
      
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
      debugPrint('[WebRTC] Sent offer');
    } catch (e) {
      debugPrint('[WebRTC] Error starting call: $e');
      onError?.call('Failed to start call: $e');
    }
  }

  void toggleMute() {
    if (_localStream != null && hasLocalAudio) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final audioTrack = audioTracks.first;
        audioTrack.enabled = !audioTrack.enabled;
      }
    }
  }

  void toggleCamera() {
    if (_localStream != null && hasLocalVideo) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final videoTrack = videoTracks.first;
        videoTrack.enabled = !videoTrack.enabled;
      }
    }
  }

  Future<void> dispose() async {
    debugPrint('[WebRTC] Disposing...');
    
    // Clear SignalR callbacks
    final signalR = SignalRService();
    if (signalR.onReceiveOffer != null || signalR.onReceiveAnswer != null || signalR.onReceiveIceCandidate != null) {
      debugPrint('[WebRTC] Clearing SignalR callbacks for session: $sessionId');
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