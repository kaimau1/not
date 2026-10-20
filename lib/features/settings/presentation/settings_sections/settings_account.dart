part of '../settings_screen.dart';

/// "Kişiler" alanının tek satırı: arkadaş listesine/isteklere götürür.
/// Yerel (anonim) hesapta e-posta olmadığı için özellik anlamsız —
/// `openFriendsScreenOrExplain` dokununca bunu açıklar.
class _FriendsRow extends ConsumerWidget {
  const _FriendsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requestCount =
        ref.watch(incomingFriendRequestsProvider).value?.length ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.people_outline),
      title: Text(l10n.friendsTitle),
      subtitle: Text(l10n.friendsRowInfo),
      trailing: requestCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$requestCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => openFriendsScreenOrExplain(context, ref),
    );
  }
}

/// "Gelen notlar" satırı — bir arkadaşın GÖNDERDİĞİ, henüz kabul edilmemiş
/// notlar (kullanıcı isteği 2026-08-18: "paylaşılan not alıcıda farklı gelen
/// notlar klasöründe görülsün").
class _InboxRow extends ConsumerWidget {
  const _InboxRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(inboxNotesProvider).value?.length ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.move_to_inbox_outlined),
      title: Text(l10n.inboxTitle),
      subtitle: Text(l10n.inboxEmptyHint),
      trailing: count > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => InboxScreen.open(context),
    );
  }
}

/// Ayarların en üstündeki kimlik kartı: avatar, ad, e-posta ve senkron durumu.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).value;
    // Yerel (anonim) hesabın adı da e-postası da yok; kart adsız kalmasın —
    // kullanıcı hangi hesap türünde olduğunu buradan görür.
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.trim().isNotEmpty ?? false)
        ? user!.email!
        : (ref.watch(isAnonymousProvider) ? l10n.localAccountBadge : '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person_outline)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if ((user?.email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.email!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                // Anonim hesapta "Senkronize edildi" YANILTICIYDI: veri başka
                // cihazdan açılamaz ve hesap kaybolursa geri gelmez. Rozet
                // gerçeği söyler; ayrıntısı alttaki yerel hesap kartında.
                Row(
                  children: [
                    Icon(
                      ref.watch(isAnonymousProvider)
                          ? Icons.smartphone
                          : Icons.cloud_done_outlined,
                      size: 14,
                      color: ref.watch(isAnonymousProvider)
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      ref.watch(isAnonymousProvider)
                          ? l10n.localAccountBadge
                          : l10n.synced,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uygulamanın düzgün çalışması için gereken izinleri gösterir ve ister.
/// Sistem ayarından dönüldüğünde (resume) durum kendiliğinden tazelenir.
class _PermissionsSection extends ConsumerStatefulWidget {
  const _PermissionsSection();

  @override
  ConsumerState<_PermissionsSection> createState() =>
      _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<_PermissionsSection>
    with WidgetsBindingObserver {
  bool? _mic;
  bool? _camera;
  bool? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı sistem izin ekranından dönünce yeni durumu göster.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final service = ref.read(permissionsServiceProvider);
    final mic = await service.micGranted();
    final camera = await service.cameraGranted();
    final notifications = await service.notificationsGranted();
    if (mounted) {
      setState(() {
        _mic = mic;
        _camera = camera;
        _notifications = notifications;
      });
    }
  }

  Future<void> _requestCamera() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestCamera();
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  Future<void> _requestMic() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestMic();
    // İstek dönüşü false ise izin kalıcı reddedilmiş olabilir; kullanıcının
    // elle açabilmesi için sistem ayarına yönlendir.
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  Future<void> _requestNotifications() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestNotifications();
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = ref.read(permissionsServiceProvider);
    return Column(
      children: [
        _PermissionTile(
          icon: Icons.mic_none,
          title: l10n.permMic,
          subtitle: l10n.permMicInfo,
          granted: _mic,
          onAction: _requestMic,
        ),
        _PermissionTile(
          icon: Icons.videocam_outlined,
          title: l10n.permCamera,
          subtitle: l10n.permCameraInfo,
          granted: _camera,
          onAction: _requestCamera,
        ),
        _PermissionTile(
          icon: Icons.notifications_none,
          title: l10n.permNotifications,
          subtitle: l10n.permNotificationsInfo,
          granted: _notifications,
          onAction: _requestNotifications,
        ),
        // Pil muafiyeti durumu güvenilir okunamadığından her zaman "Ayarları
        // aç" gösterir; kullanıcı uygulamayı pil kısıtlamasından muaf tutar.
        _PermissionTile(
          icon: Icons.battery_saver_outlined,
          title: l10n.permBattery,
          subtitle: l10n.permBatteryInfo,
          granted: null,
          actionLabel: l10n.permOpenSettings,
          onAction: service.openBatterySettings,
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onAction,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// true = verildi, false = reddedildi, null = durum okunamıyor (muafiyet).
  final bool? granted;
  final Future<void> Function() onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isGranted = granted == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.permGranted,
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
              ],
            )
          else
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel ?? context.l10n.permGrant),
            ),
        ],
      ),
    );
  }
}

