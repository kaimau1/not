import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

/// Ölçüm raporu (F2.6): her senaryonun zaman çizelgesi özetlenir,
/// `build/perf/perf_summary.json`a yazılır ve bütçe denetlenir (F27.4,
/// AKICILIK_PLANI): kare build süresi p90 < 8 ms, p99 < 16 ms, en kötü
/// kare < 33 ms — biri aşılırsa koşu başarısız.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    const keys = [
      'average_frame_build_time_millis',
      '90th_percentile_frame_build_time_millis',
      '99th_percentile_frame_build_time_millis',
      'worst_frame_build_time_millis',
      'average_frame_rasterizer_time_millis',
      '90th_percentile_frame_rasterizer_time_millis',
      '99th_percentile_frame_rasterizer_time_millis',
      'missed_frame_build_budget_count',
      'frame_count',
    ];
    final report = <String, Map<String, Object?>>{};
    for (final e in data.entries) {
      final summary = TimelineSummary.summarize(
        Timeline.fromJson(e.value as Map<String, dynamic>),
      ).summaryJson;
      report[e.key] = {for (final k in keys) k: summary[k]};
    }
    final text = const JsonEncoder.withIndent('  ').convert(report);
    final out = File('build/perf/perf_summary.json');
    await out.parent.create(recursive: true);
    await out.writeAsString(text);
    stdout.writeln(text);
    const budgets = {
      '90th_percentile_frame_build_time_millis': 8.0,
      '99th_percentile_frame_build_time_millis': 16.0,
      'worst_frame_build_time_millis': 33.0,
    };
    final over = [
      for (final e in report.entries)
        for (final b in budgets.entries)
          if (((e.value[b.key] as num?) ?? 0) > b.value)
            '${e.key}: ${b.key} ${e.value[b.key]} > ${b.value} ms',
    ];
    if (over.isNotEmpty) {
      stderr.writeln('Bütçe aşıldı:\n${over.join('\n')}');
      exitCode = 1;
    }
  },
);
