import 'package:flutter/material.dart';
import '../services/groq_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'Bonjour ! Je suis **Uni**, votre copilote académique officiel propulsé par l\'inférence ultra-rapide de **GROQ**.\n\nComment puis-je vous aider aujourd\'hui dans vos cours à l\'Université de Yaoundé I ? (Génie logiciel, algorithmique, révisions d\'examen, planning...)',
    }
  ];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'Explique la différence entre CM, TD et TP en LMD',
    'Donne-moi un plan de révision pour le cours INF4067',
    'Comment fonctionne la visioconférence P2P locale UniFlow ?',
    'Résume les concepts clés des réseaux de neurones',
  ];

  Future<void> _sendMessage([String? textToSend]) async {
    final text = textToSend ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      if (textToSend == null) _controller.clear();
    });

    _scrollToBottom();

    final response = await GroqService.askUni(question: text);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/mascot/uni_copilot_3d.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uni Copilot · Assistant IA d\'Études',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFF34D399), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'En ligne · Propulsé par GROQ (openai/gpt-oss-120b & qwen3.8)',
                              style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Messages
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser) ...[
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/mascot/uni_copilot_3d.png'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.65,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF1E3A8A) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isUser ? 18 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 18),
                              ),
                              border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg['content'] ?? '',
                              style: TextStyle(
                                color: isUser ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF1E3A8A),
                            backgroundImage: AssetImage('assets/team/avatar_aliya_anime.jpg'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))),
                    SizedBox(width: 8),
                    Text('Uni réfléchit avec GROQ...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),

            // Suggestions de prompts rapides
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: _quickPrompts.map((p) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    onPressed: () => _sendMessage(p),
                  ),
                )).toList(),
              ),
            ),

            // Barre de saisie
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Posez une question académique à Uni (GROQ)...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _sendMessage(),
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF1E3A8A)),
                    tooltip: 'Envoyer',
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
