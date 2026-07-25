import 'package:http/http.dart' as http;

class ECampusAuthService {
  static const _base = 'https://ecampus.psgtech.ac.in/studzone';
  static const _loginPageUrl = '$_base/Login';
  static const _loginPostUrl = _base;

  Future<void> login(String rollNo, String password) async {
    final getResp = await http.get(
      Uri.parse(_loginPageUrl),
      headers: {'User-Agent': 'Mozilla/5.0'},
    );

    // Build a cookie jar from all Set-Cookie headers.
    // Dart's http package may merge multiple Set-Cookie headers into one
    // comma-separated string, so we split on ',' boundaries between cookies.
    final cookie = _buildCookieJar(getResp.headers);
    final csrfToken = _extractCsrfToken(getResp.body);

    if (cookie.isEmpty || csrfToken.isEmpty) {
      throw Exception('Failed to fetch CSRF token from eCampus');
    }

    final postResp = await http.post(
      Uri.parse(_loginPostUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': cookie,
        'User-Agent': 'Mozilla/5.0',
        'Referer': _loginPageUrl,
      },
      body: {
        '__RequestVerificationToken': csrfToken,
        'rollno': rollNo.toUpperCase(),
        'password': password,
        'chkterms': 'on',
      },
    );

    if (postResp.statusCode == 302) return;

    if (postResp.statusCode == 200) {
      // NOTE: This heuristic is fragile — it infers failure from the presence
      // of login-form markers in the response body. If eCampus changes its HTML
      // structure this check may produce false positives or false negatives.
      final body = postResp.body.toLowerCase();
      if (!body.contains('student login') && !body.contains('rollno')) return;
      throw Exception('Invalid roll number or password');
    }

    throw Exception('eCampus login failed (${postResp.statusCode})');
  }

  /// Builds a cookie string from response headers, handling the case where
  /// Dart's http package collapses multiple Set-Cookie headers into one string.
  String _buildCookieJar(Map<String, String> headers) {
    final raw = headers['set-cookie'] ?? '';
    if (raw.isEmpty) return '';

    final jar = <String, String>{};

    // Split on cookie boundaries: each cookie ends with a known attribute
    // pattern. We split on ', ' only when followed by a cookie name= pattern.
    final cookieEntries = raw.split(RegExp(r',\s*(?=[^;,]+=)'));
    for (final entry in cookieEntries) {
      final nameValue = entry.split(';').first.trim();
      final eqIdx = nameValue.indexOf('=');
      if (eqIdx == -1) continue;
      final name = nameValue.substring(0, eqIdx).trim();
      final value = nameValue.substring(eqIdx + 1).trim();
      jar[name] = value;
    }

    return jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  String _extractCsrfToken(String html) {
    final match = RegExp(
      r'<input[^>]+name="__RequestVerificationToken"[^>]+value="([^"]+)"',
    ).firstMatch(html);
    return match?.group(1) ?? '';
  }
}
