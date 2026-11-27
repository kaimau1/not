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
        menuId: 'home.menu',
        quick: [
          // Rayın yanında (geniş ekran) bu dördü rayda: tekrarlanmaz.
          if (!rail) ...[
            MenuAction(
              'calendar',
              l10n.calendarTitle,
              Icons.calendar_month_outlined,
              count: _upcomingReminderCount(),
            ),
            MenuAction(
              'archive',
              l10n.archiveTitle,
              AppIcons.archive,
              count: ref.read(archivedNotesProvider).value?.length ?? 0,
            ),
            MenuAction('trash', l10n.trashTitle, Icons.delete_outline),
            // AYARLAR hızlı satırda, GRİ.
            MenuAction(
              'settings',
              l10n.settings,
              Icons.settings_outlined,
              neutral: true,
            ),
          ],
          // Şablondan not "+" menüsünde de var; burada YALNIZ orada
          // gizlenmişse çıkar.
          if (!Personalize.current.shows(UiItem.quickAdd('template')))
            MenuAction(
              'template',
              l10n.fromTemplate,
              Icons.dashboard_customize_outlined,
            ),
        ],
        sections: [
          MenuSection(l10n.menuSectionApp, [
            MenuAction('view', l10n.homeViewMenu, Icons.view_quilt_outlined),
            MenuAction(
              'appearance',
              l10n.settingsAppearance,
              AppIcons.appearance,
            ),
            if (!Personalize.current.shows(UiItem.homeAccount))
              MenuAction(
                'account',
                l10n.account,
                Icons.account_circle_outlined,
              ),
            if (hasHiddenFolders)
              MenuAction(
                'hidden',
                l10n.hiddenFoldersMenu,
                hiddenRevealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            MenuAction(
              'personalize',
              l10n.personalizeTitle,
              Icons.tune_rounded,
            ),
            MenuAction('guide', l10n.guideTitle, AppIcons.guide),
          ]),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'view':
        unawaited(showFilterSheet(context));
      case 'appearance':
        unawaited(showAppearanceStudio(context));
      case 'theme':
        unawaited(showThemePickerSheet(context));
      case 'account':
        unawaited(showAccountSheet(context));
      case 'hidden':
        unawaited(_toggleHiddenFolders());
      case 'calendar':
        unawaited(context.push('/calendar'));
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

  /// Çoklu seçimin ⋮ menüsü: çok işlemli, levha (F38.6).
  Future<void> _openSelectionMenu(Set<String> selectedIds) async {
    final l10n = context.l10n;
    final action = await showActionMenuSheet(
      context,
      ActionMenu(
        menuId: 'home.selection',
        quick: [
          MenuAction('folder', l10n.moveToFolder, AppIcons.moveToFolder),
          MenuAction('share', l10n.share, Icons.share_outlined),
          MenuAction('duplicate', l10n.duplicateNote, AppIcons.duplicate),
        ],
        sections: [
          MenuSection(l10n.menuSectionOrganize, [
            MenuAction('pin', l10n.pin, Icons.push_pin_outlined),
            MenuAction('unpin', l10n.unpin, Icons.push_pin),
            MenuAction('star', l10n.star, Icons.star_outline),
            MenuAction('unstar', l10n.unstar, Icons.star),
            MenuAction('color', l10n.backgroundColor, AppIcons.color),
            MenuAction('frame', l10n.frameColor, Icons.border_color_outlined),
          ]),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'pin':
        _setPinnedSelected(selectedIds, true);
      case 'unpin':
        _setPinnedSelected(selectedIds, false);
      case 'star':
        _setStarredSelected(selectedIds, true);
      case 'unstar':
        _setStarredSelected(selectedIds, false);
      case 'share':
        await _shareSelected(selectedIds);
      case 'folder':
        await _moveSelectedToFolder(selectedIds);
      case 'duplicate':
        await _duplicateSelected(selectedIds);
      case 'color':
        await _colorSelected(selectedIds, frame: false);
      case 'frame':
        await _colorSelected(selectedIds, frame: true);
    }
  }
}