/// Tüm notları (arşiv dahil, çöp hariç) tek JSON dosyası olarak dışa
/// aktarıp paylaşım sayfasını açar. Ek dosyaları bulutta kaldığından
/// yalnızca adları ve bağlantıları yazılır.
class _BackupButton extends ConsumerWidget {
  const _BackupButton();

  Map<String, dynamic> _exportNote(Note n) => {
    'id': n.id,
    'type': n.type.id,
    'title': n.title,
    'body': n.body,
    'items': [
      for (final i in n.items) {'text': i.text, 'checked': i.checked},
    ],
    'tags': n.tags,
    'color': n.color.id,
    'frameColor': n.frameColor.id,
    if (n.customColor != null) 'customColor': n.customColor,
    if (n.customFrameColor != null) 'customFrameColor': n.customFrameColor,
    'folderId': n.folderId,
    'pinned': n.pinned,
    'starred': n.starred,
    'locked': n.locked,
    'createdAt': n.createdAt?.toIso8601String(),
    'updatedAt': n.updatedAt?.toIso8601String(),
    'archivedAt': n.archivedAt?.toIso8601String(),
    'reminderAt': n.reminderAt?.toIso8601String(),
    'attachments': [
      // BİLEREK storagePath, downloadUrl DEĞİL: downloadUrl içindeki
      // `?token=` Storage kurallarını atlayan, süresi dolmayan bir anahtardır.
      // Yedek dosyası e-posta/bulut diskle elden ele dolaşır; URL yazılsaydı
      // yedeği gören herkes kullanıcının tüm eklerine oturum açmadan süresiz
      // erişirdi. storagePath tek başına işe yaramaz (kural denetiminden
      // geçer); geri yükleme ekleri zaten atlıyor (bkz. _RestoreButton).
      for (final a in n.attachments)
        {'fileName': a.fileName, 'kind': a.kind.name, 'path': a.storagePath},
    ],
  };

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return;
    // Kilitli not varsa dışa aktarma kimlik ister: yedek, kilitli notların
    // gövdesini DÜZ METİN taşır — kapı yalnız ekran geçişinde kalsaydı kilit
    // buradan boşaltılabilirdi (locked bayrağı yedekte yine de yazılıdır).
    if (notes.any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    try {
      final payload = const JsonEncoder.withIndent('  ').convert({
        'app': 'notlar',
        'exportedAt': DateTime.now().toIso8601String(),
        'noteCount': notes.length,
        'notes': [for (final n in notes) _exportNote(n)],
      });
      final now = DateTime.now();
      final stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final fileName = 'notlar-yedek-$stamp.json';
      if (kIsWeb) {
        // Web'de dosya sistemi/path_provider yok: baytlar bellekten paylaşılır.
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                utf8.encode(payload),
                name: fileName,
                mimeType: 'application/json',
              ),
            ],
            subject: 'Notlar yedeği',
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(payload);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], subject: 'Notlar yedeği'),
        );
      }
    } catch (e) {
      messenger.showMessage(l10n.genericError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.file_download_outlined),
      label: Text(context.l10n.exportBackup),
      onPressed: () => _export(context, ref),
    );
  }
}

