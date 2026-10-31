part of 'dashboard_screen.dart';

/// Ana ekranın ⋮ menüsü (C1).
extension _DashMenu on _DashboardScreenState {
  /// Gelecekteki hatırlatıcı sayısı (⋮ menüsündeki rozet).
  int _upcomingReminderCount() {
    final now = DateTime.now();
    return [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if (n.reminderAt != null &&
            n.reminderAt!.isAfter(now) &&
            n.archivedAt == null)
          n,
    ].length;
  }

  /// ⋮ menüsünün satırı. [count] > 0 ise sağda küçük sayı rozeti
  /// (kullanıcı isteği 2026-09-26: menü "görsel ve işlevsel olarak
  /// geliştirilsin" — Gelen notlar/Hatırlatıcılar/Arşiv'de ne beklediği
  /// açmadan görünsün). [highlight]: bekleyen iş (gelen not) vurgulu rozet.
  /// Ana ekranın ⋮ levhası: hızlı satırda en sık gidilen dört yer (sayılı),
  /// altında kişiler, ana ekran ve uygulama grupları. Sayılar levha
  /// AÇILIRKEN okunur (ref.read) — ekran bu sayılar için yeniden kurulmaz.
  Future<void> _openHomeMenu({
    required bool hasHiddenFolders,
    required bool hiddenRevealed,
  }) async {
    final l10n = context.l10n;
    // GENİŞ EKRAN (F11.8): rayda duran kapılar ⋮'te tekrarlanmaz.
    final rail = AppRailScope.visible(context);
    final action = await showActionMenuSheet(
      context,
      ActionMenu(
        // Gruplar iki sütunlu geniş satır: ikişer maddelik gruplar üç
        // sütunlu ızgarada sola yaslanıyordu (kullanıcı bulgusu 2026-10-20).
        wideSections: true,
        quick: [
          // Rayın yanında (geniş ekran) bu beşi rayda: tekrarlanmaz.
          if (!rail) ...[
            // YAPAY ZEKÂ ilk sırada (B2): ana ekrandaki ✨ yüzen düğmesi
            // kalktı.
            if (Personalize.current.shows(UiItem.homeAi))
              MenuAction('ai', l10n.aiHubTitle, Icons.auto_awesome),
            MenuAction(
              'reminders',
              l10n.remindersTitle,
              Icons.alarm_outlined,
              count: _upcomingReminderCount(),
            ),
            MenuAction(
              'archive',
              l10n.archiveTitle,
              Icons.archive_outlined,
              count: ref.read(archivedNotesProvider).value?.length ?? 0,
            ),
            MenuAction('trash', l10n.trashTitle, Icons.delete_outline),
            // AYARLAR hızlı satırda, GRİ (kullanıcı isteği 2026-10-17:
            // "ayarlar butonunu üstteki 3'lü buton gibi yap ve oraya al,
            // rengini de ayrıştır gri olsun").
            MenuAction(
              'settings',
              l10n.settings,
              Icons.settings_outlined,
              neutral: true,
            ),
          ],
          // Şablondan not "+" menüsünde de var; burada YALNIZ orada
          // gizlenmişse çıkar (toparlama 2026-10-17: aynı işin iki kapısı).
          if (!Personalize.current.shows(UiItem.quickAdd('template')))
            MenuAction(
              'template',
              l10n.fromTemplate,
              Icons.dashboard_customize_outlined,
            ),
        ],
        sections: [
          // HESAP VE KİŞİLER avatar levhasında (F11.1–F11.2): ⋮'te yalnız
          // avatar kişiselleştirmede gizlendiyse kapı olarak kalır.
          // KLASÖR SIRASI klasör ekranında ("Tüm klasörler", F11.5).
          MenuSection(l10n.menuSectionHome, [
            if (!Personalize.current.shows(UiItem.homeAccount))
              MenuAction(
                'account',
                l10n.account,
                Icons.account_circle_outlined,
              ),
            // Zemin görseli AYARLARDAN BURAYA taşındı (2026-08-16).
            MenuAction('background', l10n.dashboardBackground, Icons.wallpaper),
            // Gizli klasörler yalnız gizli klasörü OLAN kullanıcıda.
            if (hasHiddenFolders)
              MenuAction(
                'hidden',
                l10n.hiddenFoldersMenu,
                hiddenRevealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
          ]),
          MenuSection(l10n.menuSectionApp, [
            // KİŞİSELLEŞTİR (kullanıcı isteği 2026-10-16): hangi alan ve
            // düğme görünsün — menüden; ekranda kalıcı ayar düğmesi yok.
            MenuAction(
              'personalize',
              l10n.personalizeTitle,
              Icons.tune_rounded,
            ),
            MenuAction('guide', l10n.guideTitle, Icons.menu_book_outlined),
          ]),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'ai':
        unawaited(context.push('/ai'));
      case 'account':
        unawaited(showAccountSheet(context));
      case 'hidden':
        unawaited(_toggleHiddenFolders());
      case 'reminders':
        unawaited(context.push('/reminders'));
      case 'archive':
        unawaited(context.push('/archive'));
      case 'background':
        unawaited(showDashboardBackgroundSheet(context));
      case 'trash':
        unawaited(context.push('/trash'));
      case 'template':
        unawaited(createFromTemplate());
      case 'settings':
        unawaited(context.push('/settings'));
      case 'personalize':
        unawaited(context.push('/personalize'));
      case 'guide':
        unawaited(context.push('/guide'));
    }
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    int count = 0,
    bool highlight = false,
  }) => PopupMenuItem<String>(
    value: value,
    height: 42,
    // ListTile satırı daima erişilebilir tüm genişliği kaplıyordu; menü de
    // bu yüzden sağ-sol ekseninde gereksiz genişliyordu (madde 5). İçeriğe
    // göre daralan Row ile menü yalnız ikon + etiket kadar yer kaplar.
    child: Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: highlight
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
