import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/fixed_colors.dart';
import 'package:notlar/core/app_icons.dart';
import 'package:notlar/core/widgets/empty_state.dart';
import 'package:notlar/core/widgets/sheet_header.dart';
import 'package:notlar/core/widgets/skeleton.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **GÖRSEL BÜTÜNLÜK** (Faz 16, 2026-10-31): simge sözlüğü, levha iskeleti,
/// sabit renkler, yükleniyor/hata durumları. Kaynak taramaları eski
/// çakışmaların geri gelmesini yakalar.
void main() {
  final sources = [
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File &&
          f.path.endsWith('.dart') &&
          !f.path.contains('l10n${Platform.pathSeparator}generated'))
        f,
  ];

  List<String> offenders(RegExp pattern, {Set<String> allow = const {}}) => [
    for (final f in sources)
      if (!allow.any((a) => f.path.replaceAll('\\', '/').endsWith(a)))
        for (final (i, line) in f.readAsLinesSync().indexed)
          if (pattern.hasMatch(line)) '${f.path}:${i + 1}: ${line.trim()}',
  ];

  group('F16.1 simge sözlüğü', () {
    test('Gelen zarf, Not paketi zip — arşiv kutusuna benzeyen simge yok', () {
      expect(offenders(RegExp(r'Icons\.(move_to_inbox|inventory_2)')), isEmpty);
    });

    test('sözlükteki simgeler dosyalarda doğrudan yazılmaz', () {
      // Bu simgelerin anlamı tek: AppIcons'tan alınır. Klasör simgesi
      // seçicisindeki "kitap" (note_folder.dart) kullanıcının seçtiği bir
      // simge, sözlüğe girmez.
      expect(
        offenders(
          RegExp(
            r'Icons\.(archive_outlined|unarchive_outlined|palette_outlined|'
            r'menu_book_outlined|library_add_outlined|'
            r'content_copy_outlined|copy_outlined)\b',
          ),
          allow: {'lib/core/app_icons.dart', 'folders/domain/note_folder.dart'},
        ),
        isEmpty,
      );
    });

    test('her anlamın simgesi ayrı', () {
      const meanings = {
        'archive': AppIcons.archive,
        'inbox': AppIcons.inbox,
        'notebook': AppIcons.notebook,
        'guide': AppIcons.guide,
        'notePackage': AppIcons.notePackage,
        'copy': AppIcons.copy,
        'duplicate': AppIcons.duplicate,
        'appearance': AppIcons.appearance,
        'color': AppIcons.color,
        'moveToFolder': AppIcons.moveToFolder,
        'search': AppIcons.search,
        'fullscreen': AppIcons.fullscreen,
        'restore': AppIcons.restore,
        'friends': AppIcons.friends,
      };
      final byCode = <int, List<String>>{};
      for (final e in meanings.entries) {
        (byCode[e.value.codePoint] ??= []).add(e.key);
      }
      expect(byCode.values.where((v) => v.length > 1), isEmpty);
    });
  });

  group('F16.2 levha iskeleti', () {
    test('bölüm başlıkları BÜYÜK HARFE çevrilmez (cümle düzeni)', () {
      expect(
        offenders(
          RegExp(r'(title|text|label|_groupTitle\(.*\))\.toUpperCase\(\)'),
        ),
        isEmpty,
      );
    });

    testWidgets('başlık solda, ✕ sağda ve levhayı kapatır', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SheetHeader(title: 'Süz'),
                      SectionLabel('Tür ve durum'),
                    ],
                  ),
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      final title = tester.getCenter(find.text('Süz'));
      final close = find.byKey(const ValueKey('sheet-close'));
      expect(tester.getCenter(close).dx, greaterThan(title.dx));
      // ✕ gerçekten sağ kenarda (Flexible + Spacer ortaya düşürüyordu).
      expect(
        tester.getTopRight(close).dx,
        greaterThan(tester.getSize(find.byType(Scaffold)).width - 16),
      );
      expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
      expect(find.byTooltip('Kapat'), findsOneWidget);
      // Bölüm başlığı yazıldığı gibi.
      expect(find.text('Tür ve durum'), findsOneWidget);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Süz'), findsNothing);
    });
  });

  group('F16.3 sabit renkler', () {
    test('gökkuşağı halkası tek yerde', () {
      expect(
        offenders(
          RegExp(r'SweepGradient\('),
          allow: {'lib/app/theme/fixed_colors.dart'},
        ),
        isEmpty,
      );
    });

    test('renkli dairenin üstündeki mürekkep okunur', () {
      expect(FixedColors.inkOn(const Color(0xFFFFFFFF)), Colors.black87);
      expect(FixedColors.inkOn(const Color(0xFF263238)), Colors.white);
    });
  });

  group('F16.4 yükleniyor ve hata', () {
    Widget host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: Scaffold(body: child),
    );

    testWidgets('liste iskeleti genişliğe göre sütun açar', (tester) async {
      await tester.pumpWidget(host(const NoteListSkeleton()));
      expect(find.byType(NoteGridSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Kısa alanda taşmaz (Hatırlatıcılar'da RenderFlex taşması yakalandı).
      await tester.pumpWidget(
        host(const SizedBox(height: 120, child: NoteListSkeleton())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hata görünümü okunur metin ve Tekrar dene', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        host(ErrorState(error: StateError('x'), onRetry: () => retried++)),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Tekrar dene'));
      expect(retried, 1);
    });

    test('liste ekranları ilk yüklemede dönen çark göstermez', () {
      expect(
        offenders(
          RegExp(
            r'loading: \(\) => const Center\(child: CircularProgressIndicator',
          ),
          allow: {},
        ).where(
          (l) =>
              l.contains('archive_screen') ||
              l.contains('trash_screen') ||
              l.contains('folder_screen') ||
              l.contains('inbox_screen') ||
              l.contains('reminders_screen'),
        ),
        isEmpty,
      );
    });
  });
}
