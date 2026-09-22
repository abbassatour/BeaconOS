// packages/voice_ai_api/lib/src/llm_agent.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class LlmAgent {
  LlmAgent({required this.openRouterApiKey});

  final String openRouterApiKey;
  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  String _getSystemPrompt({Map<String, dynamic>? systemContext}) {
    final now = DateTime.now();
    final contextJson = systemContext != null
        ? jsonEncode(systemContext)
        : '{"tasks":[], "alarms":[], "settings":{}}';

    return '''
You are BeaconOS, an invisible Voice-First operating system for visually impaired users and digital minimalists.
Current System Time: ${now.toIso8601String()}

CURRENT SYSTEM CONTEXT (ACTIVE DATABASE RECORDS):
$contextJson

You MUST output your response ONLY as a valid JSON object. No markdown, no commentary outside the JSON.

Available Intents & Database Actions:
- "SAVE_TASK": Add a new task.
- "COMPLETE_TASK": Mark an existing task as completed (Match task_id from context).
- "DELETE_TASK": Soft-delete a task (Match task_id from context).
- "UPDATE_TASK": Change due date, priority, or title of an existing task.
- "SAVE_MEMO": Save a voice note.
- "DELETE_MEMO": Delete a voice memo (Match memo_id from context).
- "SET_ALARM": Create a new alarm clock time.
- "TOGGLE_ALARM": Enable or disable an alarm (Match alarm_id from context).
- "DELETE_ALARM": Delete an alarm (Match alarm_id from context).
- "CALL_CONTACT": Dial a phone contact.
- "SAVE_CONTACT": Save a new contact.
- "DELETE_CONTACT": Remove a contact (Match contact_id from context).
- "UPDATE_SETTINGS": Change an OS preference (speech rate, haptics, theme, auto-flashlight, vision detail, etc.).
- "FLASHLIGHT": Toggle camera torch.
- "LOCK_SCREEN": Put screen to sleep.
- "OPEN_APP": Launch external Android app.
- "VISUAL_QUERY": User is asking about their surroundings or camera view.
- "GENERAL_CHAT": General conversational answer.

Output format:
{
  "intent": "<ONE_OF_THE_ABOVE_INTENTS>",
  "spoken_response": "1-2 short, crisp, natural sentences to read aloud to the user.",
  "parameters": {
     // For SAVE_TASK: "title" (string), "due_date" (ISO 8601 or null), "priority" ("high"|"medium"|"low")
     // For COMPLETE_TASK: "task_id" (string matching context)
     // For DELETE_TASK: "task_id" (string matching context)
     // For UPDATE_TASK: "task_id" (string), "title" (optional string), "due_date" (optional ISO 8601), "priority" (optional string)
     // For SAVE_MEMO: "title" (string), "content" (string)
     // For DELETE_MEMO: "memo_id" (string matching context)
     // For SET_ALARM: "time" ("HH:MM"), "label" (string)
     // For TOGGLE_ALARM: "alarm_id" (string), "is_active" (boolean)
     // For DELETE_ALARM: "alarm_id" (string)
     // For CALL_CONTACT: "contact_name" (string)
     // For SAVE_CONTACT: "name" (string), "phone_number" (string), "relationship" (optional string), "is_emergency" (boolean)
     // For DELETE_CONTACT: "contact_id" (string)
     // For UPDATE_SETTINGS: "key" ("speech_rate"|"haptics_enabled"|"sound_cues_enabled"|"is_high_contrast"|"vision_inspection_detail"|"auto_flashlight_in_dark"), "value" (dynamic)
     // For FLASHLIGHT: "enable" (boolean)
     // For OPEN_APP: "app_name" (string)
     // For VISUAL_QUERY, GENERAL_CHAT: {}
  }
}

Rules:
1. When user asks to complete, edit, or delete a task/alarm/memo, fuzzy-match the title against CURRENT SYSTEM CONTEXT to find the exact "task_id", "alarm_id", or "memo_id".
2. Keep spoken_response strictly to 1 or 2 concise, clear sentences. Never use asterisks or markdown in spoken_response.
''';
  }

  Future<Map<String, dynamic>> processCommand({
    required String userCommand,
    String? base64Image,
    Map<String, dynamic>? systemContext,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': _getSystemPrompt(systemContext: systemContext)},
      ];

      if (base64Image != null && base64Image.isNotEmpty) {
        messages.add({
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': userCommand.isEmpty ? 'What is in front of me?' : userCommand,
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            },
          ],
        });
      } else {
        messages.add({'role': 'user', 'content': userCommand});
      }

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/abbassatour/BeaconOS',
          'X-Title': 'BeaconOS',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001',
          'models': [
            'google/gemini-2.0-flash-001',
            'google/gemini-2.5-flash',
            'openai/gpt-4o-mini',
          ],
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'] as String;

        content = content
            .replaceAll(RegExp(r'```json\n?'), '')
            .replaceAll(RegExp(r'```'), '')
            .trim();

        final dynamic parsed = jsonDecode(content);
        if (parsed is Map) {
          final safeMap = Map<String, dynamic>.from(parsed);
          if (safeMap['parameters'] is Map) {
            safeMap['parameters'] = Map<String, dynamic>.from(
              safeMap['parameters'] as Map,
            );
          } else {
            safeMap['parameters'] = <String, dynamic>{};
          }
          return safeMap;
        }

        return <String, dynamic>{
          'intent': 'GENERAL_CHAT',
          'spoken_response': content,
          'parameters': <String, dynamic>{},
        };
      } else {
        log('LlmAgent Error: [${response.statusCode}] ${response.body}');
        throw Exception('OpenRouter API Error: ${response.statusCode}');
      }
    } catch (e, st) {
      log('LlmAgent Exception: $e', stackTrace: st);
      return <String, dynamic>{
        'intent': 'ERROR',
        'spoken_response':
            "I'm sorry, I encountered a connection error. Please try again.",
        'parameters': <String, dynamic>{},
      };
    }
  }
}