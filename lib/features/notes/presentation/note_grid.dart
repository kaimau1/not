import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../domain/note.dart';
import 'note_card.dart';

/// Bir bölüm bu kadar karttan uzunsa DETERMİNİSTİK ızgara bırakılır ve tembel
/// masonry'ye dönülür (bkz. [balancedNoteColumns]).
///
/// Deterministik ızgara bölümün TAMAMINI tek kutuda çizer: yerleşim ve sıra
/// kusursuz olur ama kartların hiçbiri tembel kalmaz. Bölümler zaten
/// sabitlenmiş/bugün/bu hafta/daha önce diye bölündüğünden gerçek kullanımda
/// bu sınıra çok seyrek varılır; vardığında da eski davranış (tembel masonry)
/// aynen sürer, yani çok notlu kitaplıkta ilk kare bedeli büyümez.
const int kStaticGridLimit = 200;

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
  final heights = List<double>.filled(columns, 0);
  final buckets = List.generate(columns, (_) => <Widget>[]);
  for (var index = 0; index < items.length; index++) {
    var target = 0;
    for (var c = 1; c < columns; c++) {
      // Eşitlikte SOLDAKİ sütun kazanır — okuma sırası (soldan sağa) korunur.
      if (heights[c] < heights[target] - 0.5) target = c;
    }
    heights[target] += estimateNoteCardHeight(items[index], cellWidth) + 8;
    buckets[target].add(RepaintBoundary(child: cell(index)));
  }
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
    // Çok uzun listede tembelliği bırakmamak için eski masonry (bkz.
    // [kStaticGridLimit]).
    if (notes.length > kStaticGridLimit) {
      return MasonryGridView.count(
        padding: padding,
        crossAxisCount: columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: notes.length,
        itemBuilder: itemBuilder,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - padding.horizontal - 8 * (columns - 1)) /
            columns;
        return SingleChildScrollView(
          padding: padding,
          child: balancedNoteColumns(
            items: notes,
            columns: columns,
            cellWidth: cellWidth,
            cell: (index) => itemBuilder(context, index),
          ),
        );
      },
    );
  }
}