/// Dışa aktarılan JSON yedeği geri okur: her kayıt YENİ not olarak oluşturulur
/// (mevcut notlara dokunulmaz — id çakışması/veri ezme riski yok). Ekler
/// bulut bağlantısı olarak dışa aktarıldığından geri yüklemede atlanır.
class _RestoreButton extends ConsumerWidget {
  const _RestoreButton();

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final file = await DocPicker.pickOne(
      const XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
        mimeTypes: ['application/json'],
      ),
    );
    if (file == null) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final rawNotes = (decoded as Map<String, dynamic>)['notes'];
      if (rawNotes is! List) throw const FormatException();
      const uuid = Uuid();
      var count = 0;
      for (final raw in rawNotes) {
        if (raw is! Map) continue;
        final map = raw.cast<String, dynamic>();
        final type = NoteType.fromId(map['type'] as String?);
        final title = map['title'] as String? ?? '';
        final body = map['body'] as String? ?? '';
        final items = [
          for (final i in (map['items'] as List<dynamic>? ?? const []))
            if (i is Map)
              {
                'id': uuid.v4(),
                'text': i['text'] as String? ?? '',
                'checked': i['checked'] as bool? ?? false,
              },
        ];
        if (title.trim().isEmpty && body.trim().isEmpty && items.isEmpty) {
          continue;
        }
        final id = await repo.createNote(type);
        // Yedekteki alanların OLABİLDİĞİNCE çoğu geri yazılır. Eskiden yalnız
        // title/body/items/tags/pinned dönüyordu: kilitli notlar KİLİTSİZ
        // (içerik açıkta!), arşivdekiler ana duvara, renk/hatırlatıcı/tarih
        // kayıp geliyordu. Klasör geri yüklenmez (id başka hesapta anlamsız).
        Timestamp? ts(String key) {
          final v = map[key] as String?;
          final parsed = v == null ? null : DateTime.tryParse(v);
          return parsed == null ? null : Timestamp.fromDate(parsed);
        }

        repo.updateFields(id, {
          'title': title,
          'body': body,
          'items': items,
          'tags': [
            for (final t in (map['tags'] as List<dynamic>? ?? const []))
              t.toString(),
          ],
          'pinned': map['pinned'] as bool? ?? false,
          'starred': map['starred'] as bool? ?? false,
          'locked': map['locked'] as bool? ?? false,
          if (map['color'] is String) 'color': map['color'],
          if (map['frameColor'] is String) 'frameColor': map['frameColor'],
          if (map['customColor'] is num) 'customColor': map['customColor'],
          if (map['customFrameColor'] is num)
            'customFrameColor': map['customFrameColor'],
          if (ts('createdAt') != null) 'createdAt': ts('createdAt'),
          if (ts('archivedAt') != null) 'archivedAt': ts('archivedAt'),
          // Geçmişte kalmış hatırlatıcı geri kurulmaz (bildirim zaten
          // planlanmaz, "Geçmiş" listesini şişirir).
          if (ts('reminderAt') != null &&
              ts('reminderAt')!.toDate().isAfter(DateTime.now()))
            'reminderAt': ts('reminderAt'),
        });
        count++;
      }
      messenger.showMessage(l10n.importBackupDone(count));
    } on FormatException {
      messenger.showMessage(l10n.importBackupInvalid);
    } catch (e) {
      messenger.showMessage(l10n.genericError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.file_upload_outlined),
      label: Text(context.l10n.importBackup),
      onPressed: () => _import(context, ref),
    );
  }
}

