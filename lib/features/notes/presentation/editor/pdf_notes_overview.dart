import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/page_notes.dart';
import 'text_wrap.dart';

/// Sayfa notlarının TOPLU görünümü: bütün sayfa notları tek akışta, her biri
/// "Sayfa N" başlığı altında.
///
/// Neden ayrı bir görünüm (kullanıcı isteği, 2026-08-07 / 9. tur KARAR 2):
/// iki bölmeli editörde her seferinde tek sayfanın notu görünür — kullanıcı
/// yazdıklarının TAMAMINI bir arada okuyamıyor, aradığı satır için sayfa sayfa
/// dolaşmak zorunda kalıyordu.
///
/// Notu OLAN sayfalar listelenir; boş sayfalar akışı seyreltip aranan satırı
/// gömerdi. Yeni sayfa notu iki bölmeli ekranda yazılır — buradaki başlığa
/// dokunmak o sayfaya götürür (ekran kapanır, sayfa numarası döner).
///
/// Alanlar DÜZENLENEBİLİR: salt okunur bir döküm, gözüne çarpan yazım
/// yanlışını düzeltmek için kullanıcıyı sayfa sayfa geri dolaştırırdı.
class PdfNotesOverviewScreen extends StatefulWidget {
  const PdfNotesOverviewScreen({
    super.key,
    required this.note,
    required this.attachment,
    required this.onPageNoteChanged,
    this.textStyle,
    this.richTheme,
  });

  final Note note;
  final Attachment attachment;

  /// Sayfa notu değişti: (1 tabanlı sayfa, metin).
  final void Function(int page, String text) onPageNoteChanged;

  final TextStyle? textStyle;
  final RichTextTheme? richTheme;

  @override
  State<PdfNotesOverviewScreen> createState() => _PdfNotesOverviewScreenState();
}

class _PdfNotesOverviewScreenState extends State<PdfNotesOverviewScreen> {
  /// Sayfa → alan denetleyicisi. Liste ekran AÇILIRKEN dondurulur: kullanıcı
  /// bir notu tümüyle silerken satırın ayağının altından kaybolmaması için
  /// (akış yeniden hesaplansaydı alan odaktayken ağaçtan düşerdi).
  late final List<int> _pages;
  late final Map<int, WrapTextController> _controllers;

  @override
  void initState() {
    super.initState();
    final ordered = orderedPageNotes(
      attachment: widget.attachment,
      pageNotes: widget.note.pageNotes,
    );
    _pages = [for (final e in ordered) e.page];
    _controllers = {
      for (final e in ordered) e.page: WrapTextController(text: e.text),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    for (final c in _controllers.values) {
      c.richTheme = widget.richTheme;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pdfAllPageNotes),
        // Belgenin adı alt satırda: birden çok PDF taşıyan notta hangi belgenin
        // notlarına bakıldığı ekrandan okunmalı.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: _pages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.pdfNoPageNotes,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: _pages.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlığa dokunmak o sayfaya götürür: toplu görünümde
                    // aradığını bulan kullanıcının bir sonraki isteği hep
                    // "sayfanın kendisini gör" oluyor.
                    InkWell(
                      onTap: () => Navigator.of(context).pop(page),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              l10n.pdfPage(page),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextField(
                      controller: _controllers[page],
                      style: widget.textStyle,
                      onChanged: (_) => widget.onPageNoteChanged(
                        page,
                        _controllers[page]!.logicalText,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
