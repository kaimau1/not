part of 'note_editor_screen.dart';

typedef _EditorHeaderResult = ({
  Widget header,
  List<Attachment> imageAttachments,
  double hintLineHeight,
  bool useCanvasHint,
});

typedef _EditorContentResult = ({
  Widget body,
  Widget? pageBarDock,
  bool readingColumn,
  double toolbarHeight,
});

extension _NoteEditorContentBuild on _NoteEditorScreenState {
  _EditorHeaderResult _buildEditorHeader(
    BuildContext context, {
    required AppLocalizations l10n,
    required Note note,
    required Color? noteAccent,
    required ThemeData theme,
    required TextStyle noteBodyStyle,
  }) {
    // Üstündeki çip satırına yapışık: aradaki 8 dp, çipler başlığın ALTINDAYKEN
    // üst barla başlığı ayırmak içindi; artık o işi çip satırı görüyor.
    final titleInBar = _titleInBar(note);
    final titleBaseStyle = noteTitleStyle(
      theme,
      note,
      // Üst çubukta 48 dp'ye sığan boy (bkz. [_titleInBar]).
      fontSize:
          (titleInBar
              ? 18.0
              : (theme.textTheme.headlineSmall?.fontSize ?? 24)) *
          note.titleFontScale,
    );
    // BAŞLIK ÜST ÇUBUKTA (kullanıcı isteği 2026-11-03: "üste sabitlemede
    // başlık sabitin üstünde olmalı; şu an not alanında kalıyor ve orayı
    // daraltıyor" + "balonlu PDF başlığını kaldır, ana sayfada yazmasına
    // gerek yok"): medya/belge notun TEPESİNDEYKEN (sabit bölme ya da
    // balonlu belge) başlık gövdeden kalkar, üst çubukta tarihin yerine
    // oturur — gövdede hiç satır harcamaz, belge ve not yukarı çıkar.
    final titleBaseSize = titleBaseStyle.fontSize ?? 24;
    final titleField = Padding(
      padding: titleInBar
          ? const EdgeInsetsDirectional.only(start: 4)
          : const EdgeInsetsDirectional.fromSTEB(16, 2, 4, 0),
      // Başlığın yazı ölçeği değişince yumuşak oturur (bkz. ScaleSettle).
      child: ScaleSettle(
        value: note.titleFontScale,
        // UZUN BAŞLIK KÜÇÜLEREK SIĞAR (kullanıcı isteği 2026-11-01, bkz.
        // [fitTitleFontSize]): yazı değiştikçe yalnız bu parça yeniden
        // kurulur. Satır yüksekliği taban boyda SABİT (strut) — yazı
        // küçülürken alttaki sayfa harf harf yukarı kaymasın.
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _titleController,
          builder: (context, _, _) => LayoutBuilder(
            builder: (context, box) {
              // ÖLÇÜM ALANIN ÇİZDİĞİ STİLLE (kullanıcı bulgusu 2026-11-04:
              // "uzun başlık sağdaki çipin altına giriyor"). KÖK NEDEN:
              // TextField stili temanın `bodyLarge`ının ÜSTÜNE birleştirir;
              // başlık stili harf aralığı vermediği için alan `bodyLarge`ın
              // 0,5 aralığını miras alıyor, ölçüm ise aralıksız yapılıyordu —
              // 34 harflik başlık ~17 px dar ölçülüp "sığdı" sayılıyordu.
              final fieldStyle = fieldMergedStyle(
                Theme.of(context).textTheme.bodyLarge,
                titleBaseStyle,
              );
              final fitted = fitTitleFontSize(
                spanFor: (size) => _titleController.buildTextSpan(
                  context: context,
                  style: fieldStyle.copyWith(fontSize: size),
                  withComposing: false,
                ),
                // İmleç ve iç dolgu payı.
                maxWidth: box.maxWidth - 8,
                baseSize: titleBaseSize,
                textScaler: MediaQuery.textScalerOf(context),
                textDirection: Directionality.of(context),
              );
              return ValueListenableBuilder<bool>(
                valueListenable: AutoSpell.enabled,
                builder: (_, autoFix, _) => TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  readOnly: _readOnly,
                  autocorrect: autoFix,
                  onChanged: (_) => _mutate(
                    (n) => n.copyWith(title: _titleController.logicalText),
                  ),
                  style: titleBaseStyle.copyWith(fontSize: fitted),
                  strutStyle: StrutStyle(
                    fontSize: titleBaseSize,
                    height: titleBaseStyle.height,
                    forceStrutHeight: true,
                  ),
                  // TEK SATIR (kullanıcı isteği 2026-08-08: "başlık tek satırdan
                  // taşmasın"): sığmayan başlık önce küçülür (yukarıda), en küçük
                  // boyda da sığmazsa alanın içinde yatay kayar.
                  // ignore: avoid_redundant_argument_values
                  maxLines: 1,
                  // Başlıkta kelime başları büyük (kullanıcı isteği 2026-11-08): sanal
                  // klavye kendisi büyütür; fiziksel klavye/web için yazım düzelt
                  // açıkken [AutoSpell] (title kipi) aynı kuralı uygular.
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  // Varsayılan `next` odak sırasındaki bir SONRAKİ öğeye gider — metin
                  // olmayan bir öğeye düşerse klavye kapanıyordu. "İleri" doğrudan
                  // gövdeye (liste notunda ilk maddeye) atlar.
                  onEditingComplete: _focusAfterTitle,
                  // Başlık da biçimlendirilebiliyor: Kes/Kopyala temiz-metin sürümü
                  // (gövdeyle aynı gerekçe).
                  contextMenuBuilder: (menuContext, state) =>
                      NoteSelectionToolbar(
                        editableState: state,
                        formatController: _titleController,
                        readOnly: _readOnly,
                        onFormatCommit: () => _mutate(
                          (n) =>
                              n.copyWith(title: _titleController.logicalText),
                          immediate: true,
                        ),
                        buttonItems: arrangeSelectionMenu(
                          platform: cleanClipboardMenuItems(state),
                        ),
                      ),
                  decoration: InputDecoration(
                    hintText: l10n.titleHint,
                    filled: false,
                    border: InputBorder.none,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Notun bağlı olduğu klasör (varsa) çipte gösterilir.
    final folders =
        ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[];
    NoteFolder? noteFolder;
    if (note.folderId != null) {
      for (final f in folders) {
        if (f.id == note.folderId) {
          noteFolder = f;
          break;
        }
      }
    }

    // Başlık altındaki çip satırı: EKLEME eylemlerinin tümü tek bir "+"
    // menüsünde, satırda ise yalnız GERÇEKTEN VAR OLANLAR (hatırlatıcı,
    // klasör, etiketler) durur.
    //
    // Eskiden "Hatırlat" ve "Klasör" boşken bile birer çip kaplıyor, yanlarına
    // "Etiket · Başlık · Alarm" adlı geniş bir çip daha giriyordu; üç ekleme
    // düğmesi satırı doldurduğu için asıl bilgi (etiketler) ekrandan taşıyordu
    // (ekran görüntüsündeki dağınıklık). Artık satır boş notta tek bir "+"
    // düğmesinden ibaret, doldukça büyür.
    // Ortak çalışan eklenebilir mi: yalnız bu cihazdaki not kimseyle
    // paylaşılamaz; kişiselleştirmede "Ortak çalışma" kapatılabilir.
    final collabPossible =
        widget.ownerId != null ||
        !(ref.read(notesRepositoryProvider)?.isLocal(widget.noteId) ?? false);
    final canCollab = Customizable.shows(UiItem.topCollab) && collabPossible;
    // TEK "+" (F38.3): ne dolu olduğu çip şeridinde; paylaşım durumu yanında
    // (paylaşılmışsa). Levha [_openMetaMenu]; `note-meta-chip` anahtarı korunur.
    final actionsMenu = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Düzen modunda gizliyken de çerçeveli görünür (P63 PB7); normal
        // kipte gizliyse yer kaplamaz.
        if (collabPossible)
          Customizable(id: UiItem.topCollab, child: _collabMarker(theme)),
        IconButton(
          key: const ValueKey('note-meta-chip'),
          tooltip: l10n.noteMetaMenu,
          visualDensity: VisualDensity.compact,
          icon: ValueListenableBuilder<bool>(
            valueListenable: _titleGeneratingN,
            builder: (context, generating, _) => generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.add,
                    size: 22,
                    color: noteAccent ?? theme.colorScheme.onSurfaceVariant,
                  ),
          ),
          onPressed: () =>
              _openMetaMenu(note, noteFolder?.iconData, canCollab: canCollab),
        ),
      ],
    );

    // Çip yazısı: gövdeyle aynı aileden ama küçük — satır üst bar ile başlık
    // arasındaki dar banda sığmalı (bkz. [metaChips]).
    final chipLabelStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12.5,
      // Haplar kartın etiketiyle aynı: renkli notta koyu ton, renksizde soluk.
      color: noteAccent ?? theme.colorScheme.onSurfaceVariant,
    );

    // BALONLU ⇄ KLASİK görünüm çipleri buradaydı (başlığın altında, etiket ve
    // klasör çipleriyle aynı kayan şeritte). Kullanıcı bulgusu 2026-10-16:
    // "kolay geçişin yeri ve düzeni iyi değil". Görünüm artık EKİN YANINDA
    // tek bir üçlü anahtar (Sabit / Yüzen / Balonlu — bkz.
    // view_mode_switch.dart); balonlu görünümde başlık satırının sağında.
    final metaChildren = <Widget>[
      // Yalnız KURULU hatırlatıcı çipte görünür; kurmak "+" menüsünden.
      if (note.reminderAt != null)
        InputChip(
          avatar: Icon(
            note.reminderRepeat.isEmpty ? Icons.alarm : Icons.repeat,
            size: 14,
          ),
          // Dar alanda çip etiketleri KISALTILIR (`...`): sığmayan bir metin
          // `Chip` içinde taşma hatası verir.
          label: Text(
            note.reminderRepeat.isEmpty
                ? DateFormat('d MMM HH:mm').format(note.reminderAt!)
                : '${DateFormat('d MMM HH:mm').format(note.reminderAt!)} · '
                      '${reminderRepeatLabel(context.l10n, ReminderRepeat.parse(note.reminderRepeat))}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          labelStyle: chipLabelStyle,
          padding: _NoteEditorScreenState._kChipPadding,
          visualDensity: _NoteEditorScreenState._kChipDensity,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          deleteIconBoxConstraints: _NoteEditorScreenState._kChipDeleteBox,
          onPressed: _pickReminder,
          onDeleted: _clearReminder,
        ),
      // ZAMANLI NOT: kurulu süre çipte; kurmak ⋮ menüsünden.
      if (note.expiresAt != null)
        InputChip(
          avatar: const Icon(Icons.hourglass_bottom, size: AppIconSize.xs),
          label: Text(
            noteExpiryChipText(context.l10n, note.expiresAt!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          labelStyle: chipLabelStyle,
          padding: _NoteEditorScreenState._kChipPadding,
          visualDensity: _NoteEditorScreenState._kChipDensity,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          deleteIconBoxConstraints: _NoteEditorScreenState._kChipDeleteBox,
          onPressed: _pickExpiry,
          onDeleted: _clearExpiry,
        ),
      // GERİ BAĞLANTILAR (F18.16): bu nota bağlanan notlar. YALNIZ varken
      // listeye girer — KÖK NEDEN (kullanıcı bulgusu 2026-11-05: "etiket
      // satırından kalan kısım boşluk olarak kalmış"): çip boşken kendini
      // `SizedBox.shrink` çiziyordu ama listede durduğu için şerit hiç boş
      // sayılmıyor, etiketler üst çubuğa taşındıktan sonra başlığın altında
      // 36 dp'lik boş bir bant kalıyordu.
      // KÖK KURULUM YOK (K32 S27): kök yalnız "geri bağlantı var mı"yı
      // dinler; liste akışının her yayını (her kayıt yankısı, yandaki notta
      // yazmak) bütün editörü yeniden kuruyordu. Sayı/başlıklar çipte.
      if (ref.watch(
        backlinksIndexProvider.select(
          (index) => (index[note.id] ?? const <Note>[]).isNotEmpty,
        ),
      ))
        Consumer(
          builder: (context, ref, _) => BacklinksChip(
            noteId: note.id,
            backlinks: ref.watch(
              backlinksIndexProvider.select(
                (index) => index[note.id] ?? const <Note>[],
              ),
            ),
            labelStyle: chipLabelStyle,
          ),
        ),
      // Klasör çipi yalnız notun klasörü VARSA; seçmek "+" menüsünden.
      if (noteFolder != null)
        InputChip(
          avatar: Icon(noteFolder.iconData, size: 14),
          label: Text(
            noteFolder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          labelStyle: chipLabelStyle,
          padding: _NoteEditorScreenState._kChipPadding,
          visualDensity: _NoteEditorScreenState._kChipDensity,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          deleteIconBoxConstraints: _NoteEditorScreenState._kChipDeleteBox,
          onPressed: _pickFolder,
          onDeleted: () =>
              _mutate((n) => n.copyWith(clearFolderId: true), immediate: true),
        ),
      // Etiketler üst çubukta, tarihin solunda (kullanıcı isteği
      // 2026-11-05); başlık çubuktayken tarih yok — o zaman burada.
      if (titleInBar)
        for (final tag in note.tags)
          InputChip(
            label: Text('#$tag', maxLines: 1, overflow: TextOverflow.ellipsis),
            labelStyle: chipLabelStyle,
            padding: _NoteEditorScreenState._kChipPadding,
            visualDensity: _NoteEditorScreenState._kChipDensity,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            deleteIconBoxConstraints: _NoteEditorScreenState._kChipDeleteBox,
            onDeleted: () => _removeTag(tag),
          ),
    ];

    // **Çip alanı yeniden yazıldı** (kullanıcı bulgusu 2026-08-09: "etiket ve
    // klasör kısmı güzel değil, düzenlenmeli — yazılar kesiliyor, hizalı
    // değil").
    //
    // KÖK NEDEN: çipler başlık satırının sağında 168 dp'lik bir kutuya
    // sıkıştırılmış, üstelik her çip 80 dp'ye kırpılmıştı. 80 dp'ye bir çipin
    // dolgusu + silme (×) ikonundan sonra ~34 dp yazı kalıyor; "#yapılacak"
    // ekranda "#ya…" oluyordu. `Wrap` sağa dayalı olduğu için de çipler satır
    // satır kayıyor, hiçbir kenara hizalanmıyordu.
    //
    // Şimdi çipler başlığın ALTINDA, sayfa boyunca uzanan TEK satırlık yatay
    // bir şeritte: genişlik sınırı yok (etiket adı tam okunur), hepsi aynı
    // taban çizgisine hizalı ve sığmayanlar kaydırılarak görülür.
    // **BİR SATIR KAZANILDI** (kullanıcı isteği 2026-08-09: "etiket ve klasör
    // için olan artı butonu başlık satırında olsun; etiket yoksa etiket satırı
    // oluşmasın, eklenirse oluşsun"). Eskiden çip şeridi HER NOTTA 34 dp
    // yükseklikte duruyordu — içinde tek bir "+" düğmesi olsa bile. "+" artık
    // başlığın sağında; şerit ancak gerçekten bir çip (hatırlatıcı, klasör,
    // etiket) varsa kuruluyor, boş notta hiç yer kaplamıyor.
    // Şerit kişiselleştirmede gizlenebilir (bkz. UiItem.editorTags).
    final metaChips = metaChildren.isEmpty
        ? const SizedBox.shrink()
        : Customizable(
            id: UiItem.editorTags,
            badgeInset: 8,
            // Renkli notta hapların çerçevesi, simgesi ve × işareti notun
            // koyu tonunda (yazısı [chipLabelStyle]'da) — kartla aynı ton.
            child: ChipTheme(
              data: noteAccent == null
                  ? theme.chipTheme
                  : theme.chipTheme.copyWith(
                      side: BorderSide(
                        color: noteAccent.withValues(alpha: 0.45),
                      ),
                      deleteIconColor: noteAccent,
                      iconTheme: IconThemeData(color: noteAccent, size: 14),
                    ),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _NoteEditorScreenState._kGutter,
                  ),
                  itemCount: metaChildren.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => Align(child: metaChildren[i]),
                ),
              ),
            ),
          );

    // Başlık satırı: alan + sağ kenarda "+" (ekleme/öneri menüsü). Balonlu
    // görünümde belgenin görünüm anahtarı da burada — not başlığının
    // hemen yanında, sayfa çubuğunu kalabalıklaştırmadan.
    // Bölmedeki belge: türü notun türüyle aynı OLAN ilk ek (sunum notunda
    // sunum, PDF notunda PDF — bkz. [_viewOf]).
    final bubbleDocument = note.type.isPageNoteType
        ? note.attachments
              .where(
                (a) =>
                    a.kind ==
                    (note.type == NoteType.slides
                        ? AttachmentKind.slide
                        : AttachmentKind.pdf),
              )
              .firstOrNull
        : null;
    final bubbleSwitch = bubbleDocument == null
        ? null
        : _viewSwitchFor(note, bubbleDocument, dense: true);
    final bubbleCaptionOwner = bubbleDocument == null
        ? null
        : note.attachments
              .where(
                (a) => a.id == bubbleDocument.sourceId && a.caption.isNotEmpty,
              )
              .firstOrNull;
    final titleRow = titleInBar
        // Başlık ve "+" üst çubukta; gövdede yalnız balonlu belgenin görünüm
        // anahtarı kalır (çip satırının sağında — ayrı satır harcamaz).
        ? null
        : Row(
            children: [
              Expanded(child: titleField),
              if (bubbleSwitch != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: bubbleSwitch,
                ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: actionsMenu,
              ),
            ],
          );
    _barTitle = titleInBar
        ? _HoldOffstageWidth(
            child: Row(
              children: [
                Expanded(child: titleField),
                _starBadge,
                _urgentBadge,
                actionsMenu,
              ],
            ),
          )
        : null;

    // Sayfada yüzen görseller ve videolar: "ek olarak" işaretlenenler buraya
    // girmez, alt şeritte dosya eki olarak durur (bkz. Attachment.asFile).
    // SAYFALI NOT: yalnız ETKİN sayfanın görselleri (bkz. Note.textPages —
    // ilk sayfanınki bölümsüz '').
    final imageAttachments = [
      for (final a in note.attachments)
        if (a.floatsOnPage &&
            a.id != note.backgroundImageId &&
            a.section == note.activePage &&
            !note.hidesDerivedDocument(a))
          a,
    ];

    // Görseller sayfanın üzerinde serbest katmanda yüzer ve metnin ÜSTÜne
    // çizilir. Yazılı metin görselin etrafından akar (bkz. text_wrap.dart),
    // ama ipucu metni DEKORASYONDUR — akmaz, sabit yerinde durur ve üste
    // sürüklenen görselin altında kaybolur.
    //
    // Eskiden bu, görseli bir satır aşağı ZORLAYARAK çözülüyordu (topLimit'e
    // bir satırlık pay eklenirdi); bedeli, kullanıcının görseli en üst satıra
    // hiç koyamamasıydı. Artık ters yönde çözülür: görsel serbest, ipucu
    // görselin altına iner (bkz. [NotePageCanvas.hint]).
    // İpucu satırının bandı = metnin GERÇEK satır yüksekliği.
    //
    // KÖK NEDEN: burada notun kendi yazı ölçeği (`fontScale`) yok sayılıyor
    // ve satır aralığı 1.45 diye TAHMİN ediliyordu. Alan ise satırlarını
    // stilin çıpasına kilitliyor (bkz. [wrapStrutStyle]); büyük puntolu bir
    // notta ipucu ile imleç bu yüzden ayrı satırlara düşüyordu.
    final hintLineHeight =
        MediaQuery.textScalerOf(context).scale(noteBodyStyle.fontSize ?? 16) *
        (noteBodyStyle.height ?? 1.45);
    // Tuval ipucunu yalnız gerçekten çakışma olabilecek durumda üstlenir:
    // gövde boş VE sayfada görsel var. Diğer hâllerde TextField'ın kendi
    // ipucu kullanılır (odak/animasyon davranışı bozulmasın).
    final useCanvasHint =
        note.type == NoteType.text &&
        note.body.trim().isEmpty &&
        imageAttachments.isNotEmpty;

    // Son güncelleme zamanı artık ÜST BARDA (başlık yerinde) duruyor: gövdenin
    // içinde her açılışta bir satır yer kaplıyordu ve "Düzenlendi:" öneki
    // tarihin kendisinden uzundu. Üst barda önek olmadan okunuyor.
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?titleRow,
        if (titleRow == null && bubbleSwitch != null)
          Row(
            children: [
              Expanded(child: metaChips),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 10, 2),
                child: bubbleSwitch,
              ),
            ],
          )
        else
          metaChips,
        // Takvim bağı hapı (TAKVIM F49.2): bağ yoksa yer kaplamaz.
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: NoteCalendarPills(noteId: note.id),
        ),
        // Görselden üretilmiş belgede açıklama görselindir (F40.7).
        if (bubbleCaptionOwner != null)
          Center(
            child: AttachmentCaptionBand(
              text: bubbleCaptionOwner.caption,
              onTap: _readOnly
                  ? null
                  : () => unawaited(_editCaption(bubbleCaptionOwner)),
            ),
          ),
      ],
    );
    return (
      header: header,
      imageAttachments: imageAttachments,
      hintLineHeight: hintLineHeight,
      useCanvasHint: useCanvasHint,
    );
  }

  _EditorContentResult _buildEditorContent(
    BuildContext context, {
    required AppLocalizations l10n,
    required Note note,
    required RichTextTheme richTheme,
    required TextStyle noteBodyStyle,
    required List<Attachment> imageAttachments,
    required double hintLineHeight,
    required bool useCanvasHint,
    required Widget header,
  }) {
    // DEFTERİN SAYFA ÇUBUĞU ALT PANELİN HEMEN ÜSTÜNDE, SABİT (kullanıcı
    // isteği 2026-11-22: "en altta derken alt panelin üzerinde sabit olacak,
    // şu an sayfayı kaydırmak gerekiyor"): başlığın altında maddeleri aşağı
    // itiyordu, içeriğin sonuna konunca da kaydırmadan görünmüyordu. Alt
    // çubukla aynı sütunda — yazarken / biçim paneli açıkken onunla gizlenir.
    final pageBarDock =
        (note.textPages.isNotEmpty || note.paged) && !note.type.isPageNoteType
        ? KeyedSubtree(
            key: const ValueKey('page-bar-dock'),
            child: _pageBar(note),
          )
        : null;

    // Gövde metin alanı: saf metin modunda ve karışık (metin+madde) modda
    // aynı controller/focus'u paylaşır. Madde varken kısalır (2 satır tabanı).
    // `Builder`: dokunuşta alanın KENDİ EditableText'i bulunur (başlığınki
    // değil); sarmalayıcı dokunuşun konumunu tutar (bkz. [_tappedEmbed]).
    // Notun yazı ölçeği değişince gövde eski boyundan yenisine yumuşakça
    // oturur (yalnız boyama; yüzen görsel varken kapalı — sarma ölçümü
    // dönüşümden etkilenmesin).
    final bodyField = ScaleSettle(
      value: note.fontScale,
      enabled: _floats.isEmpty,
      child: Builder(
        builder: (fieldContext) {
          void onBodyTap() {
            final editable = editableTextBelow(fieldContext);
            // PDF REFERANSI (📖 s.12): belge o sayfaya döner.
            final pdfRef = _tappedPdfRef(editable);
            if (pdfRef != null) {
              editable?.hideToolbar();
              _goToPdfPage(pdfRef.page);
              return;
            }
            final seconds = _tappedTimestamp(editable);
            if (seconds != null) {
              editable?.hideToolbar();
              _seekVideoTo(seconds);
              return;
            }
            // WEB BAĞLANTISI gömülü yazı (2026-11-24): okurken açar; yazarken
            // imleç konur, açmak uzun basma menüsünden ("Bağlantıyı aç").
            final web = _tappedUrlLink(editable);
            if (web != null) {
              if (!_bodyTapPoint.wasFocused) {
                editable?.hideToolbar();
                unawaited(openLink(web));
              }
              return;
            }
            // NOT BAĞLANTISI (F18.16): okurken açar, yazarken önerir.
            final linked = _tappedNoteLink(editable);
            if (linked != null) {
              editable?.hideToolbar();
              _openLinkedNote(linked, editing: _bodyTapPoint.wasFocused);
              return;
            }
            final tapped = _tappedEmbed(editable);
            if (tapped != null) {
              // Dokunuşun açtığı Yapıştır menüsü önizlemenin altında kalmasın.
              editable?.hideToolbar();
              _showEmbedPreviewFor(tapped.attachment, tapped.label);
              return;
            }
            // BAĞLANTIYA DOKUNUŞ (2026-10-28): okurken açar, yazarken önerir.
            final link = tappedLink(
              displayText: _bodyField.text,
              editable: editable,
              tapGlobal: _bodyTapPoint.last,
            );
            if (link != null) {
              editable?.hideToolbar();
              handleLinkTap(
                context,
                link,
                editing: _bodyTapPoint.wasFocused,
                onEmbedVideo: _readOnly || note.type.isPageNoteType
                    ? null
                    : _embedLinkedVideo,
              );
              return;
            }
            // Altı çizili kelimeye dokunuş: öneri menüsü (Y-4).
            showSpellMenuAfterTap(editable);
          }

          Widget fieldOf(bool top, bool bottom) => AttachmentTagChips(
            key: _bodyFieldKey,
            controller: _bodyField,
            looks: _tagLooks,
            child: _bodyTapPoint.wrap(
              // KLAVYENİN OTOMATİK DÜZELTMESİ uygulamanın kipine bağlı (kullanıcı
              // 2026-11-25: "otomatik düzelt kapalı ama otomatik düzeliyor"):
              // `autocorrect` varsayılanı true, klavye (Gboard) kendi düzeltmesini
              // yapıyordu. Kip seyrek değişir; dinleyici ağaçta hep var (şekil sabit).
              ValueListenableBuilder<bool>(
                valueListenable: AutoSpell.enabled,
                builder: (_, autoFix, _) => TextField(
                  controller: _bodyField,
                  focusNode: _bodyFocus,
                  readOnly: _readOnly,
                  autocorrect: autoFix,
                  // Sarma planı bu stille hesaplanır; TextField'ın örtük varsayılanına
                  // bırakılırsa ölçüm ile çizim ayrışır ve satırlar yanlış kırılır.
                  style: noteBodyStyle,
                  // SATIR YÜKSEKLİĞİ ÇIPASI AÇIKÇA VERİLİR: alan zaten `forceStrutHeight`
                  // ile çiziyor, sarma ölçümü de aynı çıpayı kullanıyor (bkz.
                  // [wrapStrutStyle]). Açıkça vermek eşleşmeyi `EditableText`in
                  // varsayılanına bırakmaz — kaymanın kök nedeni buydu.
                  strutStyle: wrapStrutStyle(noteBodyStyle),
                  onChanged: (value) {
                    final before = _note?.body ?? '';
                    final after = _bodyController.logicalText;
                    _mutate((n) => n.copyWith(body: after));
                    // Yapıştırılan YouTube bağlantısı videoyu gömer.
                    _maybeEmbedPastedVideo(before, after);
                    // `[[` yazınca not seçici (F18.16): iki parantez silinir, seçilen
                    // notun başlığı bağlantı olarak imlece yazılır.
                    _maybeLinkTrigger(before, after);
                    if (_windowAllowed(note)) _bodyWindow.enter();
                  },
                  maxLines: null,
                  minLines: _bodyWindow.active
                      ? 1
                      : note.items.isEmpty
                      ? 8
                      : 2,
                  keyboardType: TextInputType.multiline,
                  // EK ETİKETİNE DOKUNUNCA ÖNİZLEME (kullanıcı isteği 2026-08-16).
                  //
                  // Span'in kendisine `TapGestureRecognizer` bağlanamıyor: düzenlenebilir
                  // bir alanda dokunuş imleci taşımak için EditableText'e gidiyor ve
                  // span tanıyıcıları hiç ateşlenmiyor. `onTap` ise dokunuş imleci
                  // TAŞIDIKTAN SONRA çalışır — imlecin nereye düştüğüne bakmak, "etikete
                  // dokunuldu mu" sorusunun bu alandaki tek doğru cevabı.
                  // YENİ (gömme yeniden tasarımı): tam ekran yerine YERİNDE önizleme
                  // kartı; yalnız dokunuş etiketin İÇİNE düşünce (yanına imleç koymak
                  // yazmaya devam etmektir, önizleme açmaz).
                  onTap: onBodyTap,
                  // Bağlantıya uzun basınca seçim menüsüne "Bağlantıyı aç" eklenir.
                  // Düzenlenebilir bir alanda span'e tıklama Flutter'da çalışmaz (dokunuş
                  // imleci taşımak için EditableText'e gider), bu yüzden yol seçim menüsü.
                  contextMenuBuilder: _bodyContextMenu,
                  contentInsertionConfiguration: _keyboardImagePaste,
                  decoration: InputDecoration(
                    // Görsel ipucunun üstüne gelebiliyorsa ipucu tuvale devredilir.
                    hintText: useCanvasHint ? null : l10n.bodyHint,
                    filled: false,
                    border: InputBorder.none,
                    visualDensity: VisualDensity.standard,
                    // İÇ DOLGU AÇIKÇA: ilk metin satırının alanın tepesinden ne kadar
                    // aşağıda başladığı hem sarma ölçümüne ([_wrapped]) hem de tuval
                    // ipucuna ([NotePageCanvas.textTop]) veriliyor. Flutter'ın örtük
                    // varsayılanına bırakılırsa üç yer sessizce ayrışır.
                    contentPadding: EdgeInsets.only(
                      top: top ? _NoteEditorScreenState._kBodyTextTop : 0,
                      bottom: bottom ? _NoteEditorScreenState._kBodyTextTop : 0,
                    ),
                  ),
                ),
              ),
              // Damgaya/etikete dokunmak klavyeyi AÇMAZ (bkz. TapPointTracker.wrap).
              focusNode: _bodyFocus,
              keepsKeyboardClosed: (global) => linkAtPoint(
                editable: editableTextBelow(fieldContext),
                displayText: _bodyField.text,
                global: global,
                timestamps:
                    _note != null && _NoteEditorScreenState._hasVideo(_note!),
                pdfRefs: _note != null && _pdfForRefs(_note!) != null,
                tagNames: _bodyController.attachmentNames,
              ),
            ),
          );

          // Uzun notta yazarken (F24.2): alan aynı State'le ([_bodyFieldKey])
          // pencere parçalarının arasına taşınır, klavye kapanmaz.
          if (_bodyWindow.active &&
              !_windowAllowed(note) &&
              !noteRouteClosing.value) {
            _bodyWindow.exit(notify: false);
          }
          if (!_bodyWindow.active) return fieldOf(true, true);
          return WindowedBodyField(
            window: _bodyWindow,
            style: windowedFieldStyle(context, noteBodyStyle),
            strut: wrapStrutStyle(noteBodyStyle),
            linkColor: _themeOf(context).colorScheme.primary,
            topPadding: _NoteEditorScreenState._kBodyTextTop,
            field: fieldOf,
            onTileTap: (offset, global) {
              _bodyWindow.moveCaretTo(offset);
              _bodyTapPoint
                ..last = global
                ..wasFocused = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) onBodyTap();
              });
            },
            onTileLongPress: (offset, global) {
              _bodyWindow.moveCaretTo(offset);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  selectWordAt(editableTextBelow(fieldContext), global);
                }
              });
            },
          );
        },
      ),
    );

    // Başlık + çipler: yüksekliği görsellerin üst sınırıdır.
    final keyedHeader = KeyedSubtree(key: _bodyTopKey, child: header);

    // Sayfa içeriği not tipine göre değişir; SARAN KATMAN hepsinde aynıdır:
    // görseller (el yazısı çizimleri dahil) tüm sayfanın üzerinde serbest
    // katmanda yüzer, metnin sağına/soluna sürüklenir ve metin etrafından akar.
    final Widget pageContent;
    if (note.type.isPageNoteType) {
      // Belge notunda sayfa tuvali (yüzen görseller + metin sarma) YOK: gövde
      // iki sabit bölmeye ayrılır, bu yüzden `body` aşağıda ayrı kurulur ve
      // buradaki tuval içeriği kullanılmaz.
      pageContent = const SizedBox.shrink();
    } else if (note.type == NoteType.text && note.items.isEmpty) {
      pageContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          keyedHeader,
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _NoteEditorScreenState._kGutter,
            ),
            child: _wrapped(_bodyController, bodyField),
          ),
        ],
      );
    } else if (note.type == NoteType.text) {
      // Karışık içerik: serbest metin + checklist maddeleri. Gövde metni, madde
      // editörünün (ItemsEditor) header'ında durur; tüm ekle/işaretle/sırala/
      // sil mantığı olduğu gibi yeniden kullanılır. Madde kalmayınca (hepsi
      // silinince) note.items boşalır ve editör kendiliğinden saf metne döner.
      pageContent = ItemsEditor(
        key: _itemsEditorKey,
        items: note.items,
        showCheckboxes: true,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) =>
            _mutate((n) => n.copyWith(items: items), itemsShown: true),
        floatsListenable: _floatsN,
        pageBox: _pageBox,
        shrinkWrap: true,
        contentInsertion: _keyboardImagePaste,
        richTheme: richTheme,
        textStyle: noteBodyStyle,
        onFieldFocused: _setFormatTarget,
        onFieldDisposed: _clearFormatTargetFor,
        // Madde satırlarındaki ek etiketleri de gövdedekiyle aynı çizilsin
        // ve dokunulunca açılsın (bkz. ItemsEditor.attachmentNames).
        attachmentNames: _bodyController.attachmentNames,
        tagLooks: _tagLooks,
        onAttachmentTag: _openTagByName,
        selectionMenu: _itemSelectionMenu,
        videoTimestamps: _bodyController.videoTimestamps,
        onVideoTimestamp: _seekVideoTo,
        onEmbedVideo: _readOnly ? null : _embedLinkedVideo,
        addRowTrailing: _partsMenu(note),
        paperLines: note.paged && note.archivePaper.ruled,
        onMoveToPage: textPagePosition(note).count > 1 ? _moveItemToPage : null,
        onMakeTask: _readOnly ? null : (item) => _makeTask(note, item),
        onLineReminder: _readOnly
            ? null
            : (item) => unawaited(
                addLineReminder(
                  context,
                  ref,
                  noteId: note.id,
                  itemId: item.id,
                  text: item.text,
                ),
              ),
        lineTrailing: (item) => LineTaskChip(noteId: note.id, itemId: item.id),
        onItemChecked: (item, checked) =>
            syncItemToTasks(ref, note.id, item.id, checked),
        // Paylaşım biçimi (☐/☑) — `- [ ]` değil (bkz. noteShareText).
        wholeNoteText: () => _note == null
            ? ''
            : noteShareText(_note!, pageLabel: context.l10n.pageLabel),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            keyedHeader,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _NoteEditorScreenState._kGutter,
              ),
              child: _wrapped(_bodyController, bodyField),
            ),
          ],
        ),
      );
    } else {
      pageContent = ItemsEditor(
        key: _itemsEditorKey,
        items: note.items,
        showCheckboxes: note.type == NoteType.checklist,
        // İki sütun YALNIZ gerçek liste notunda (kullanıcı isteği
        // 2026-08-16). Metin notuna iliştirilmiş maddeler gövdenin altında
        // birkaç satır tutuyor; onları ikiye bölmek yalnız karıştırırdı.
        columns: note.listColumns,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) =>
            _mutate((n) => n.copyWith(items: items), itemsShown: true),
        floatsListenable: _floatsN,
        pageBox: _pageBox,
        shrinkWrap: true,
        contentInsertion: _keyboardImagePaste,
        richTheme: richTheme,
        textStyle: noteBodyStyle,
        onFieldFocused: _setFormatTarget,
        onFieldDisposed: _clearFormatTargetFor,
        // Madde satırlarındaki ek etiketleri de gövdedekiyle aynı çizilsin
        // ve dokunulunca açılsın (bkz. ItemsEditor.attachmentNames).
        attachmentNames: _bodyController.attachmentNames,
        tagLooks: _tagLooks,
        onAttachmentTag: _openTagByName,
        selectionMenu: _itemSelectionMenu,
        videoTimestamps: _bodyController.videoTimestamps,
        onVideoTimestamp: _seekVideoTo,
        onEmbedVideo: _readOnly ? null : _embedLinkedVideo,
        addRowTrailing: _partsMenu(note),
        paperLines: note.paged && note.archivePaper.ruled,
        onMoveToPage: textPagePosition(note).count > 1 ? _moveItemToPage : null,
        onMakeTask: _readOnly ? null : (item) => _makeTask(note, item),
        onLineReminder: _readOnly
            ? null
            : (item) => unawaited(
                addLineReminder(
                  context,
                  ref,
                  noteId: note.id,
                  itemId: item.id,
                  text: item.text,
                ),
              ),
        lineTrailing: (item) => LineTaskChip(noteId: note.id, itemId: item.id),
        onItemChecked: (item, checked) =>
            syncItemToTasks(ref, note.id, item.id, checked),
        // Paylaşım biçimi (☐/☑) — `- [ ]` değil (bkz. noteShareText).
        wholeNoteText: () => _note == null
            ? ''
            : noteShareText(_note!, pageLabel: context.l10n.pageLabel),
        header: () {
          final explicitKind = smartListKindFromId(note.listKind);
          final resolvedKind = explicitKind != SmartListKind.generic
              ? explicitKind
              : (smartKindFromPhrase(note.title) ?? SmartListKind.generic);
          final showStoreModePill =
              note.type == NoteType.checklist &&
              !_readOnly &&
              resolvedKind == SmartListKind.shopping;
          final showSmartWorkspacePill =
              note.type == NoteType.checklist &&
              !_readOnly &&
              resolvedKind != SmartListKind.generic &&
              resolvedKind != SmartListKind.shopping;
          final showBody = note.body.trim().isNotEmpty || _listBodyOpen;
          if (!showStoreModePill && !showSmartWorkspacePill && !showBody) {
            return keyedHeader;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              keyedHeader,
              if (showStoreModePill)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _NoteEditorScreenState._kGutter,
                    0,
                    _NoteEditorScreenState._kGutter,
                    AppSpace.s,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('editor-open-store-mode'),
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: AppIconSize.s,
                      ),
                      label: Text(() {
                        final rem = note.items
                            .where(
                              (i) =>
                                  !i.header &&
                                  !i.checked &&
                                  i.text.trim().isNotEmpty,
                            )
                            .length;
                        return rem > 0
                            ? context.l10n.shopOpenStoreModeCount(rem)
                            : context.l10n.shopOpenStoreMode;
                      }()),
                      onPressed: _openStoreMode,
                    ),
                  ),
                ),
              if (showSmartWorkspacePill)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _NoteEditorScreenState._kGutter,
                    0,
                    _NoteEditorScreenState._kGutter,
                    AppSpace.s,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('editor-open-smart-workspace'),
                      icon: Icon(
                        smartWorkspaceIcon(resolvedKind),
                        size: AppIconSize.s,
                      ),
                      label: Text(
                        smartWorkspacePillLabel(
                          note,
                          resolvedKind,
                          context.l10n,
                        ),
                      ),
                      onPressed: () =>
                          unawaited(_openSmartWorkspace(resolvedKind)),
                    ),
                  ),
                ),
              if (showBody)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _NoteEditorScreenState._kGutter,
                  ),
                  child: _wrapped(_bodyController, bodyField),
                ),
            ],
          );
        }(),
      );
    }

    _scheduleBodyTopMeasure();
    final hasBodyField =
        note.type == NoteType.text ||
        note.body.trim().isNotEmpty ||
        _listBodyOpen;
    // Gövde BOŞKEN "Not..." ipucu satırı görsellere kapalı bant sayılır.
    //
    // KLAVYE KARELERİNDE AĞACI YENİDEN KURMA (kullanıcı bulgusu 2026-08-10:
    // "klavye açılırken kasma sorunu var, geçmişte de vardı hâlâ tam
    // düzelmedi"): alt çubuk klavye yüksekliği kadar büyüyor, dolayısıyla
    // Scaffold gövdesinin KISITI animasyonun her karesinde değişiyor ve
    // `LayoutBuilder` her karede yeniden koşuyordu. Kurulan ağaç
    // (`SingleChildScrollView` + `NotePageCanvas` + her görselin kutusu)
    // karede bir baştan yaratılıyordu — oysa tuvalin tek ihtiyacı olan taban
    // yükseklik [_stableCanvasHeight] sayesinde ZATEN sabit.
    //
    // Çözüm: aynı taban için AYNI widget örneği döndürülür. Flutter
    // `updateChild`te birebir aynı örneği görünce alt ağacı hiç kurmaz, yani
    // klavye animasyonu boyunca yeniden kurulan tek şey `Padding` kalır.
    // Önbellek her editör build'inde sıfırlanır (bkz. build başındaki
    // `_canvasCache = null`) — yani not değişimi ya da yeni görsel bir kare
    // bile gecikmeden görünür.
    final pageBody = note.type.isPageNoteType
        ? _pageNoteBody(note, keyedHeader, richTheme, noteBodyStyle)
        : LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = _stableCanvasHeight(constraints);
              final cached = _canvasCache;
              if (cached != null && _canvasCacheHeight == minHeight) {
                return cached;
              }
              final built = _buildCanvas(
                minHeight: minHeight,
                imageAttachments: imageAttachments,
                hintLineHeight: hintLineHeight,
                hintStyle: noteBodyStyle,
                useCanvasHint: useCanvasHint,
                hasBodyField: hasBodyField,
                pageContent: pageContent,
                l10n: l10n,
                note: note,
                bodyStyle: noteBodyStyle,
              );
              _canvasCache = built;
              _canvasCacheHeight = minHeight;
              return built;
            },
          );
    // Oynatıcılar (sabit bölme, sayfadaki video kutuları) notun video
    // merkezine buradan ulaşır (bkz. VideoHubScope).
    final body = VideoHubScope(
      hub: _videoHub,
      child: _withPinnedMedia(note, pageBody),
    );

    // ALT ÇUBUK — Scaffold'ın `bottomNavigationBar` YUVASINDA DEĞİL,
    // gövdenin dibinde bir `Column` çocuğu.
    //
    // KÖK NEDEN (kullanıcı 2026-08-16: "kasma sorunu tam çözülmemiş"):
    // yuvadayken çubuğun yüksekliği klavye kadar BÜYÜYORDU. Scaffold'ın
    // gövde alanı `bottom - max(viewInsets, altÇubukYüksekliği)` ile
    // hesaplandığı için çubuğun her karede değişen boyu Scaffold'ı ve
    // gövdeyi her karede yeniden YERLEŞTİRİYORDU. `Column`da ise esnek
    // OLMAYAN çocuk klavyeden bağımsız bir kısıtla ölçülür.
    //
    // ÇUBUK BURADA, `KeyboardSnap`in DIŞINDA kuruluyor (2026-08-22):
    // klavye boşluğu değişince `KeyboardSnap` gövde ağacını yeniden kurar;
    // çubuk o kapanışın içinde olsaydı — ek şeridi, biçim çubuğu,
    // BottomAppBar, AI ve mikrofon düğmeleriyle birlikte — her açılış ve
    // kapanışta baştan kurulurdu. Dışarıda kurulunca AYNI ÖRNEK olarak
    // geçirilir ve Flutter alt ağacı hiç ellemez.
    //
    // Balona yazılırken çubuk TÜMÜYLE gizlenir: klavye + belge bölmesi + iki
    // çubuk aynı ekrana sığmıyor ve balon kartı altta kalıyordu (kullanıcı
    // isteği 2026-08-08). Kip bitince geri gelir.
    //
    // RepaintBoundary: çubuk klavye animasyonu boyunca yer değiştiriyor;
    // ayrı katmanda olmazsa her karede GÖVDEYİ de yeniden boyatır.
    // KALEM ÇEKMECESİ (kullanıcı isteği 2026-11-02): telefonda da tablette
    // de kalemler ALTTA, sayfanın üstünde yüzen bir çekmecede (bkz.
    // PenTray.dock). Sayfa yerleşimi kalem kipinde değişmez; çubuk yer
    // kaplamaz.
    // Sayfa ortada okuma sütununda mı (bkz. [_buildCanvas]): sabit medya ve
    // belge notunda sayfa bölmeyi doldurur, çubuklar da.
    final readingColumn = !note.type.isPageNoteType && !_titleInBar(note);
    // KISA PENCERE (F66.7/F67.4: yatay telefon, < 480 dp): üst çubuk 40 dp.
    // `sizeOf` klavyeyle değişmez — klavye kareleri kök kurulumu görmez.
    final toolbarHeight = WindowClass.of(context).height == WindowHeight.short
        ? 40.0
        : _NoteEditorScreenState._kEditorToolbarHeight;
    return (
      body: body,
      pageBarDock: pageBarDock,
      readingColumn: readingColumn,
      toolbarHeight: toolbarHeight,
    );
  }
}
