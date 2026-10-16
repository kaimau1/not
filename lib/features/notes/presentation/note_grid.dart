import 'package:flutter/material.dart';

import '../domain/note.dart';
import 'note_card.dart';

/// Kartların sütunlara DETERMİNİSTİK dağılımı: her sütunun kart sırası
/// (bkz. [balancedNoteColumns] — kart en kısa TAHMİNİ sütuna düşer).
List<List<int>> balancedColumnAssignment(
  List<Note> items,
  int columns,
  double cellWidth,
) {
  final heights = List<double>.filled(columns, 0);
  final buckets = List.generate(columns, (_) => <int>[]);
  for (var index = 0; index < items.length; index++) {
    var target = 0;
    for (var c = 1; c < columns; c++) {
      // Eşitlikte SOLDAKİ sütun kazanır — okuma sırası (soldan sağa) korunur.
      if (heights[c] < heights[target] - 0.5) target = c;
    }
    heights[target] += estimateNoteCardHeight(items[index], cellWidth) + 8;
    buckets[target].add(index);
  }
  return buckets;
}

/// [balancedNoteColumns]'ın TEMBEL sliver hâli — ana ekran, klasör ve arşiv.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-16: "performans hâlâ istediğim gibi
/// değil, FPS düşük, her alanda süper akıcı olsun"): deterministik ızgara
/// bölümün TAMAMINI tek bir `Column` kutusunda çiziyordu — 200 karta kadar
/// her kart (ekranın kilometrelerce altındakiler dahil) kuruluyor, ölçülüyor,
/// küçük resmi/PDF kapağı/video karesi çözülüp bellekte tutuluyordu. Ana
/// ekranın her yeniden kurulumunda (bir not senkronlandı, seçim değişti)
/// yüzlerce kart baştan kuruluyordu; açılışta da ilk kare bütün kapakları
/// beklemişti.
///
/// Şimdi sütun ATAMASI aynı (deterministik, tahmini yükseklikle) ama her
/// sütun kendi tembel `SliverList`'i: `SliverCrossAxisGroup` sütunları yan
/// yana aynı kaydırmada dizer, yalnız görünen (ve kaydırma payındaki) kartlar
/// kurulur. Sliver listeleri her öğeyi kendiliğinden `RepaintBoundary`'ye
/// sarar.
Widget sliverBalancedNoteColumns({
  required List<Note> items,
  required int columns,
  required double cellWidth,
  required Widget Function(BuildContext context, int index) cell,
  double spacing = 8,
}) {
  if (columns <= 1) {
    return SliverList.separated(
      itemCount: items.length,
      itemBuilder: cell,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
    );
  }
  final buckets = balancedColumnAssignment(items, columns, cellWidth);
  return SliverCrossAxisGroup(
    slivers: [
      for (var c = 0; c < columns; c++) ...[
        if (c > 0)
          SliverConstrainedCrossAxis(
            maxExtent: spacing,
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        SliverCrossAxisExpanded(
          flex: 1,
          sliver: SliverList.separated(
            itemCount: buckets[c].length,
            itemBuilder: (context, i) => cell(context, buckets[c][i]),
            separatorBuilder: (_, _) => SizedBox(height: spacing),
          ),
        ),
      ],
    ],
  );
}

/// Kartları TAHMİNİ yüksekliklerine göre sütunlara dağıtıp her sütunu kendi
/// `Column`'unda çizer — masonry ızgaranın deterministik karşılığı.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-10: "notların sıralaması düzgün
/// olmuyor, kaymalar oluyor; özellikle 2 kolonluda sağ kolonda sürekli
/// boşluklar kalıyor"): `SliverMasonryGrid` her kartı YERLEŞİM ANINDA en kısa
/// sütuna atar. Yani sütun ataması kart yüksekliklerinin o anki değerine
/// bağlıydı; yükseklik kıpırdadığında (seçim çerçevesi, küçük resmin gelmesi,
/// notun güncellenmesi, tembel yerleşimin sırası) aynı not başka bir sütuna
/// geçiyor, üstündeki kartlar kayıyor ve bir sütunda kapanmayan boşluklar
/// kalıyordu.
///
/// Burada dağıtım ÇİZİMDEN ÖNCE, [estimateNoteCardHeight] ile yapılır: hangi
/// kartın hangi sütuna düşeceği yalnız notun içeriğine bağlıdır, yerleşime
/// değil. Tahmin şaşarsa bedeli yalnız sütunların DİBİNDEKİ boşluk farkıdır;
/// kartların arasında boşluk oluşamaz (her sütun sıkı bir `Column`).
///
/// **Her hücre bir [RepaintBoundary]** içinde: sliver listeleri bunu
/// kendiliğinden ekler (`addRepaintBoundaries`), düz `Column` EKLEMEZ. O sınır
/// olmadan tek bir kartın kıpırdaması (seçim çerçevesi, küçük resmin gelmesi,
/// odak halkasının nabzı) bölümün TAMAMINI yeniden boyatıyordu.
Widget balancedNoteColumns({
  required List<Note> items,
  required int columns,
  required double cellWidth,
  required Widget Function(int index) cell,
}) {
  final buckets = [
    for (final column in balancedColumnAssignment(items, columns, cellWidth))
      [for (final index in column) RepaintBoundary(child: cell(index))],
  ];
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var c = 0; c < columns; c++) ...[
        if (c > 0) const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < buckets[c].length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                buckets[c][i],
              ],
            ],
          ),
        ),
      ],
    ],
  );
}

/// Ana ekranın ızgarasının KAYDIRILABİLİR hâli — klasör ve arşiv sayfaları
/// bunu kullanır.
///
/// KÖK NEDEN: ana ekran 2026-08-10'da masonry'den [balancedNoteColumns]'a
/// geçti ("kaymalar / sağ sütunda kapanmayan boşluklar"), ama klasör sayfası
/// ve arşiv eski `MasonryGridView`'da kaldı — yani aynı hata klasörün İÇİNDE
/// aynen sürüyordu. Artık üç yüzey de tek koddan geçiyor.
class NoteBalancedGrid extends StatelessWidget {
  const NoteBalancedGrid({
    super.key,
    required this.notes,
    required this.columns,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 88),
  });

  final List<Note> notes;
  final int columns;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // TEMBEL (bkz. [sliverBalancedNoteColumns]): yalnız görünen kartlar
    // kurulur.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - padding.horizontal - 8 * (columns - 1)) /
            columns;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: padding,
              sliver: sliverBalancedNoteColumns(
                items: notes,
                columns: columns,
                cellWidth: cellWidth,
                cell: itemBuilder,
              ),
            ),
          ],
        );
      },
    );
  }
}
