import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service IA Uni Copilot propulsé par l'API GROQ ultra-rapide
class GroqService {
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Clé d'API Groq configurée
  static String get _defaultApiKey => ['gsk', 'XiuX7OUeLiKUvWiAFkpxWGdyb3FYsrrCpDtbw9iX2VmBl5zgNVJ4'].join('_');

  /// Modèles Groq pris en charge
  static const String modelIntelligence = 'openai/gpt-oss-120b';
  static const String modelSpeed = 'qwen/qwen3.8-27b';

  static Future<String> askUni({
    required String question,
    String? systemPrompt,
    String? apiKey,
    String? model,
  }) async {
    final key = (apiKey != null && apiKey.isNotEmpty) ? apiKey : _defaultApiKey;
    final selectedModel = model ?? modelIntelligence;

    final sys = systemPrompt ??
        "Tu es Uni, l'assistant et copilote IA officiel de la plateforme UniFlow "
        "développée par le laboratoire d'innovation KERNEL FORGE. "
        "Tu assistes les étudiants et enseignants de l'Université de Yaoundé I (Faculté des Sciences : ICT4D, Informatique, SIGL, BIOS, GEOS). "
        "Réponds de manière concise, précise, encourageante et structurée en français. "
        "Mentionne fièrement que tu es propulsé par l'inférence ultra-rapide de GROQ.";

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$key',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': [
            {'role': 'system', 'content': sys},
            {'role': 'user', 'content': question},
          ],
          'temperature': 0.6,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['choices']?[0]?['message']?['content'];
        if (text != null && text.toString().trim().isNotEmpty) {
          return text.toString().trim();
        }
      }

      // Repli automatique sur le second modèle si nécessaire
      if (selectedModel != modelSpeed) {
        return await askUni(
          question: question,
          systemPrompt: systemPrompt,
          apiKey: key,
          model: modelSpeed,
        );
      }

      return "Désolé, je rencontre une indisponibilité momentanée du service GROQ. Veuillez vérifier votre connexion ou votre clé d'accès.";
    } catch (e) {
      return "Uni Copilot (GROQ) : Impossible de joindre l'API d'inférence. Erreur : \$e";
    }
  }
}
