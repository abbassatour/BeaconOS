// packages/voice_ai_api/lib/src/llm_agent.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LlmAgent {
  LlmAgent({required this.openRouterApiKey});

  final String openRouterApiKey;
  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  // دالة لتوليد موجه النظام الديناميكي (لإخبار الذكاء الاصطناعي بالوقت والتاريخ الحاليين)
  String _getSystemPrompt() {
    final now = DateTime.now();
    return '''
You are BeaconOS, an invisible Voice-First operating system for visually impaired users and digital minimalists.
Current System Time: ${now.toIso8601String()}

You MUST output your response ONLY as a valid JSON object. No markdown, no explanations outside the JSON.

Determine the user's intent and return a JSON in this exact format:
{
  "intent": "SAVE_TASK" | "SAVE_MEMO" | "READ_NOTIFICATIONS" | "SET_ALARM" | "CALL_CONTACT" | "LOCK_SCREEN" | "GENERAL_CHAT" | "VISUAL_QUERY",
  "spoken_response": "The exact short sentence BeaconOS will speak out loud to the user.",
  "parameters": {
     // For SAVE_TASK: "task_title" (string), "due_date" (ISO 8601 string if explicitly mentioned, else null)
     // For SAVE_MEMO: "memo_title" (string), "memo_content" (string)
     // For SET_ALARM: "time" (HH:MM format)
     // For CALL_CONTACT: "contact_name" (string)
     // For VISUAL_QUERY, GENERAL_CHAT, READ_NOTIFICATIONS, LOCK_SCREEN: null
  }
}

Rules for spoken_response:
1. Extremely concise (1-2 short sentences max).
2. Professional, supportive, and direct.
3. If intent is VISUAL_QUERY, acknowledge they want to see something and that you are analyzing it.
''';
  }

  Future<Map<String, dynamic>> processCommand({
    required String userCommand,
    String? base64Image, // في حالة الاستعلام البصري
  }) async {
    try {
      final messages = [
        {'role': 'system', 'content': _getSystemPrompt()},
      ];

      // إضافة الصورة إذا وجدت
      if (base64Image != null && base64Image.isNotEmpty) {
        messages.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userCommand.isEmpty ? 'What is in front of me?' : userCommand},
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}}
          ]
        });
      } else {
        messages.add({'role': 'user', 'content': userCommand});
      }

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/satwrabbas/BeaconOS',
          'X-Title': 'BeaconOS',
        },
        body: jsonEncode({
          'model': 'google/gemini-1.5-flash',
          'response_format': {'type': 'json_object'}, // إجبار النموذج على إرجاع JSON
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'] as String;
        
        // تنظيف النص في حال أرجع الذكاء الاصطناعي كود Markdown بالخطأ
        content = content.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'```'), '').trim();
        
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // إرجاع رد آمن في حالة فشل الاتصال بالإنترنت
      return {
        "intent": "ERROR",
        "spoken_response": "I'm sorry, I encountered a connection error. Please try again.",
        "parameters": {}
      };
    }
  }
}