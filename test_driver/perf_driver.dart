import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

/// Ölçüm raporu (F2.6): her senaryonun zaman çizelgesi özetlenir,
/// `build/perf/perf_summary.json`a yazılır ve bütçe denetlenir — p90 kare
/// build süresi 8 ms'yi aşarsa koşu başarısız.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    const keys = [
      'average_frame_build_time_millis',
      '90th_percentile_frame_build_time_millis',
      '99th_percentile_frame_build_time_millis',
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
    const budgetMs = 8.0;
    final over = [
      for (final e in report.entries)
        if (((e.value['90th_percentile_frame_build_time_millis'] as num?) ??
                0) >
            budgetMs)
          e.key,
    ];
    if (over.isNotEmpty) {
      stderr.writeln('Bütçe aşıldı (p90 build > $budgetMs ms): $over');
      exitCode = 1;
    }
  },
);