/// Misafir hesabı Google hesabına bağlar (uid korunur, notlar yerinde
/// kalır). Ayarlar'daki satır ve ana ekrandaki hatırlatma kartı (F4.3)
/// aynı akışı kullanır.
Future<void> linkGuestAccount(BuildContext context, WidgetRef ref) =>
    _AccountSection._linkAccount(context, ref);

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    // Silme sürerken kapatılamayan bir bekleme göstergesi.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await ref.read(accountServiceProvider).deleteAccountAndData();
      // Başarıda auth durumu değişir; router login ekranına yönlendirir.
      navigator.pop();
    } catch (e) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(l10n.genericError(e.toString()));
    }
  }

  /// Yerel hesabı Google hesabına BAĞLAR — yeni giriş DEĞİL.
  ///
  /// `signInWithGoogle` çağrılsaydı yeni bir uid oluşur ve anonim hesapta
  /// biriken bütün notlar erişilemez hâle gelirdi. `linkWithGoogle` uid'i
  /// koruyarak hesabı yükseltir; notlar taşınmaya gerek kalmadan yerinde
  /// kalır ve o andan itibaren yedeklenir.
  static Future<void> _linkAccount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).linkWithGoogle();
      messenger.showMessage(l10n.accountLinked);
    } on FirebaseAuthException catch (e) {
      // Hesap seçiciyi kapatmak hata değil: sessizce geçilir.
      if (isSignInCancel(e)) return;
      // **credential-already-in-use — KÖK NEDEN düzeltmesi** (kullanıcı
      // bulgusu 2026-08-18: "çıkış yaptım tekrar giremiyorum bu hatayı
      // veriyor"). Seçilen Google hesabı zaten BAŞKA bir Firebase
      // kullanıcısına (kullanıcının kendi ESKİ gerçek hesabına) bağlı —
      // Firebase iki uid'i BİRLEŞTİREMEZ, yalnız hata verir. Eskiden burada
      // ham hata metni gösterilip kullanıcı çıkmaza düşüyordu ("Google
      // hesabı bağla" dışında bir yol yoktu, oysa gerekli olan BAĞLAMAK
      // değil o hesaba doğrudan GİRİŞ yapmaktı).
      //
      // ÇÖZÜM: `e.credential` (reddedilen ama GEÇERLİ Google kimlik bilgisi)
      // ile doğrudan giriş yapılır — Google hesap seçiciyi TEKRAR açmaya
      // gerek kalmaz. Bu, o anki (yeni/anonim) oturumdaki notları TERK EDER;
      // boşsa (neredeyse her zaman — bu ekrana yeni bir anonim oturumla
      // düşülmüştür) sormadan geçilir, doluysa önce onay istenir.
      if (e.code == 'credential-already-in-use' && e.credential != null) {
        if (context.mounted) {
          await _recoverExistingAccount(context, ref, e.credential!);
        }
        return;
      }
      messenger.showMessage(authErrorText(l10n, e));
    } catch (e) {
      if (isSignInCancel(e)) return;
      messenger.showMessage(authErrorText(l10n, e));
    }
  }

  /// [credential] zaten BAŞKA (gerçek) bir Firebase hesabına ait — o hesaba
  /// doğrudan giriş yapar. Şu anki (yeni/anonim) oturumun notları varsa
  /// (nadir ama imkânsız değil — kullanıcı hesaptan çıkmadan önce bu cihazda
  /// birkaç not almış olabilir) önce onay ister; kaybolacakları açıkça söyler.
  static Future<void> _recoverExistingAccount(
    BuildContext context,
    WidgetRef ref,
    AuthCredential credential,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final noteCount = (ref.read(notesStreamProvider).value ?? const [])
        .where((n) => !n.isEmpty)
        .length;
    if (noteCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.accountRecoverConflictTitle),
          content: Text(l10n.accountRecoverConflictBody(noteCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.accountRecoverConflictProceed),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Başarıda auth durumu değişir; kullanıcı gerçek hesabına döner,
      // notları olduğu gibi orada bekliyor olur.
      if (context.mounted) {
        messenger.showMessage(l10n.accountLinked);
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showMessage(authErrorText(l10n, e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Kimlik (avatar/ad/e-posta) artık ayarların en üstündeki profil kartında;
    // burada yalnızca hesap EYLEMLERİ kalır.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yerel (anonim) hesapta yükseltme yolu HER ZAMAN görünür olmalı:
        // kullanıcı notlarının yalnız bu cihazda olduğunu bilmeden aylarca
        // kullanıp uygulamayı silince hepsini kaybedebilir.
        if (ref.watch(isAnonymousProvider)) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phonelink_lock_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.localAccountBadge,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.localAccountInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(l10n.linkGoogleAccount),
                    onPressed: () => _linkAccount(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
          onPressed: () async {
            // Anonim (yerel) hesapta çıkış GERİ DÖNÜŞSÜZ veri kaybıdır: uid
            // bir daha ele geçirilemez, "Yerel devam et" YENİ uid açar ve
            // eski notların tamamı erişilmez kalır. Sıradan onay yetmez —
            // diyalog açık uyarır ve silme düğmesi gibi kırmızı görünür.
            final anonymous = ref.read(isAnonymousProvider);
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.signOut),
                content: Text(
                  anonymous
                      ? l10n.signOutAnonymousWarning
                      : l10n.signOutConfirm,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    style: anonymous
                        ? FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              dialogContext,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              dialogContext,
                            ).colorScheme.onError,
                          )
                        : null,
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.signOut),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              await ref.read(authRepositoryProvider).signOut();
            }
          },
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(l10n.deleteAccount),
          onPressed: () => _deleteAccount(context, ref),
        ),
        const SizedBox(height: 16),
        // Hukuki şeffaflık: gizlilik politikası + açık kaynak lisansları.
        TextButton.icon(
          icon: const Icon(Icons.privacy_tip_outlined),
          label: Text(l10n.privacyPolicyTitle),
          onPressed: () => context.push('/privacy'),
        ),
        TextButton.icon(
          icon: const Icon(Icons.description_outlined),
          label: Text(l10n.licensesTitle),
          onPressed: () =>
              showLicensePage(context: context, applicationName: l10n.appName),
        ),
        // Hata günlüğü + çökme raporları (F1.9).
        const _ErrorLogButton(),
        if (CrashReporting.supported) const _CrashReportsSwitch(),
        const _AppVersionRow(),
      ],
    );
  }
}

