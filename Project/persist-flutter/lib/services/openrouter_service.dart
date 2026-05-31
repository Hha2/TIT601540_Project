import 'dart:convert';
import 'package:http/http.dart' as http;

const _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
const _model = 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free';

const _systemPrompt = '''You are Persist AI, a calm, practical habit coach inside Persist.
Do not shame the user. Be supportive, realistic, and action-focused.
Keep replies short: 2-4 sentences. Suggest one small next action.''';

Map<String, String> _headers() => {
  'Authorization': 'Bearer $_apiKey',
  'Content-Type': 'application/json',
  'HTTP-Referer': 'https://persist-app.com',
  'X-Title': 'Persist',
};

bool get _hasKey => _apiKey.trim().startsWith('sk-' 'or-' 'v1-');

Future<String> chatWithAI(List<Map<String, String>> history) async {
  if (!_hasKey) {
    return 'AI coach is not connected in this build. Add your OpenRouter key with --dart-define to enable replies.';
  }
  try {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers(),
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          ...history,
        ],
        'max_tokens': 420,
        'temperature': 0.55,
      }),
    );

    if (response.statusCode != 200) {
      return 'AI is busy right now. Try again in a moment, or continue with one small task.';
    }
    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'];
    if (content == null || content.toString().trim().isEmpty) {
      return 'I am here. Pick the smallest task and start for two minutes.';
    }
    return content.toString().trim();
  } catch (_) {
    return 'Connection is unstable. For now, choose the easiest task and complete one small step.';
  }
}

Future<List<Map<String, dynamic>>?> generateGoalPlan(
  String goalName,
  int days,
  String category,
) async {
  if (!_hasKey || days > 30) {
    return generateLocalGoalPlan(goalName, days, category);
  }

  try {
    final prompt = '''Create a structured $days-day plan for goal "$goalName" in category "$category".
Return ONLY valid JSON array. Exactly $days objects. Each object:
{"dayNum":1,"title":"Day 1 — ...","tasks":["Task 1","Task 2","Task 3"]}
Each day must have 3 concise tasks.''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers(),
      body: jsonEncode({
        'model': _model,
        'messages': [{'role': 'user', 'content': prompt}],
        'max_tokens': days <= 14 ? 3500 : 7000,
        'temperature': 0.25,
      }),
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) return generateLocalGoalPlan(goalName, days, category);
    final data = jsonDecode(response.body);
    var content = data['choices'][0]['message']['content'].toString();
    content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = content.indexOf('[');
    final end = content.lastIndexOf(']');
    if (start == -1 || end <= start) return generateLocalGoalPlan(goalName, days, category);
    final parsed = jsonDecode(content.substring(start, end + 1));
    if (parsed is! List || parsed.length < days) return generateLocalGoalPlan(goalName, days, category);
    return parsed.take(days).map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map)).toList();
  } catch (_) {
    return generateLocalGoalPlan(goalName, days, category);
  }
}

List<Map<String, dynamic>> generateLocalGoalPlan(String goalName, int days, String category) {
  final cleanGoal = goalName.trim().isEmpty ? 'your goal' : goalName.trim();
  final phases = [
    'Foundation', 'Rhythm', 'Consistency', 'Strengthening', 'Review', 'Upgrade',
    'Momentum', 'Recovery', 'Deepening', 'Final Push'
  ];
  final cat = category.toLowerCase();
  List<String> taskSet(int day) {
    if (cat.contains('fitness') || cat.contains('health')) {
      return ['Warm up and complete the core activity', 'Track duration, reps, or effort', 'Do a short recovery check-in'];
    }
    if (cat.contains('learning') || cat.contains('career')) {
      return ['Study or practice one focused topic', 'Write a short summary of what you learned', 'Apply it with one small exercise'];
    }
    if (cat.contains('mind')) {
      return ['Do a short breathing or reflection session', 'Write one honest note about your state', 'Choose one gentle action for tomorrow'];
    }
    if (cat.contains('creative')) {
      return ['Create one small draft or sketch', 'Refine one detail without overthinking', 'Save progress and note what improved'];
    }
    return ['Start with one focused action', 'Track what you completed', 'Write one sentence about progress'];
  }

  return List.generate(days, (i) {
    final day = i + 1;
    final bucketSize = (days / phases.length).clamp(1, 99).toDouble();
    final phaseIndex = (((day - 1) / bucketSize).floor()).clamp(0, phases.length - 1);
    final phase = phases[phaseIndex];
    final tasks = taskSet(day);
    return {
      'dayNum': day,
      'title': 'Day $day — $phase',
      'tasks': [
        '${tasks[0]} for $cleanGoal',
        tasks[1],
        tasks[2],
      ],
    };
  });
}
