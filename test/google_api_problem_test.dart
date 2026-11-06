import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/data/google_api_problem.dart';
import 'package:notlar/features/calendar/data/google_calendar_api.dart';
import 'package:notlar/features/calendar/data/google_tasks_api.dart';

/// Kullanıcı bulgusu 2026-11-06: "Google takvimi bağlanamadı" — 403 hep
/// "yetki yok" sayılıyor, API'si kapalı proje sebepsiz başarısız oluyordu.
void main() {
  const disabled =
      '{"error":{"code":403,"message":"Google Calendar API has not been used '
      'in project 123 before or it is disabled. Enable it by visiting '
      'https://console.developers.google.com/apis/api/calendar-json.googleapis.com/overview?project=123 '
      'then retry.","status":"PERMISSION_DENIED","details":[{"reason":'
      '"SERVICE_DISABLED"}]}}';
  const scope =
      '{"error":{"code":403,"message":"Request had insufficient '
      'authentication scopes.","status":"PERMISSION_DENIED","details":'
      '[{"reason":"ACCESS_TOKEN_SCOPE_INSUFFICIENT"}]}}';

  test('API kapalı 403 tanınır, yetkisiz sayılmaz', () {
    expect(googleServiceDisabled(403, disabled), isTrue);
    expect(googleServiceDisabled(401, disabled), isFalse);
    expect(googleServiceDisabled(403, scope), isFalse);
    final e = GoogleCalendarException(403, disabled);
    expect(e.serviceDisabled, isTrue);
    expect(e.unauthorized, isFalse);
    expect(GoogleTasksException(403, disabled).unauthorized, isFalse);
    expect(GoogleCalendarException(403, scope).unauthorized, isTrue);
    expect(GoogleCalendarException(401, '').unauthorized, isTrue);
  });

  test('kapsam eksikliği tanınır', () {
    expect(googleScopeInsufficient(403, scope), isTrue);
    expect(GoogleCalendarException(403, scope).scopeInsufficient, isTrue);
  });

  test('etkinleştirme adresi gövdeden, yoksa kütüphane sayfası', () {
    expect(
      googleActivationUrl(disabled, 'calendar-json.googleapis.com'),
      'https://console.developers.google.com/apis/api/calendar-json.googleapis.com/overview?project=123',
    );
    expect(
      googleActivationUrl('{}', 'tasks.googleapis.com'),
      'https://console.cloud.google.com/apis/library/tasks.googleapis.com',
    );
  });
}