/// **HATA GÜNLÜĞÜNÜ PAYLAŞ** (F1.9): cihazdaki son hatalar düz metin dosyası
/// olarak paylaşım penceresine verilir (e-posta, mesaj…). Başına sürüm ve
/// platform yazılır — hata bildiriminin ilk sorusu.
class _ErrorLogButton extends StatelessWidget {
  const _ErrorLogButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.errorLogInfo,
      child: TextButton.icon(
        icon: const Icon(Icons.bug_report_outlined),
        label: Text(l10n.errorLogShare),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          if (ErrorLog.entries.isEmpty) {
            messenger.showMessage(l10n.errorLogEmpty);
            return;
          }
          var header = '';
          try {
            final info = await PackageInfo.fromPlatform();
            header =
                '${l10n.appName} ${info.version} (${info.buildNumber}) · '
                '${kIsWeb ? 'web' : Platform.operatingSystem}';
          } catch (_) {
            // Sürüm okunamazsa başlıksız paylaşılır.
          }
          final text = ErrorLog.exportText(header: header);
          try {
            await SharePlus.instance.share(
              ShareParams(
                files: [
                  XFile.fromData(
                    utf8.encode(text),
                    name: 'notlar-hata-gunlugu.txt',
                    mimeType: 'text/plain',
                  ),
                ],
                subject: l10n.errorLogShare,
              ),
            );
          } catch (e) {
            messenger.showMessage(l10n.genericError('$e'));
          }
        },
      ),
    );
  }
}

