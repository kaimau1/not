import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';

final aiReportServiceProvider = Provider<AiReportService>(
  AiReportService.new,
);

/// Sorunlu AI çıktısı bildirimi (Google Play üretken AI politikası gereği).
/// Bildirim kullanıcının kendi alanına (`users/{uid}/aiReports`) yazılır;
/// geliştirici konsoldan inceleyebilir.
class AiReportService {
  AiReportService(this._ref);

  final Ref _ref;

  Future<void> report({required String content, required String source}) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('aiReports')
        .add({
          'content': content.length > 2000
              ? content.substring(0, 2000)
              : content,
          'source': source,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
