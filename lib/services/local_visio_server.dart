import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Service de Visioconférence Local Embarqué UniFlow.
///
/// Démarre un serveur HTTP et WebSocket local autonome en Dart natif sur la machine Desktop.
/// - Sert une application web de visioconférence WebRTC ultra-soignée et responsive sur `/visio`.
/// - Toute personne sur le même réseau (ou via tunnel/IP) sans l'application UniFlow peut
///   ouvrir le lien dans un navigateur (smartphone, tablette, PC) et rejoindre la visio directement.
/// - Gère le signalling WebSocket P2P sans infrastructure cloud externe.
class LocalVisioServer {
  static final LocalVisioServer instance = LocalVisioServer._internal();
  LocalVisioServer._internal();

  HttpServer? _server;
  int _port = 7890;
  bool _isRunning = false;
  String _activeRoom = 'AMPHI-VIRTUEL-UY1';
  final Set<WebSocket> _clients = {};
  String? _localIp;

  bool get isRunning => _isRunning;
  int get port => _port;
  String get activeRoom => _activeRoom;
  int get participantCount => _clients.length;

  /// Démarre le serveur local de visioconférence
  Future<bool> startServer({int port = 7890, String room = 'AMPHI-VIRTUEL-UY1'}) async {
    if (_isRunning) return true;
    _port = port;
    _activeRoom = room;

    try {
      // Détection de l'adresse IP locale sur le réseau LAN
      _localIp = await _findLocalIpAddress();

      // Bind sur 0.0.0.0 pour écouter sur localhost et sur tout le réseau local
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;

      _server!.listen((HttpRequest request) async {
        try {
          final path = request.uri.path;

          // Route WebSocket pour le signalling WebRTC
          if (path == '/ws') {
            if (WebSocketTransformer.isUpgradeRequest(request)) {
              final socket = await WebSocketTransformer.upgrade(request);
              _handleWebSocket(socket);
            } else {
              request.response.statusCode = HttpStatus.badRequest;
              request.response.close();
            }
            return;
          }

          // Route API Statut
          if (path == '/api/status') {
            _setCorsHeaders(request.response);
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'status': 'online',
              'room': _activeRoom,
              'participants': _clients.length,
              'port': _port,
              'localUrl': 'http://localhost:$_port/visio?room=$_activeRoom',
              'networkUrl': 'http://${_localIp ?? 'localhost'}:$_port/visio?room=$_activeRoom',
            }));
            await request.response.close();
            return;
          }

          // Route Web de Visioconférence (HTML5 + WebRTC responsive)
          if (path == '/visio' || path == '/' || path == '') {
            final roomName = request.uri.queryParameters['room'] ?? _activeRoom;
            final htmlContent = _generateVisioWebHtml(roomName);

            request.response.headers.contentType = ContentType.html;
            _setCorsHeaders(request.response);
            request.response.write(htmlContent);
            await request.response.close();
            return;
          }

          // 404 par défaut
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Page non trouvée');
          await request.response.close();
        } catch (e) {
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          } catch (_) {}
        }
      });

      return true;
    } catch (e) {
      _isRunning = false;
      return false;
    }
  }

  /// Arrête le serveur de visioconférence
  Future<void> stopServer() async {
    for (final client in _clients) {
      try {
        client.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
  }

  /// URL locale (machine hôte)
  String getLocalUrl() => 'http://localhost:$_port/visio?room=$_activeRoom';

  /// URL réseau partageable aux invités sans l'application UniFlow
  String getShareableNetworkUrl() {
    final ip = _localIp ?? 'localhost';
    return 'http://$ip:$_port/visio?room=$_activeRoom';
  }

  void _setCorsHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');
  }

  /// Gestion des connexions WebSocket et du relai de messages WebRTC (Signalling)
  void _handleWebSocket(WebSocket socket) {
    _clients.add(socket);
    _broadcastParticipantCount();

    socket.listen((message) {
      try {
        // Relai du message aux autres participants du salon
        for (final client in _clients) {
          if (client != socket && client.readyState == WebSocket.open) {
            client.add(message);
          }
        }
      } catch (_) {}
    }, onDone: () {
      _clients.remove(socket);
      _broadcastParticipantCount();
    }, onError: (_) {
      _clients.remove(socket);
      _broadcastParticipantCount();
    });
  }

  void _broadcastParticipantCount() {
    final payload = jsonEncode({
      'type': 'presence',
      'count': _clients.length,
    });
    for (final client in _clients) {
      if (client.readyState == WebSocket.open) {
        try {
          client.add(payload);
        } catch (_) {}
      }
    }
  }

  /// Recherche de l'IP LAN principale
  Future<String> _findLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith(RegExp(r'^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'))) {
            return addr.address;
          }
        }
      }
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return 'localhost';
  }

  /// Génère l'application Web HTML5/CSS/JS de visioconférence autonome et responsive
  String _generateVisioWebHtml(String roomName) {
    return '''<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>UniFlow Visio Campus · $roomName</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    body { font-family: 'Plus Jakarta Sans', sans-serif; }
    .video-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 1rem;
      height: 100%;
    }
    video {
      transform: scaleX(-1);
    }
  </style>
</head>
<body class="bg-slate-950 text-white min-h-screen flex flex-col justify-between overflow-x-hidden selection:bg-cyan-500 selection:text-black">
  
  <!-- Header Bar -->
  <header class="bg-slate-900/80 backdrop-blur-md border-b border-slate-800 px-4 py-3 flex items-center justify-between z-20">
    <div class="flex items-center gap-3">
      <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-[#1E3A8A] to-[#0D9488] flex items-center justify-center font-black text-white shadow-md">
        UF
      </div>
      <div>
        <div class="flex items-center gap-2">
          <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
          <h1 class="text-sm font-bold text-white tracking-tight">Amphi Virtuel Campus</h1>
          <span class="text-[10px] bg-slate-800 text-cyan-300 font-mono px-2 py-0.5 rounded border border-slate-700">$roomName</span>
        </div>
        <p class="text-[11px] text-slate-400">UniFlow Desktop P2P · Hébergé en local par l'hôte</p>
      </div>
    </div>

    <div class="flex items-center gap-2">
      <span id="participantBadge" class="bg-slate-800 text-slate-300 text-xs px-2.5 py-1 rounded-lg border border-slate-700 flex items-center gap-1.5 font-medium">
        👥 <span id="participantCount">1</span> connecté(s)
      </span>
      <span class="hidden sm:inline-flex bg-emerald-500/10 text-emerald-300 text-xs px-2.5 py-1 rounded-lg border border-emerald-500/20 font-semibold">
        HD WebRTC Direct
      </span>
    </div>
  </header>

  <!-- Video Stage -->
  <main class="flex-1 p-3 sm:p-4 flex flex-col justify-center items-center relative overflow-hidden">
    <div class="w-full max-w-6xl h-[65vh] sm:h-[72vh] rounded-3xl bg-slate-900 border border-slate-800 p-2 sm:p-3 shadow-2xl relative overflow-hidden flex flex-col">
      <div class="video-grid flex-1">
        <!-- Flux Local -->
        <div class="relative bg-slate-950 rounded-2xl overflow-hidden border border-slate-800 flex items-center justify-center group shadow-inner">
          <video id="localVideo" autoplay playsinline muted class="w-full h-full object-cover rounded-2xl"></video>
          <div class="absolute bottom-3 left-3 bg-black/60 backdrop-blur-md px-3 py-1 rounded-lg text-xs font-semibold flex items-center gap-2 border border-white/10">
            <span class="w-2 h-2 rounded-full bg-emerald-400"></span> Vous (Caméra Locale)
          </div>
        </div>

        <!-- Flux Distant / Invités -->
        <div id="remoteContainer" class="relative bg-slate-950 rounded-2xl overflow-hidden border border-slate-800 flex items-center justify-center shadow-inner">
          <video id="remoteVideo" autoplay playsinline class="w-full h-full object-cover rounded-2xl"></video>
          <div id="remotePlaceholder" class="flex flex-col items-center justify-center p-6 text-center">
            <div class="w-16 h-16 rounded-2xl bg-slate-900 flex items-center justify-center text-2xl mb-2 border border-slate-800">
              🎓
            </div>
            <p class="text-xs font-bold text-slate-300">En attente d'autres participants...</p>
            <p class="text-[11px] text-slate-500 mt-1 max-w-xs">Partagez l'URL ou le QR code pour que d'autres étudiants ou enseignants rejoignent la séance sans installer l'app.</p>
          </div>
          <div id="remoteLabel" class="hidden absolute bottom-3 left-3 bg-black/60 backdrop-blur-md px-3 py-1 rounded-lg text-xs font-semibold items-center gap-2 border border-white/10">
            <span class="w-2 h-2 rounded-full bg-cyan-400"></span> Participant distant
          </div>
        </div>
      </div>
    </div>
  </main>

  <!-- Controls Bar -->
  <footer class="bg-slate-900/90 backdrop-blur-md border-t border-slate-800 px-4 py-3 flex items-center justify-center gap-3 z-20">
    <button id="toggleMic" class="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white text-xs font-bold transition-all shadow-sm">
      <span id="micIcon">🎤</span> <span id="micText" class="hidden sm:inline">Micro activé</span>
    </button>
    <button id="toggleCam" class="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white text-xs font-bold transition-all shadow-sm">
      <span id="camIcon">📹</span> <span id="camText" class="hidden sm:inline">Caméra activée</span>
    </button>
    <button id="shareScreen" class="hidden sm:flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white text-xs font-bold transition-all shadow-sm">
      <span>🖥️</span> <span>Partager l'écran</span>
    </button>
    <button id="leaveCall" class="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-red-600 hover:bg-red-500 text-white text-xs font-bold transition-all shadow-lg shadow-red-900/30">
      <span>✕</span> <span>Quitter</span>
    </button>
  </footer>

  <!-- WebRTC & WebSocket Client Script -->
  <script>
    let localStream = null;
    let peerConnection = null;
    let ws = null;
    let isMicOn = true;
    let isCamOn = true;

    const localVideo = document.getElementById('localVideo');
    const remoteVideo = document.getElementById('remoteVideo');
    const remotePlaceholder = document.getElementById('remotePlaceholder');
    const remoteLabel = document.getElementById('remoteLabel');
    const participantCountEl = document.getElementById('participantCount');

    // Configuration ICE (STUN public par défaut pour le NAT si besoin)
    const rtcConfig = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
      ]
    };

    async function initMedia() {
      try {
        localStream = await navigator.mediaDevices.getUserMedia({
          video: { width: { ideal: 1280 }, height: { ideal: 720 } },
          audio: true
        });
        localVideo.srcObject = localStream;
        connectWebSocket();
      } catch (err) {
        console.warn('Accès caméra/micro non disponible :', err);
        alert('Veuillez autoriser l\\'accès à la caméra et au microphone pour participer à la visio.');
      }
    }

    function connectWebSocket() {
      const loc = window.location;
      const wsProtocol = loc.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = wsProtocol + '//' + loc.host + '/ws';

      ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        console.log('Connecté au serveur de signalling UniFlow Desktop');
        createPeerConnection();
      };

      ws.onmessage = async (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data.type === 'presence') {
            participantCountEl.textContent = data.count;
          } else if (data.offer) {
            await handleOffer(data.offer);
          } else if (data.answer) {
            await handleAnswer(data.answer);
          } else if (data.candidate) {
            await handleCandidate(data.candidate);
          }
        } catch (e) {
          console.error('Erreur signalling message', e);
        }
      };

      ws.onclose = () => {
        setTimeout(connectWebSocket, 3000);
      };
    }

    function createPeerConnection() {
      peerConnection = new RTCPeerConnection(rtcConfig);

      if (localStream) {
        localStream.getTracks().forEach(track => {
          peerConnection.addTrack(track, localStream);
        });
      }

      peerConnection.ontrack = (event) => {
        if (event.streams && event.streams[0]) {
          remoteVideo.srcObject = event.streams[0];
          remotePlaceholder.classList.add('hidden');
          remoteLabel.classList.remove('hidden');
          remoteLabel.classList.add('flex');
        }
      };

      peerConnection.onicecandidate = (event) => {
        if (event.candidate && ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ candidate: event.candidate }));
        }
      };

      // Si premier à se connecter, émettre une offre
      peerConnection.onnegotiationneeded = async () => {
        try {
          const offer = await peerConnection.createOffer();
          await peerConnection.setLocalDescription(offer);
          if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ offer: peerConnection.localDescription }));
          }
        } catch (e) {
          console.error('Erreur négociation', e);
        }
      };
    }

    async function handleOffer(offer) {
      if (!peerConnection) createPeerConnection();
      await peerConnection.setRemoteDescription(new RTCSessionDescription(offer));
      const answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ answer: peerConnection.localDescription }));
      }
    }

    async function handleAnswer(answer) {
      if (peerConnection) {
        await peerConnection.setRemoteDescription(new RTCSessionDescription(answer));
      }
    }

    async function handleCandidate(candidate) {
      if (peerConnection) {
        await peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
      }
    }

    // Commandes Micro et Caméra
    document.getElementById('toggleMic').addEventListener('click', () => {
      if (!localStream) return;
      isMicOn = !isMicOn;
      localStream.getAudioTracks().forEach(track => track.enabled = isMicOn);
      document.getElementById('micIcon').textContent = isMicOn ? '🎤' : '🔇';
      document.getElementById('micText').textContent = isMicOn ? 'Micro activé' : 'Micro coupé';
    });

    document.getElementById('toggleCam').addEventListener('click', () => {
      if (!localStream) return;
      isCamOn = !isCamOn;
      localStream.getVideoTracks().forEach(track => track.enabled = isCamOn);
      document.getElementById('camIcon').textContent = isCamOn ? '📹' : '🚫';
      document.getElementById('camText').textContent = isCamOn ? 'Caméra activée' : 'Caméra coupée';
    });

    document.getElementById('shareScreen').addEventListener('click', async () => {
      try {
        const screenStream = await navigator.mediaDevices.getDisplayMedia({ video: true });
        const videoTrack = screenStream.getVideoTracks()[0];
        const sender = peerConnection.getSenders().find(s => s.track.kind === 'video');
        if (sender) sender.replaceTrack(videoTrack);
        localVideo.srcObject = screenStream;
        videoTrack.onended = () => {
          if (sender) sender.replaceTrack(localStream.getVideoTracks()[0]);
          localVideo.srcObject = localStream;
        };
      } catch (e) {
        console.warn('Partage écran annulé ou non autorisé');
      }
    });

    document.getElementById('leaveCall').addEventListener('click', () => {
      if (localStream) {
        localStream.getTracks().forEach(t => t.stop());
      }
      if (ws) ws.close();
      window.close();
      document.body.innerHTML = '<div class="flex items-center justify-center min-h-screen"><div class="text-center p-6"><h2 class="text-xl font-bold">Séance de visioconférence terminée</h2><p class="text-sm text-slate-400 mt-2">Vous pouvez fermer cet onglet.</p></div></div>';
    });

    window.addEventListener('load', initMedia);
  </script>
</body>
</html>
''';
  }
}
