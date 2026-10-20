import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/note_shares_repository.dart';
import '../../domain/note_heavy.dart' show kPresenceCollection;

/// **"BAŞKA BİRİ DÜZENLİYOR" GÖSTERGESİ** (F4.1).
///
/// Ortak notta (benimle paylaşılan ya da benim paylaştığım) editör açıkken
/// `users/{sahip}/notes/{id}/presence/{benim uid}` belgesine
/// [_beat] aralıkla nabız yazar; öbür editörler aynı koleksiyonu dinler ve
/// son [_fresh] içinde nabzı olan BAŞKA birini üst çubukta gösterir. Editör
/// kapanınca belge silinir (uygulama öldürülürse nabız bayatlar, gösterge
/// kendiliğinden söner). Paylaşılmayan notta hiçbir şey yazılmaz.
const _beat = Duration(seconds: 25);
const _fresh = Duration(seconds: 70);

class NotePresenceIndicator extends ConsumerStatefulWidget {
  const NotePresenceIndicator({super.key, required this.noteId, this.ownerId});

  final String noteId;

  /// Başkasının notu ise sahibi; kendi notumsa null.
  final String? ownerId;

  @override
  ConsumerState<NotePresenceIndicator> createState() =>
      _NotePresenceIndicatorState();
}

class _NotePresenceIndicatorState extends ConsumerState<NotePresenceIndicator> {
  Timer? _timer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<String> _others = const [];
  String? _announced;
  bool _active = false;

  String? get _me => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final owner = widget.ownerId ?? _me;
    if (owner == null) return null;
    return FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(owner)
        .collection(AppConstants.notesCollection)
        .doc(widget.noteId)
        .collection(kPresenceCollection);
  }

  void _start() {
    final collection = _collection;
    final me = _me;
    if (_active || collection == null || me == null) return;
    _active = true;
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? '');
    void beat() => collection
        .doc(me)
        .set({'name': name, 'at': FieldValue.serverTimestamp()})
        .catchError((Object _) {});
    beat();
    _timer = Timer.periodic(_beat, (_) {
      beat();
      if (mounted) setState(() {});
    });
    _sub = collection.snapshots().listen((snap) {
      final now = DateTime.now();
      final others = <String>[
        for (final doc in snap.docs)
          if (doc.id != me &&
              now.difference(
                    (doc.data()['at'] as Timestamp?)?.toDate() ?? now,
                  ) <
                  _fresh)
            (doc.data()['name'] as String?)?.trim() ?? '',
      ];
      if (!mounted) return;
      setState(() => _others = others);
      if (others.isNotEmpty && _announced != others.first) {
        _announced = others.first;
        ScaffoldMessenger.of(context)
            .showMessage(_label(context, others.first));
      }
    }, onError: (Object _) {});
  }

  String _label(BuildContext context, String name) => context.l10n
      .presenceEditing(name.isEmpty ? context.l10n.presenceSomeone : name);

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    // Firebase'e yalnız nabız başladıysa dokunulur (testlerde uygulama yok).
    if (_active) {
      final me = _me;
      if (me != null) {
        unawaited(_collection?.doc(me).delete().catchError((Object _) {}));
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shared =
        widget.ownerId != null ||
        ref.watch(
          myNoteSharesProvider.select(
            (m) => (m.value?[widget.noteId]?.sharedWith.length ?? 0) > 0,
          ),
        );
    if (shared && !_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
    }
    if (_others.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final label = _label(context, _others.first);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: scheme.tertiaryContainer,
            child: Text(
              _others.first.isEmpty ? '?' : _others.first.characters.first,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ),
      ),
    );
  }
}
