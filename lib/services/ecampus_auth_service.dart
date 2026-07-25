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

    final cookie = _extractCookie(getResp.headers['set-cookie'] ?? '');
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
      final body = postResp.body.toLowerCase();
      if (!body.contains('student login') && !body.contains('rollno')) return;
      throw Exception('Invalid roll number or password');
    }

    throw Exception('eCampus login failed (${postResp.statusCode})');
  }

  String _extractCookie(String setCookieHeader) {
    final match = RegExp(r'(\.AspNetCore\.Antiforgery\.[^=]+=\S+?)(?:;|$)').firstMatch(setCookieHeader);
    return match?.group(1) ?? '';
  }

  String _extractCsrfToken(String html) {
    final match = RegExp(
      r'<input[^>]+name="__RequestVerificationToken"[^>]+value="([^"]+)"',
    ).firstMatch(html);
    return match?.group(1) ?? '';
  }
}
