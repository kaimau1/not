import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';

/// Hızlı ekle → liste notu (2026-11-20 hızlı ekle / akıllı liste turu):
/// bavul listesi tanınır (maddeler bölünür), reyon sırasındaki listede yeni
/// madde kendi reyonuna girer.
void main() {
  var seq = 0;
  String id() => 'y${seq++}';
  Note list(String title, List<String> items, {bool header = false}) => Note(
    id: 'n-$title-${items.length}',
    type: NoteType.checklist,
    title: title,
    items: [
      if (header) const NoteItem(id: 'h', text: 'Başlık', header: true),
      for (var i = 0; i < items.length; i++)
        NoteItem(id: 'i$i', text: items[i]),
    ],
  );
  List<String> texts(Note note, String content) {
    final r = quickDropFields(note, content, locale: 'tr', newId: id);
    return [
      for (final m in (r.fields['items'] as List? ?? const []))
        (m as Map)['text'] as String,
    ];
  }

  group('tür', () {
    test('başlıktan: kök eşlenir, ön ek değil', () {
      expect(smartKindOfTitle('Bavul listesi'), SmartListKind.packing);
      expect(smartKindOfTitle('Antalya tatili'), SmartListKind.packing);
      expect(smartKindOfTitle('Kamp malzemeleri'), SmartListKind.packing);
      expect(smartKindOfTitle('Marketten alınacaklar'), SmartListKind.shopping);
      expect(smartKindOfTitle('Haftalık alışveriş'), SmartListKind.shopping);
      // İçerir-araması bunları da tür sayıyordu.
      expect(smartKindOfTitle('Pazartesi işleri'), isNull);
      expect(smartKindOfTitle('Kampanya fikirleri'), isNull);
      expect(smartKindOfTitle('Marketing planı'), isNull);
    });

    test('"Pazartesi" listesi alışveriş sayılmaz: fiil içerikte kalır', () {
      expect(looksLikeGrocery('Pazartesi işleri', const [], 'tr'), isFalse);
      expect(texts(list('Pazartesi işleri', ['Rapor']), 'kitap al'), [
        'Rapor',
        'Kitap al',
      ]);
    });

    test('maddelerden bavul: başlık bir şey söylemese de', () {
      expect(
        noteListKind(list('Antalya', ['Pasaport', 'Tişört']), 'tr'),
        SmartListKind.packing,
      );
      expect(
        noteListKind(list('Yapılacaklar', ['Faturayı öde']), 'tr'),
        SmartListKind.generic,
      );
    });
  });

  test('bavul listesine eklenenler maddelere bölünür (cümleli kip değil)', () {
    // Önceden tek madde: "Şort mayo şarj aleti".
    final got = texts(
      list('Bavul listesi', ['Pasaport', 'Tişört']),
      'şort mayo şarj aleti',
    );
    expect(got, containsAll(['Şort', 'Mayo', 'Şarj aleti']));
    expect(got, hasLength(5));
  });

  group('reyon yerleşimi', () {
    test('sıralı market listesinde yeni madde kendi reyonuna', () {
      // Manav → kahvaltılık → temizlik (alışveriş listesinin kurduğu sıra).
      final note = list('Market listesi', ['Domates', 'Süt', 'Deterjan']);
      expect(texts(note, 'elma'), ['Domates', 'Elma', 'Süt', 'Deterjan']);
      expect(texts(note, 'peynir çamaşır suyu'), [
        'Domates',
        'Süt',
        'Peynir',
        'Deterjan',
        'Çamaşır suyu',
      ]);
    });

    test('tanınmayan madde ve sırasız liste: eskisi gibi sona', () {
      final sorted = list('Market listesi', ['Domates', 'Süt']);
      expect(texts(sorted, 'zımbırtı'), ['Domates', 'Süt', 'Zımbırtı']);
      final unsorted = list('Market listesi', ['Süt', 'Domates']);
      expect(texts(unsorted, 'elma'), ['Süt', 'Domates', 'Elma']);
    });

    test('başlıklı listede ve tek tanınan maddede sıra bozulmaz (sona)', () {
      final headed = list('Market', ['Domates', 'Süt'], header: true);
      expect(texts(headed, 'elma').last, 'Elma');
      final one = list('Market listesi', ['Süt']);
      expect(texts(one, 'domates'), ['Süt', 'Domates']);
    });

    test('bavul listesinde belgeler önce', () {
      final note = list('Bavul listesi', ['Pasaport', 'Tişört', 'Şarj aleti']);
      expect(texts(note, 'kimlik'), [
        'Pasaport',
        'Kimlik',
        'Tişört',
        'Şarj aleti',
      ]);
    });
  });

  test('önizleme planı ekleme ile aynı hesabı verir', () {
    final note = list('Market listesi', ['Süt']);
    final plan = quickDropPlan(note, 'süt ekmek x2', locale: 'tr')!;
    expect(plan.texts, ['Ekmek (2)']);
    final text = Note(id: 't', type: NoteType.text, title: 'Fikirler');
    expect(quickDropPlan(text, 'bir fikir', locale: 'tr'), isNull);
  });
}