class _CrashReportsSwitch extends ConsumerWidget {
  const _CrashReportsSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      title: Text(l10n.crashReports),
      subtitle: Text(l10n.crashReportsInfo),
      value: ref.watch(crashReportsProvider),
      onChanged: (v) => ref.read(crashReportsProvider.notifier).set(v),
    );
  }
}

/// **UYGULAMA SÜRÜMÜ** — kullanıcı "hangi sürümdeyim" sorusuna hiçbir yerde
/// cevap bulamıyordu.
///
/// Güncelleme akışı "yeni APK'yı üstüne kur" olduğu için bu bilgi pratikte
/// zorunlu: telefondaki sürümün CI'ın ürettiğinden eski olup olmadığı ancak
/// böyle görülür. Aynı zamanda hata bildirmenin de ön koşulu.
///
/// Dokununca panoya kopyalanır: numarayı elle okuyup yazmak gerekmesin.
class _AppVersionRow extends StatefulWidget {
  const _AppVersionRow();

  @override
  State<_AppVersionRow> createState() => _AppVersionRowState();
}

class _AppVersionRowState extends State<_AppVersionRow> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Sürüm okunamadı (beklenmedik platform): satır hiç çizilmez, ayarların
      // geri kalanı çalışmaya devam eder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final row = _versionButton(context, l10n, version);
    if (!Diagnostics.enabled) return row;
    // Teşhis sayaçları (F9.2): yalnız hata ayıklama/profil derlemesinde;
    // dokununca tazelenir.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        GestureDetector(
          onTap: () => setState(() {}),
          child: Text(
            Diagnostics.summary(thumbBytes: CardThumbs.memoryBytes),
            key: const ValueKey('diagnostics-row'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  Widget _versionButton(
    BuildContext context,
    AppLocalizations l10n,
    String version,
  ) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      icon: const Icon(Icons.info_outline),
      label: Text('${l10n.appVersion}: $version'),
      // Uzun bas → Crashlytics test çökmesi (yalnız raporlama açıkken,
      // Android release derlemesinde). Kurulum doğrulaması için gizli kapı.
      onLongPress: CrashReporting.active
          ? () => _confirmTestCrash(context)
          : null,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(
          ClipboardData(text: '${l10n.appName} $version'),
        );
        messenger
          ..hideCurrentSnackBar()
          ..showMessage(l10n.appVersionCopied);
      },
    );
  }
}

Future<void> _confirmTestCrash(BuildContext context) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.crashTestTitle),
      content: Text(l10n.crashTestBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.crashTestAction),
        ),
      ],
    ),
  );
  if (ok ?? false) CrashReporting.testCrash();
}

/// Arama suzgecinin test kancalari.
///
/// `_Area` ve `_SettingRow` bu dosyaya ozel (private) kalmali — ayar ekrani
/// disinda kullanilacak seyler degil. Suzme mantigi ise sinanmaya deger:
/// satir duzeyi suzme "hangi satir gorunur" sorusunun cevabi ve gozle
/// dogrulamasi zahmetli. Bu iki yapici testin nesne kurmasina izin verir,
/// tipi disari acmadan.
@visibleForTesting
Object settingsRowForTest(
  Widget child, {
  String title = '',
  String keywords = '',
}) => _SettingRow(child, title: title, keywords: keywords);

@visibleForTesting
dynamic settingsAreaForTest({
  required String id,
  required String title,
  required String summary,
  required String keywords,
  required List<Object> rows,
}) => _Area(
  id: id,
  icon: Icons.settings,
  title: title,
  summary: summary,
  keywords: keywords,
  rows: [for (final r in rows) r as _SettingRow],
);
