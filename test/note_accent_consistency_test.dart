import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/note_colors.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/title_fit.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **KART ↔ AÇIK NOT AYNI** (kullanıcı bulgusu 2026-11-04, iki ekran
/// görüntüsüyle: "notun açık hali ile dashboarddaki görüntüsü farklı" — koyu
/// pembe notta kart pembe, açık not petrol yeşili kutucuk gösteriyordu).
/// Kutucuk, "Yeni madde" ve haplar iki yerde de [NoteAccent]'ten.
final _light = AppTheme.of(ThemeFamily.sage, Brightness.light);

const _items = [
  NoteItem(id: 'a', text: 'açık madde'),
  NoteItem(id: 'b', text: 'bitmiş madde', checked: true),
];

Note _note({int? customColor, NoteColor color = NoteColor.none}) => Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Not uygulaması geliştirme hataları',
  items: _items,
  tags: const ['yazilim'],
  pinned: true,
  customColor: customColor,
  color: color,
);

Future<void> _pumpEditor(WidgetTester tester, Note note) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUidProvider.overrideWithValue(null),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(null),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      noteStreamProvider('n').overrideWith((ref) => Stream.value(note)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _light,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NoteEditorScreen(noteId: 'n'),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpCard(WidgetTester tester, Note note) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: _light,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 300, child: NoteCard(note: note)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

/// Editördeki İŞARETLİ kutunun dolgusu.
Color _editorCheckedFill(WidgetTester tester) {
  final box = tester
      .widgetList<Checkbox>(find.byType(Checkbox))
      .firstWhere((c) => c.value ?? false);
  return box.fillColor!.resolve({WidgetState.selected})!;
}

/// Karttaki İŞARETLİ kutunun rengi.
Color _cardCheckedIcon(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.check_box).first).color!;

/// Editörün notu çizdiği tema (zıt okunurluk teması dahil).
ColorScheme _schemeFor(Note note) {
  final background = NoteColors.noteSurfaceIn(_light, note);
  return (NoteColors.inkThemeFor(_light, background) ?? _light).colorScheme;
}

void main() {
  test('kural: renkli notta koyu ton, renksizde temanın vurgusu; soluk', () {
    final scheme = _light.colorScheme;
    const accent = Color(0xFFAA3377);
    expect(
      NoteCheckColors.checked(scheme, accent),
      accent.withValues(alpha: NoteCheckColors.checkedDim),
    );
    expect(
      NoteCheckColors.checked(scheme, null),
      scheme.primary.withValues(alpha: NoteCheckColors.checkedDim),
    );
    expect(NoteCheckColors.unchecked(scheme, accent), accent);
    expect(NoteCheckColors.unchecked(scheme, null), scheme.onSurfaceVariant);
  });

  for (final (name, note) in [
    // Kullanıcının notu: açık temada koyu mor/siyah özel renk.
    ('koyu özel renk', _note(customColor: 0xFF1A0B1F)),
    ('hazır renk (adaçayı)', _note(color: NoteColor.sage)),
    ('renksiz', _note()),
  ]) {
    testWidgets('$name: kart ve editör kutucuğu AYNI renk', (tester) async {
      await _pumpCard(tester, note);
      final card = _cardCheckedIcon(tester);
      await _pumpEditor(tester, note);
      final editor = _editorCheckedFill(tester);
      expect(editor, card);
      // Beklenen renk: notun kendi tonu (renksizde temanın vurgusu).
      final element = tester.element(find.byType(Checkbox).first);
      final accent = NoteAccent.maybeOf(element)?.accent;
      expect(editor, NoteCheckColors.checked(_schemeFor(note), accent));
      if (note.color != NoteColor.none || note.customColor != null) {
        expect(accent, isNotNull);
      } else {
        expect(accent, isNull);
      }
      await _end(tester);
    });
  }

  testWidgets('renkli notta "Yeni madde" ve etiket hapı notun tonunda', (
    tester,
  ) async {
    final note = _note(customColor: 0xFF1A0B1F);
    await _pumpEditor(tester, note);
    final element = tester.element(find.byType(Checkbox).first);
    final accent = NoteAccent.maybeOf(element)!.accent!;
    final add = tester.widget<TextButton>(
      find.byKey(const ValueKey('items-add-button')),
    );
    expect(add.style?.foregroundColor?.resolve(<WidgetState>{}), accent);
    // Etiket üst çubukta, tarihin solunda (2026-11-05).
    final tag = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('editor-bar-tags')),
        matching: find.text('#yazilim'),
      ),
    );
    expect(tag.style?.color, accent);
    await _end(tester);
  });

  test('başlık ölçümü alanın birleşik stiliyle (harf aralığı dahil)', () {
    // TextField M3'te stilini `bodyLarge`ın üstüne birleştirir: başlık harf
    // aralığı vermezse alan 0,5'i miras alır — ölçüm de almalı.
    const fieldDefault = TextStyle(fontSize: 16, letterSpacing: 0.5);
    const title = TextStyle(fontSize: 24, fontWeight: FontWeight.w500);
    final merged = fieldMergedStyle(fieldDefault, title);
    expect(merged.letterSpacing, 0.5);
    expect(merged.fontSize, 24);
    const text = 'Not uygulaması geliştirme hataları';
    final plain = fitTitleFontSize(
      spanFor: (s) => TextSpan(
        text: text,
        style: title.copyWith(fontSize: s),
      ),
      // Test yazı tipinde her harf 1 em: taban 14'e inmeden ölçülebilsin.
      maxWidth: 600,
      baseSize: 24,
    );
    final spaced = fitTitleFontSize(
      spanFor: (s) => TextSpan(
        text: text,
        style: merged.copyWith(fontSize: s),
      ),
      // Test yazı tipinde her harf 1 em: taban 14'e inmeden ölçülebilsin.
      maxWidth: 600,
      baseSize: 24,
    );
    // Harf aralığı hesaba katılınca daha küçük boy seçilir.
    expect(spaced, lessThan(plain));
  });

  testWidgets('uzun başlık alana sığar (çipin altına girmez)', (tester) async {
    await _pumpEditor(tester, _note(customColor: 0xFF1A0B1F));
    final title = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .firstWhere((e) => e.controller.text.startsWith('Not uygulaması'));
    final state = tester.state<EditableTextState>(find.byWidget(title));
    final render = state.renderEditable;
    expect(
      render.getMaxIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(render.size.width),
    );
    await _end(tester);
  });
}
