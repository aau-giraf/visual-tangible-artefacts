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
  
  // Track available media
  bool hasLocalVideo = false;
  bool hasLocalAudio = false;
  bool hasRemoteVideo = false;
  bool hasRemoteAudio = false;
    
  // Track what remote peer advertised in SDP
  bool _remoteOffersVideo = false;
  bool _remoteOffersAudio = false;
  bool _remoteMediaKnown = false;
  
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

  Future<void> _requestUserMedia() async {
    // Try to get both video and audio
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      hasLocalVideo = _localStream!.getVideoTracks().isNotEmpty;
      hasLocalAudio = _localStream!.getAudioTracks().isNotEmpty;
      print('[WebRTC] Got both video and audio');
      return;
    } catch (e) {
      print('[WebRTC] Failed to get both video and audio: $e');
    }
    
    // Try video only
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': _mediaConstraints['video'],
      });
      hasLocalVideo = _localStream!.getVideoTracks().isNotEmpty;
      hasLocalAudio = false;
      print('[WebRTC] Got video only');
      return;
    } catch (e) {
      print('[WebRTC] Failed to get video: $e');
    }
    
    // Try audio only
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
      });
      hasLocalVideo = false;
      hasLocalAudio = _localStream!.getAudioTracks().isNotEmpty;
      print('[WebRTC] Got audio only');
      return;
    } catch (e) {
      print('[WebRTC] Failed to get audio: $e');
    }
    
    // Continue without media
    print('[WebRTC] No media available, continuing with data channel only');
    hasLocalVideo = false;
    hasLocalAudio = false;
    _localStream = null;
  }

  Future<void> initialize() async {
    try {
      print('[WebRTC] Starting initialization');
      
      // Try to get local media with fallbacks
      print('[WebRTC] Requesting user media');
      await _requestUserMedia();
      
      if (_localStream != null) {
        print('[WebRTC] Got local media stream (video: $hasLocalVideo, audio: $hasLocalAudio)');
        onLocalStream?.call(_localStream!);
        onLocalMediaAvailability?.call(hasLocalVideo, hasLocalAudio);
      } else {
        print('[WebRTC] No local media available, continuing without it');
        onLocalMediaAvailability?.call(false, false);
      }

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
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          // Connection established - trigger callback even if no media tracks arrive
          // This handles the case where remote peer has no media to send
          onConnectionEstablished?.call();
        }
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
          
          // Update specific track availability
          if (event.track.kind == 'video') {
            hasRemoteVideo = true;
            print('[WebRTC] Remote video track received');
          } else if (event.track.kind == 'audio') {
            hasRemoteAudio = true;
            print('[WebRTC] Remote audio track received');
          }
          
          // Call the callbacks
          onRemoteStream?.call(_remoteStream!);
          onRemoteMediaAvailability?.call(hasRemoteVideo, hasRemoteAudio);
          
          print('[WebRTC] Remote media state: video=$hasRemoteVideo, audio=$hasRemoteAudio');
        }
      };

      // Add local tracks to peer connection
      if (_localStream != null) {
        print('[WebRTC] Adding local tracks to peer connection');
        final tracks = _localStream!.getTracks();
        print('[WebRTC] Found ${tracks.length} tracks to add');
        
        for (var track in tracks) {
          print('[WebRTC] Adding track: ${track.kind} (${track.id})');
          await pc.addTrack(track, _localStream!);
          print('[WebRTC] Successfully added track: ${track.kind}');
        }
      } else {
        print('[WebRTC] No local media tracks to add');
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
    
    bool _sdpHasVideo(String? sdp) {
      if (sdp == null) return false;
      return sdp.contains('m=video') && !sdp.contains('m=video 0');
    }
    
    bool _sdpHasAudio(String? sdp) {
      if (sdp == null) return false;
      return sdp.contains('m=audio') && !sdp.contains('m=audio 0');
    }
    
    // Register callbacks in SignalR service
    signalR.onReceiveOffer = (receivedSessionId, offer) async {
      if (receivedSessionId != sessionId) {
        print('[WebRTC] Ignoring offer for different session: $receivedSessionId != $sessionId');
        return;
      }
      
      print('[WebRTC] Received offer');
      try {
        // Parse SDP to check what media the remote peer is offering
        final sdp = offer['sdp'] as String?;
        _remoteOffersVideo = _sdpHasVideo(sdp);
        _remoteOffersAudio = _sdpHasAudio(sdp);
        _remoteMediaKnown = true;
        
        print('[WebRTC] Remote peer offers: video=$_remoteOffersVideo, audio=$_remoteOffersAudio');
        
        // Notify if remote offers NO media at all
        if (!_remoteOffersVideo && !_remoteOffersAudio) {
          print('[WebRTC] Remote peer has no media tracks in offer');
          hasRemoteVideo = false;
          hasRemoteAudio = false;
          onRemoteMediaAvailability?.call(false, false);
        }
        
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
        // Parse SDP to check what media the remote peer is offering
        final sdp = answer['sdp'] as String?;
        _remoteOffersVideo = _sdpHasVideo(sdp);
        _remoteOffersAudio = _sdpHasAudio(sdp);
        _remoteMediaKnown = true;
        
        print('[WebRTC] Remote peer offers: video=$_remoteOffersVideo, audio=$_remoteOffersAudio');
        
        // Notify if remote offers NO media at all
        if (!_remoteOffersVideo && !_remoteOffersAudio) {
          print('[WebRTC] Remote peer has no media tracks in answer');
          hasRemoteVideo = false;
          hasRemoteAudio = false;
          onRemoteMediaAvailability?.call(false, false);
        }
        
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
      
      // Add transceivers for video and audio to ensure we can receive them
      // even if we don't have them locally to send
      if (!hasLocalVideo) {
        print('[WebRTC] Adding recvonly video transceiver');
        await _peerConnection!.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
        );
      }
      
      if (!hasLocalAudio) {
        print('[WebRTC] Adding recvonly audio transceiver');
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
      print('[WebRTC] Sent offer');
    } catch (e) {
      print('[WebRTC] Error starting call: $e');
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