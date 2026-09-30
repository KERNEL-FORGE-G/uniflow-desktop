import 'dart:io';
import 'package:flutter/foundation.dart';

import 'conference_paths.dart';

/// Télécharge et installe automatiquement le binaire `livekit-server` sur les
/// plateformes où il n'est pas préinstallé (principalement Windows).
///
/// GitHub Releases publie un binaire pour chaque plateforme ; cette classe en
/// détermine l'URL, le télécharge dans `.uniflow/conference/bin/`, le décompresse
/// et le rend exécutable. Sur Linux, le script officiel reste la voie
/// recommandée, mais ce provisionnement automatique est utilisé comme repli.
class LiveKitBinaryProvisioner {
  static const String _version = '1.13.7';
  static const String _releasesBase =
      'https://github.com/livekit/livekit/releases/download/v$_version';

  /// Dossier bin dans le répertoire de travail UniFlow.
  static String _binDirectory() =>
      '${conferenceHomeDirectory()}${Platform.pathSeparator}bin';

  /// Chemin cible du binaire une fois installé.
  static String installedBinaryPath() {
    final dir = _binDirectory();
    final name = Platform.isWindows ? 'livekit-server.exe' : 'livekit-server';
    return '$dir${Platform.pathSeparator}$name';
  }

  /// Vrai si le binaire est déjà installé dans le dossier géré.
  static Future<bool> isInstalled() async =>
      File(installedBinaryPath()).existsSync();

  /// Détermine l'URL d'archive pour la plateforme et l'architecture courantes.
  /// Renvoie `null` si la plateforme n'est pas supportée.
  static String? _archiveUrl() {
    final String os;
    late String arch;
    if (Platform.isWindows) {
      os = 'windows';
    } else if (Platform.isLinux) {
      os = 'linux';
    } else if (Platform.isMacOS) {
      os = 'darwin';
    } else {
      return null;
    }
    // Heuristique d'architecture ; `dart.io.Platform` ne l'expose pas
    // directement — on se fie à `uname` sur Unix et à `PROCESSOR_ARCHITECTURE`
    // sur Windows.
    final envArch = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '';
    if (Platform.isWindows) {
      arch = envArch.contains('ARM') ? 'arm64' : 'amd64';
    } else {
      // Sur Linux/macOS, on tente `uname -m` ; à défaut on suppose amd64.
      try {
        final result = Process.runSync('uname', ['-m']);
        final machine = (result.stdout as String).trim().toLowerCase();
        if (machine == 'aarch64' || machine == 'arm64') {
          arch = 'arm64';
        } else if (machine.contains('arm')) {
          arch = 'armv7';
        } else {
          arch = 'amd64';
        }
      } catch (_) {
        arch = 'amd64';
      }
    }
    final ext = Platform.isWindows ? 'zip' : 'tar.gz';
    return '$_releasesBase/livekit_${_version}_${os}_$arch.$ext';
  }

  /// Télécharge, décompresse et installe le binaire.
  ///
  /// [onProgress] reçoit des messages destinés à l'interface (« Téléchargement… »,
  /// « Extraction… »).
  ///
  /// Lève [LiveKitProvisionException] si l'installation échoue pour une raison
  /// récupérable (réseau absent, disk plein).
  static Future<String> provision({
    void Function(String message)? onProgress,
  }) async {
    final url = _archiveUrl();
    if (url == null) {
      throw const LiveKitProvisionException(
          'Plateforme non supportée pour le provisionnement automatique.');
    }

    final binDir = Directory(_binDirectory());
    await binDir.create(recursive: true);

    final archiveName = url.split('/').last;
    final isZip = archiveName.endsWith('.zip');
    final archivePath =
        '${binDir.path}${Platform.pathSeparator}$archiveName';

    // ── Téléchargement ──────────────────────────────────────────────────────
    onProgress?.call('Téléchargement de livekit-server v$_version…');
    debugPrint('[LiveKit] Téléchargement depuis $url');

    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw LiveKitProvisionException(
            'Téléchargement échoué (HTTP ${resp.statusCode}).');
      }
      final archive = File(archivePath);
      final sink = archive.openWrite();
      await resp.pipe(sink);
      await sink.flush();
      await sink.close();
    } finally {
      client.close(force: true);
    }

    // ── Extraction ──────────────────────────────────────────────────────────
    onProgress?.call('Extraction…');
    try {
      if (isZip) {
        // Windows : utilise PowerShell (disponible sur tout Windows ≥ 7)
        final result = await Process.run('powershell', [
          '-Command',
          'Expand-Archive -Force -Path "$archivePath" -DestinationPath "${binDir.path}"',
        ]);
        if (result.exitCode != 0) {
          throw LiveKitProvisionException(
              'Extraction ZIP échouée : ${result.stderr}');
        }
      } else {
        // Linux / macOS
        final result = await Process.run('tar', [
          '-xzf',
          archivePath,
          '-C',
          binDir.path,
        ]);
        if (result.exitCode != 0) {
          throw LiveKitProvisionException(
              'Extraction tar.gz échouée : ${result.stderr}');
        }
      }
    } finally {
      // Nettoyage de l'archive téléchargée (peu importe le résultat)
      try {
        await File(archivePath).delete();
      } catch (_) {}
    }

    // ── Vérification & permissions ──────────────────────────────────────────
    final binary = File(installedBinaryPath());
    if (!await binary.exists()) {
      throw const LiveKitProvisionException(
          'Binaire introuvable après extraction. '
          'L\'archive a peut-être une structure différente.');
    }

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', binary.path]);
    }

    onProgress?.call('livekit-server installé avec succès.');
    debugPrint('[LiveKit] Binaire disponible : ${binary.path}');
    return binary.path;
  }
}

/// Erreur levée quand le provisionnement automatique échoue.
class LiveKitProvisionException implements Exception {
  final String message;
  const LiveKitProvisionException(this.message);

  @override
  String toString() => message;
}
