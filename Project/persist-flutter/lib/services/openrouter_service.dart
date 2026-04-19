import 'dart:convert';
import 'package:http/http.dart' as http;

// Replace with your OpenRouter API key
const _apiKey = 'YOUR_OPENROUTER_API_KEY';
const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
const _model = 'mistralai/mistral-7b-instruct';

const _systemPrompt = '''You are Persist AI, a supportive and insightful personal coach embedded in the Persist habit-tracking app. Your role is to help users stay consistent with their goals, reflect on their progress, and overcome obstacles. Be encouraging, empathetic, and actionable in your responses. Keep responses concise (2-4 sentences unless more detail is needed). You can help users create goals when they ask.''';

Future<String> chatWithAI(List<Map<String, String>> history) async {
  try {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history,
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://persist-app.com',
        'X-Title': 'Persist',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 500,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    }
    return "I'm having trouble connecting right now. Please try again in a moment.";
  } catch (_) {
    return "I'm having trouble connecting right now. Please try again in a moment.";
  }
}

Future<List<Map<String, dynamic>>?> generateGoalPlan(
    String goalName, int days, String category) async {
  try {
    final prompt = '''Create a structured $days-day plan for the goal: "$goalName" (Category: $category).

Return ONLY a JSON array with this exact format, no markdown:
[
  {"dayNum": 1, "title": "Day 1 — Introduction", "tasks": ["Task 1", "Task 2", "Task 3"]},
  {"dayNum": 2, "title": "Day 2 — Building Foundation", "tasks": ["Task 1", "Task 2", "Task 3"]}
]

Rules:
- Generate exactly $days days
- Each day has exactly 3 tasks
- Tasks should be specific and actionable
- Titles should be progressive and motivating
- Return pure JSON array only, no other text''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://persist-app.com',
        'X-Title': 'Persist',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 3000,
        'temperature': 0.4,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var content = data['choices'][0]['message']['content'] as String;
      content = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> parsed = jsonDecode(content);
      return parsed.cast<Map<String, dynamic>>();
    }
  } catch (_) {}
  return null;
}
