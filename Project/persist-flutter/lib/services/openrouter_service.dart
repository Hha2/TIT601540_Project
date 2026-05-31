import 'dart:convert';
import 'package:http/http.dart' as http;

const _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');

const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
const _model = 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free';

const _systemPrompt = '''
You are Persist AI, a supportive and practical personal coach inside the Persist habit-tracking app.
Help users stay consistent with goals, reflect on progress, and overcome obstacles.
Be concise, warm, realistic, and actionable.
Keep replies 2-4 sentences unless the user asks for detail.
''';

Map<String, String> _headers() {
  return {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://persist-app.com',
    'X-Title': 'Persist',
  };
}

Future<String> chatWithAI(List<Map<String, String>> history) async {
  try {
    if (_apiKey.contains('PASTE_YOUR_REAL') || _apiKey.contains('YOUR_OPENROUTER')) {
      return 'AI setup error: OpenRouter API key is missing.';
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers(),
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          ...history,
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      }),
    );

    print('OPENROUTER CHAT STATUS: ${response.statusCode}');
    print('OPENROUTER CHAT BODY: ${response.body}');

    if (response.statusCode != 200) {
      return 'AI error ${response.statusCode}. Check console for OpenRouter response.';
    }

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'];

    if (content == null || content.toString().trim().isEmpty) {
      return 'AI returned an empty response.';
    }

    return content.toString().trim();
  } catch (e, stack) {
    print('OPENROUTER CHAT EXCEPTION: $e');
    print(stack);
    return 'AI connection failed. Check console logs.';
  }
}

Future<List<Map<String, dynamic>>?> generateGoalPlan(
  String goalName,
  int days,
  String category,
) async {
  try {
    if (_apiKey.contains('PASTE_YOUR_REAL') || _apiKey.contains('YOUR_OPENROUTER')) {
      print('OPENROUTER GOAL ERROR: API key missing.');
      return null;
    }

    final prompt = '''
Create a structured $days-day plan for the goal: "$goalName" (Category: $category).

Return ONLY valid JSON. No markdown. No explanation.

Format:
[
  {
    "dayNum": 1,
    "title": "Day 1 — Introduction",
    "tasks": ["Task 1", "Task 2", "Task 3"]
  }
]

Rules:
- Generate exactly $days days.
- Each day must have exactly 3 tasks.
- Tasks must be specific and actionable.
- Return only a JSON array.
''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers(),
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 3000,
        'temperature': 0.3,
      }),
    );

    print('OPENROUTER GOAL STATUS: ${response.statusCode}');
    print('OPENROUTER GOAL BODY: ${response.body}');

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    String content = data['choices'][0]['message']['content'].toString();

    content = content
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final start = content.indexOf('[');
    final end = content.lastIndexOf(']');

    if (start == -1 || end == -1 || end <= start) {
      print('OPENROUTER GOAL JSON ERROR: No JSON array found.');
      return null;
    }

    content = content.substring(start, end + 1);

    final parsed = jsonDecode(content);

    if (parsed is! List) {
      return null;
    }

    return parsed.map<Map<String, dynamic>>((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  } catch (e, stack) {
    print('OPENROUTER GOAL EXCEPTION: $e');
    print(stack);
    return null;
  }
}