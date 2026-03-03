import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'error_log_service.dart';

class GitHubIssueService {
  static const _owner = 'cristiangastonl';
  static const _repo = 'GuitarrApp';

  String? get _token => dotenv.env['GITHUB_TOKEN'];

  bool get isConfigured => _token != null && _token!.isNotEmpty;

  /// Creates a GitHub issue with user feedback + automatic error logs.
  Future<String?> createIssue({
    required String title,
    required String body,
    required String category,
    bool attachLogs = true,
  }) async {
    if (!isConfigured) return null;

    final label = switch (category) {
      'bug' => 'bug',
      'sugerencia' => 'enhancement',
      _ => 'feedback',
    };

    final errorLog = ErrorLogService();
    final logsSection = attachLogs && errorLog.hasErrors
        ? '\n\n<details>\n<summary>Error logs (${errorLog.errors.length})</summary>\n\n${errorLog.formatForIssue()}\n</details>'
        : '';

    final fullBody = '''
$body
$logsSection
---
**Reportado desde la app**
- Plataforma: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}
- Categoría: $category
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/issues'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': '[$category] $title',
          'body': fullBody,
          'labels': [label, 'from-app'],
        }),
      );

      if (response.statusCode == 201) {
        // Clear logs after successful submission
        if (attachLogs) errorLog.clear();
        final data = jsonDecode(response.body);
        return data['html_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
